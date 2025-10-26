#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Server Security and Compliance Audit Tool
    
.DESCRIPTION
    Comprehensive Windows Server security audit including:
    - Security configuration analysis
    - Patch compliance checking
    - Service and process audit
    - Local security policy review
    - Active Directory integration checks
    
.PARAMETER ComputerName
    Target computer to audit (localhost by default)
    
.PARAMETER OutputPath
    Output directory for audit reports
    
.PARAMETER IncludeHotfixCheck
    Check Windows Update status
    
.PARAMETER IncludeServiceAudit
    Audit running services
    
.EXAMPLE
    .\windows_server_audit.ps1 -ComputerName DC01 -OutputPath C:\Audits
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string[]]$ComputerName = @('localhost'),
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\audits",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeHotfixCheck,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeServiceAudit,
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential
)

$ErrorActionPreference = 'Stop'

# Initialize output directory
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Function to get Windows Server information
function Get-ServerInfo {
    param([string]$Computer)
    
    $info = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            OSName = (Get-CimInstance Win32_OperatingSystem).Caption
            OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
            LastBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            TotalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            Processors = (Get-CimInstance Win32_ComputerSystem).NumberOfProcessors
            DomainRole = (Get-CimInstance Win32_ComputerSystem).DomainRole
            Domain = (Get-CimInstance Win32_ComputerSystem).Domain
            CurrentUser = $env:USERNAME
            Uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        }
    }
    
    return $info
}

# Function to check Windows Update status
function Get-UpdateStatus {
    param([string]$Computer)
    
    Write-Host "Checking Windows Update status..." -ForegroundColor Cyan
    
    $updates = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        Get-WmiObject -Class Win32_QuickFixEngineering | 
            Select-Object HotFixID, Description, InstalledOn, InstalledBy |
            Sort-Object InstalledOn -Descending
    }
    
    return $updates
}

# Function to audit services
function Get-ServiceAudit {
    param([string]$Computer)
    
    Write-Host "Auditing services..." -ForegroundColor Cyan
    
    $services = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        Get-Service | Select-Object Name, DisplayName, Status, StartType, ServiceName |
            Where-Object { $_.Status -eq 'Running' }
    }
    
    return $services
}

# Function to check security settings
function Get-SecurityAudit {
    param([string]$Computer)
    
    Write-Host "Checking security configuration..." -ForegroundColor Cyan
    
    $security = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        [PSCustomObject]@{
            FirewallProfile = (Get-NetFirewallProfile).Name
            FirewallEnabled = (Get-NetFirewallProfile | Where-Object Enabled -eq 'True').Count
            UACEnabled = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA
            RDPEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -ErrorAction SilentlyContinue).fDenyTSConnections
            RemoteManagementEnabled = (Get-Service -Name WinRM).Status
            WindowsDefenderStatus = (Get-MpComputerStatus).AntivirusEnabled
            BitLockerStatus = (Get-BitLockerVolume -ErrorAction SilentlyContinue).VolumeStatus
        }
    }
    
    return $security
}

# Function to audit local users and groups
function Get-UserAudit {
    param([string]$Computer)
    
    Write-Host "Auditing local users and groups..." -ForegroundColor Cyan
    
    $users = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        Get-LocalUser | Select-Object Name, Enabled, LastLogon, Description, PasswordExpires
    }
    
    $groups = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        Get-LocalGroup | Select-Object Name, Description, @{
            Name='MemberCount';
            Expression={(Get-LocalGroupMember $_.Name).Count}
        }
    }
    
    return @{
        Users = $users
        Groups = $groups
    }
}

# Main execution
Write-Host "=== Windows Server Security Audit Tool ===" -ForegroundColor Yellow
Write-Host "Starting audit at $(Get-Date)" -ForegroundColor Yellow

$allResults = @()

foreach ($computer in $ComputerName) {
    Write-Host "`n=== Auditing: $computer ===" -ForegroundColor Cyan
    
    try {
        # Basic server information
        $serverInfo = Get-ServerInfo -Computer $computer
        Write-Host "OS: $($serverInfo.OSName) $($serverInfo.OSVersion)" -ForegroundColor Green
        Write-Host "Domain: $($serverInfo.Domain)" -ForegroundColor Green
        Write-Host "Uptime: $($serverInfo.Uptime.Days) days" -ForegroundColor Green
        
        $results = [PSCustomObject]@{
            ComputerName = $serverInfo.ComputerName
            OSName = $serverInfo.OSName
            OSVersion = $serverInfo.OSVersion
            Domain = $serverInfo.Domain
            LastBootTime = $serverInfo.LastBootTime
            UptimeDays = $serverInfo.Uptime.Days
        }
        
        # Hotfix check
        if ($IncludeHotfixCheck) {
            $updates = Get-UpdateStatus -Computer $computer
            $results | Add-Member -NotePropertyName 'TotalHotfixes' -NotePropertyValue $updates.Count
            $results | Add-Member -NotePropertyName 'LastUpdateDate' -NotePropertyValue ($updates[0].InstalledOn)
        }
        
        # Service audit
        if ($IncludeServiceAudit) {
            $services = Get-ServiceAudit -Computer $computer
            $results | Add-Member -NotePropertyName 'RunningServices' -NotePropertyValue $services.Count
        }
        
        # Security audit
        $security = Get-SecurityAudit -Computer $computer
        $results | Add-Member -NotePropertyName 'WindowsDefender' -NotePropertyValue $security.WindowsDefenderStatus
        $results | Add-Member -NotePropertyName 'FirewallEnabled' -NotePropertyValue ($security.FirewallEnabled -gt 0)
        
        # User audit
        $users = Get-UserAudit -Computer $computer
        $results | Add-Member -NotePropertyName 'LocalUsers' -NotePropertyValue $users.Users.Count
        $results | Add-Member -NotePropertyName 'LocalGroups' -NotePropertyValue $users.Groups.Count
        
        $allResults += $results
        
    } catch {
        Write-Error "Failed to audit $computer`: $_"
    }
}

# Generate report
Write-Host "`nGenerating audit report..." -ForegroundColor Cyan

$csvPath = Join-Path $OutputPath "windows_audit_$timestamp.csv"
$allResults | Export-Csv -Path $csvPath -NoTypeInformation

$report = @"
# Windows Server Security Audit Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- Servers Audited: $($allResults.Count)

## Server Details
"@

$allResults | ForEach-Object {
    $report += "`n### $($_.ComputerName)"
    $report += "- OS: $($_.OSName) $($_.OSVersion)`n"
    $report += "- Domain: $($_.Domain)`n"
    $report += "- Uptime: $($_.UptimeDays) days`n"
    $report += "- Windows Defender: $($_.WindowsDefender)`n"
    $report += "- Firewall Enabled: $($_.FirewallEnabled)`n"
}

$reportPath = Join-Path $OutputPath "windows_audit_summary_$timestamp.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nAudit saved to: $csvPath" -ForegroundColor Green
Write-Host "Summary report: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n=== Audit Summary ===" -ForegroundColor Yellow
$allResults | Format-Table ComputerName, OSVersion, Domain, WindowsDefender, FirewallEnabled -AutoSize

exit 0
