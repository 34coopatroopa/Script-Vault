#Requires -Version 5.1

<#
.SYNOPSIS
    Cisco Meraki Device Inventory and Management Tool
    
.DESCRIPTION
    Automated device discovery and inventory for Meraki networks
    Retrieves device status, configuration, and network topology
    Supports bulk operations across multiple organizations and networks
    
.PARAMETER APIKey
    Meraki Dashboard API Key
    
.PARAMETER OrganizationID
    Meraki Organization ID (optional - will list if not provided)
    
.PARAMETER NetworkID
    Specific network ID to query (optional)
    
.PARAMETER OutputPath
    Output directory for reports
    
.EXAMPLE
    .\meraki_device_inventory.ps1 -APIKey "yourkey" -OrganizationID "123456" -OutputPath C:\Meraki
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$APIKey,
    
    [Parameter(Mandatory=$false)]
    [string]$OrganizationID,
    
    [Parameter(Mandatory=$false)]
    [string]$NetworkID,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\output",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDevices,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeClients
)

$ErrorActionPreference = 'Stop'
$baseUrl = "https://api.meraki.com/api/v1"

# Set up headers
$headers = @{
    "X-Cisco-Meraki-API-Key" = $APIKey
    "Content-Type" = "application/json"
}

# Initialize output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# Function to invoke Meraki API
function Invoke-MerakiAPI {
    param(
        [string]$Endpoint,
        [string]$Method = 'Get',
        [object]$Body = $null
    )
    
    $uri = "$baseUrl/$Endpoint"
    
    try {
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $headers
            TimeoutSec = 30
        }
        
        if ($Body) {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Error "API call failed for $Endpoint`: $_"
        return $null
    }
}

# Function to get organizations
function Get-MerakiOrganizations {
    Write-Host "Retrieving organizations..." -ForegroundColor Cyan
    
    $orgs = Invoke-MerakiAPI -Endpoint "organizations"
    
    return $orgs
}

# Function to get networks
function Get-MerakiNetworks {
    param([string]$OrgID)
    
    Write-Host "Retrieving networks for organization $OrgID..." -ForegroundColor Cyan
    
    $networks = Invoke-MerakiAPI -Endpoint "organizations/$OrgID/networks"
    
    return $networks
}

# Function to get devices in a network
function Get-MerakiDevices {
    param([string]$NetworkID)
    
    Write-Host "Retrieving devices for network $NetworkID..." -ForegroundColor Cyan
    
    $devices = Invoke-MerakiAPI -Endpoint "networks/$NetworkID/devices"
    
    return $devices
}

# Function to get clients on network
function Get-MerakiClients {
    param(
        [string]$NetworkID,
        [int]$timespan = 3600
    )
    
    Write-Host "Retrieving clients for network $NetworkID..." -ForegroundColor Cyan
    
    $clients = Invoke-MerakiAPI -Endpoint "networks/$NetworkID/clients?timespan=$timespan"
    
    return $clients
}

# Main execution
Write-Host "=== Meraki Device Inventory Tool ===" -ForegroundColor Yellow

# Get or display organizations
if (-not $OrganizationID) {
    Write-Host "`nAvailable Organizations:" -ForegroundColor Cyan
    $orgs = Get-MerakiOrganizations
    
    if ($orgs) {
        $orgs | Format-Table Id, Name -AutoSize
        Write-Host "`nRun with -OrganizationID <id> to inventory specific organization" -ForegroundColor Yellow
        exit 0
    }
}

# Get networks
$networks = Get-MerakiNetworks -OrgID $OrganizationID

if ($networks.Count -eq 0) {
    Write-Warning "No networks found in organization $OrganizationID"
    exit 1
}

Write-Host "Found $($networks.Count) networks" -ForegroundColor Green

# Collect inventory data
$inventory = @()

foreach ($network in $networks) {
    Write-Host "`nProcessing network: $($network.name) ($($network.id))" -ForegroundColor Cyan
    
    $networkData = [PSCustomObject]@{
        NetworkName = $network.name
        NetworkID = $network.id
        NetworkType = $network.productTypes -join ','
        Tags = $network.tags -join ','
        TimeZone = $network.timeZone
    }
    
    if ($IncludeDevices) {
        $devices = Get-MerakiDevices -NetworkID $network.id
        
        if ($devices) {
            $networkData | Add-Member -NotePropertyName 'DeviceCount' -NotePropertyValue $devices.Count
            $networkData | Add-Member -NotePropertyName 'Devices' -NotePropertyValue ($devices | ForEach-Object {
                "$($_.name) ($($_.model))"
            } -join '; ')
        }
    }
    
    if ($IncludeClients) {
        $clients = Get-MerakiClients -NetworkID $network.id
        $networkData | Add-Member -NotePropertyName 'ActiveClients' -NotePropertyValue $clients.Count
    }
    
    $inventory += $networkData
}

# Generate report
Write-Host "`nGenerating inventory report..." -ForegroundColor Cyan

$csvPath = Join-Path $OutputPath "meraki_inventory_$timestamp.csv"
$inventory | Export-Csv -Path $csvPath -NoTypeInformation

# Create summary report
$report = @"
# Meraki Network Inventory Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Organization ID: $OrganizationID

## Summary
- Total Networks: $($networks.Count)
- Networks Inventoried: $($inventory.Count)

## Network Details
"@

if ($IncludeDevices) {
    $totalDevices = ($inventory.DeviceCount | Measure-Object -Sum).Sum
    $report += "`n- Total Devices: $totalDevices`n"
}

if ($IncludeClients) {
    $totalClients = ($inventory.ActiveClients | Measure-Object -Sum).Sum
    $report += "- Total Active Clients (last hour): $totalClients`n"
}

$reportPath = Join-Path $OutputPath "meraki_summary_$timestamp.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nInventory saved to: $csvPath" -ForegroundColor Green
Write-Host "Summary report: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n=== Inventory Summary ===" -ForegroundColor Yellow
$inventory | Select-Object NetworkName, NetworkType, DeviceCount, ActiveClients | Format-Table -AutoSize

exit 0
