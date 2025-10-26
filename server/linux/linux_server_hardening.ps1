#Requires -Version 5.1

<#
.SYNOPSIS
    Linux Server Security Hardening and Audit Tool (via SSH)
    
.DESCRIPTION
    Automated security audit and hardening recommendations for Linux servers
    Checks security configurations, patch status, and compliance
    
.PARAMETER ServerList
    Path to CSV file with server information (IP, Hostname, OS)
    
.PARAMETER Credential
    SSH credentials for Linux servers
    
.PARAMETER OutputPath
    Output directory for reports
    
.EXAMPLE
    .\linux_server_hardening.ps1 -ServerList servers.csv -OutputPath C:\Reports
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerList,
    
    [Parameter(Mandatory=$true)]
    [PSCredential]$Credential,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\output",
    
    [Parameter(Mandatory=$false)]
    [switch]$ApplyHardening
)

$ErrorActionPreference = 'Stop'

# Import Posh-SSH module
try {
    Import-Module Posh-SSH -ErrorAction Stop
} catch {
    Write-Error "Posh-SSH module not found. Install with: Install-Module -Name Posh-SSH"
    exit 1
}

# Initialize output directory
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Security check functions
function Invoke-SSHCommand {
    param(
        [System.Management.Automation.Runspaces.PSSession]$SSHSession,
        [string]$Command
    )
    
    $result = Invoke-Command -Session $SSHSession -ScriptBlock {
        param($cmd)
        Invoke-Expression $cmd
    } -ArgumentList $Command
    
    return $result
}

# Function to audit Linux server
function Test-LinuxSecurity {
    param(
        [string]$Server,
        [string]$Username,
        [SecureString]$Password
    )
    
    Write-Host "Auditing: $Server" -ForegroundColor Cyan
    
    try {
        # Create SSH connection
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
        
        $sshOptions = New-SSHTrustedHost -Force:$true
        
        # Note: In production, use proper SSH key authentication
        $session = New-SSHSession -ComputerName $Server -Credential (New-Object System.Management.Automation.PSCredential($Username, $Password))
        
        if (-not $session) {
            throw "Failed to establish SSH connection"
        }
        
        # Check security configurations
        $audit = [PSCustomObject]@{
            Server = $Server
            OSRelease = (Invoke-SSHCommand -SessionId $session.SessionId -Command "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2").Output
            Kernel = (Invoke-SSHCommand -SessionId $session.SessionId -Command "uname -r").Output
            OpenSSHVersion = (Invoke-SSHCommand -SessionId $session.SessionId -Command "ssh -V 2>&1").Output
            LastUpdate = (Invoke-SSHCommand -SessionId $session.SessionId -Command "grep 'Installed' /var/log/yum.log | tail -1 || echo 'No data'").Output
            SSHPermitRootLogin = (Invoke-SSHCommand -SessionId $session.SessionId -Command "grep 'PermitRootLogin' /etc/ssh/sshd_config | grep -v '^#' | awk '{print \$2}'").Output
            FirewallEnabled = (Invoke-SSHCommand -SessionId $session.SessionId -Command "systemctl is-active firewalld || systemctl is-active ufw").Output
            SELinuxEnabled = (Invoke-SSHCommand -SessionId $session.SessionId -Command "getenforce 2>/dev/null || echo 'Not installed'").Output
        }
        
        # Check for high-privilege users
        $adminUsers = (Invoke-SSHCommand -SessionId $session.SessionId -Command "grep -E 'sudo|wheel' /etc/group | cut -d: -f4 | tr ',' ' '").Output
        
        $audit | Add-Member -NotePropertyName 'AdminUsers' -NotePropertyValue $adminUsers
        
        # Uptime
        $uptime = (Invoke-SSHCommand -SessionId $session.SessionId -Command "uptime -p").Output
        $audit | Add-Member -NotePropertyName 'Uptime' -NotePropertyValue $uptime
        
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
        
        return $audit
        
    } catch {
        Write-Warning "Error auditing $Server`: $_"
        return $null
    }
}

# Main execution
Write-Host "=== Linux Server Security Audit Tool ===" -ForegroundColor Yellow

# Import server list
if (-not (Test-Path $ServerList)) {
    Write-Error "Server list file not found: $ServerList"
    exit 1
}

$servers = Import-Csv -Path $ServerList

Write-Host "`nFound $($servers.Count) servers to audit" -ForegroundColor Green

$results = @()

foreach ($server in $servers) {
    $serverIP = $server.IPAddress
    $username = $server.Username ?? $Credential.UserName
    
    $result = Test-LinuxSecurity -Server $serverIP -Username $username -Password $Credential.Password
    
    if ($result) {
        $results += $result
    }
}

# Generate report
Write-Host "`nGenerating audit report..." -ForegroundColor Cyan

$csvPath = Join-Path $OutputPath "linux_audit_$timestamp.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

$report = @"
# Linux Server Security Audit Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- Servers Audited: $($results.Count)

## Security Findings

### High Priority Issues
- Servers with SSH root login enabled: $(($results | Where-Object { $_.SSHPermitRootLogin -eq 'yes' }).Count)
- Servers with firewall disabled: $(($results | Where-Object { $_.FirewallEnabled -notlike '*active*' }).Count)

### Server Details
"@

$results | ForEach-Object {
    $report += "`n### $($_.Server)"
    $report += "- OS: $($_.OSRelease)`n"
    $report += "- Kernel: $($_.Kernel)`n"
    $report += "- SSH Root Login: $($_.SSHPermitRootLogin)`n"
    $report += "- Firewall: $($_.FirewallEnabled)`n"
    $report += "- SELinux: $($_.SELinuxEnabled)`n"
}

$report += @"

## Recommendations
1. Disable SSH root login on all servers
2. Ensure firewall is active and properly configured
3. Enable SELinux where possible
4. Keep systems updated with latest security patches
5. Implement key-based SSH authentication

"@

$reportPath = Join-Path $OutputPath "linux_audit_summary_$timestamp.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nAudit saved to: $csvPath" -ForegroundColor Green
Write-Host "Summary report: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n=== Audit Summary ===" -ForegroundColor Yellow
$results | Format-Table Server, OSRelease, SSHPermitRootLogin, FirewallEnabled -AutoSize

exit 0
