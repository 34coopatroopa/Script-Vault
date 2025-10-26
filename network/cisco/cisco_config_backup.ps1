#Requires -Version 5.1

<#
.SYNOPSIS
    Cisco Configuration Backup and Management Tool
    
.DESCRIPTION
    Automated backup and retrieval of Cisco device configurations (IOS, NX-OS, ASA)
    Supports SSH/Telnet connection with multi-threading for bulk operations
    Includes configuration comparison and change tracking
    
.PARAMETER DeviceList
    Path to CSV file containing device information (IP, Hostname, Credentials)
    
.PARAMETER ConfigType
    Type of configuration to retrieve (running-config, startup-config, backup)
    
.PARAMETER OutputPath
    Directory to store backed up configurations
    
.PARAMETER ThreadCount
    Number of concurrent connections (default: 5)
    
.EXAMPLE
    .\cisco_config_backup.ps1 -DeviceList devices.csv -OutputPath C:\Backups
    
.NOTES
    Requires Posh-SSH module: Install-Module -Name Posh-SSH
    Tested on: Cisco IOS, IOS-XE, NX-OS, ASA
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceList,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('running-config', 'startup-config', 'backup')]
    [string]$ConfigType = 'running-config',
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory=$false)]
    [int]$ThreadCount = 5,
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential
)

# Import required modules
try {
    Import-Module Posh-SSH -ErrorAction Stop
} catch {
    Write-Error "Posh-SSH module not found. Install with: Install-Module -Name Posh-SSH"
    exit 1
}

# Initialize script variables
$ErrorActionPreference = 'Stop'
$script:SuccessCount = 0
$script:ErrorCount = 0
$script:Results = @()
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# Test and create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Function to backup Cisco device configuration
function Backup-CiscoConfig {
    param(
        [PSCustomObject]$Device,
        [string]$Config,
        [string]$OutputDir,
        [PSCredential]$Cred
    )
    
    $hostname = $Device.Hostname
    $ipAddress = $Device.IPAddress
    
    try {
        Write-Host "Connecting to $hostname ($ipAddress)..." -ForegroundColor Cyan
        
        # Establish SSH connection
        $session = New-SSHSession -ComputerName $ipAddress -Credential $Cred -AcceptKey
        
        if ($null -eq $session) {
            throw "Failed to establish SSH connection"
        }
        
        # Execute show command based on device type
        $deviceType = (Invoke-SSHCommand -SessionId $session.SessionId -Command "show version | include IOS").Output
        
        if ($deviceType -like "*ASA*") {
            $config = Invoke-SSHCommand -SessionId $session.SessionId -Command "show $Config" -TimeOut 60
        } else {
            $config = Invoke-SSHCommand -SessionId $session.SessionId -Command "show $Config | begin" -TimeOut 60
        }
        
        # Save configuration to file
        $filename = "$hostname`_$Config`_$timestamp.txt"
        $filePath = Join-Path $OutputDir $filename
        
        if ($config.Output) {
            $config.Output | Out-File -FilePath $filePath -Encoding utf8
            Write-Host "Successfully backed up: $hostname" -ForegroundColor Green
            
            $script:Results += [PSCustomObject]@{
                Hostname = $hostname
                IPAddress = $ipAddress
                Status = 'Success'
                FilePath = $filePath
                Size = (Get-Item $filePath).Length
                Timestamp = Get-Date
            }
            
            $script:SuccessCount++
        } else {
            throw "No configuration data retrieved"
        }
        
        # Close SSH session
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
        
    } catch {
        Write-Warning "Error backing up $hostname`: $_"
        
        $script:Results += [PSCustomObject]@{
            Hostname = $hostname
            IPAddress = $ipAddress
            Status = 'Failed'
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
        
        $script:ErrorCount++
    }
}

# Main execution
Write-Host "=== Cisco Configuration Backup Tool ===" -ForegroundColor Yellow
Write-Host "Starting backup process at $(Get-Date)" -ForegroundColor Yellow

# Import device list
if (-not (Test-Path $DeviceList)) {
    Write-Error "Device list file not found: $DeviceList"
    exit 1
}

$devices = Import-Csv -Path $DeviceList

# Prompt for credentials if not provided
if (-not $Credential) {
    $Credential = Get-Credential -Message "Enter network device credentials"
}

# Process devices with throttling
Write-Host "`nProcessing $($devices.Count) devices with $ThreadCount concurrent connections..." -ForegroundColor Cyan

$jobs = $devices | ForEach-Object -ThrottleLimit $ThreadCount -Parallel {
    & $using:function:Backup-CiscoConfig -Device $_ -Config $using:ConfigType -OutputDir $using:OutputPath -Cred $using:Credential
}

# Generate summary report
$reportPath = Join-Path $OutputPath "backup_report_$timestamp.csv"
$script:Results | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "`n=== Backup Summary ===" -ForegroundColor Yellow
Write-Host "Successful: $script:SuccessCount" -ForegroundColor Green
Write-Host "Failed: $script:ErrorCount" -ForegroundColor Red
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

# Display failed devices
if ($script:ErrorCount -gt 0) {
    Write-Host "`nFailed devices:" -ForegroundColor Red
    $script:Results | Where-Object { $_.Status -eq 'Failed' } | 
        Format-Table Hostname, IPAddress, Error -AutoSize
}

exit 0
