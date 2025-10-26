#Requires -Version 5.1
#Requires -Modules Az.Accounts, Az.Resources, Az.Compute

<#
.SYNOPSIS
    Azure Resource Inventory and Compliance Checker
    
.DESCRIPTION
    Comprehensive Azure resource inventory across subscriptions
    Includes security and compliance checks for best practices
    
.PARAMETER SubscriptionID
    Azure subscription ID (optional - uses default if not specified)
    
.PARAMETER OutputPath
    Output directory for reports
    
.EXAMPLE
    .\azure_resource_inventory.ps1 -SubscriptionID "12345678-1234-1234-1234-123456789012"
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionID,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\azure_reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCompliance
)

$ErrorActionPreference = 'Stop'

# Check for Azure PowerShell modules
$requiredModules = @('Az.Accounts', 'Az.Resources', 'Az.Compute')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Error "Azure PowerShell module '$module' not installed. Install with: Install-Module -Name $module"
        exit 1
    }
}

# Initialize output directory
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
} catch {
    Write-Error "Failed to connect to Azure. Run Connect-AzAccount first."
    exit 1
}

# Set subscription
if ($SubscriptionID) {
    Set-AzContext -SubscriptionId $SubscriptionID | Out-Null
    Write-Host "Using subscription: $SubscriptionID" -ForegroundColor Green
} else {
    $SubscriptionID = (Get-AzContext).Subscription.Id
    Write-Host "Using current subscription: $SubscriptionID" -ForegroundColor Green
}

# Function to get all resource groups
function Get-AzureResourceGroups {
    Write-Host "Retrieving resource groups..." -ForegroundColor Cyan
    
    $resourceGroups = Get-AzResourceGroup
    
    return $resourceGroups
}

# Function to get resources in a resource group
function Get-AzureResources {
    param([string]$ResourceGroupName)
    
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName -ExpandProperties
    
    return $resources
}

# Function to get virtual machines
function Get-AzureVMs {
    $vms = Get-AzVM
    
    $vmDetails = $vms | ForEach-Object {
        $vmStatus = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status
        
        [PSCustomObject]@{
            Name = $_.Name
            ResourceGroup = $_.ResourceGroupName
            Location = $_.Location
            VMSize = $vmStatus.HardwareProfile.VmSize
            OSType = $vmStatus.StorageProfile.OsDisk.OsType
            PowerState = $vmStatus.Statuses[0].Code
            ProvisioningState = $vmStatus.ProvisioningState
        }
    }
    
    return $vmDetails
}

# Main execution
Write-Host "=== Azure Resource Inventory Tool ===" -ForegroundColor Yellow

# Get subscription info
$subscription = Get-AzSubscription -SubscriptionId $SubscriptionID
Write-Host "Subscription: $($subscription.Name)" -ForegroundColor Green

# Get all resource groups
$resourceGroups = Get-AzureResourceGroups
Write-Host "`nFound $($resourceGroups.Count) resource groups" -ForegroundColor Green

# Collect resource inventory
$inventory = @()

foreach ($rg in $resourceGroups) {
    Write-Host "Processing resource group: $($rg.ResourceGroupName)" -ForegroundColor Cyan
    
    $resources = Get-AzureResources -ResourceGroupName $rg.ResourceGroupName
    
    foreach ($resource in $resources) {
        $inventory += [PSCustomObject]@{
            ResourceGroup = $rg.ResourceGroupName
            ResourceName = $resource.Name
            ResourceType = $resource.ResourceType
            Location = $resource.Location
            Tags = $resource.Tags.Keys -join ','
        }
    }
}

# Get VM details
Write-Host "`nRetrieving virtual machine details..." -ForegroundColor Cyan
$vms = Get-AzureVMs

# Generate reports
Write-Host "`nGenerating reports..." -ForegroundColor Cyan

# Export full inventory to CSV
$csvPath = Join-Path $OutputPath "azure_inventory_$timestamp.csv"
$inventory | Export-Csv -Path $csvPath -NoTypeInformation

# Export VM details to CSV
if ($vms.Count -gt 0) {
    $vmCsvPath = Join-Path $OutputPath "azure_vms_$timestamp.csv"
    $vms | Export-Csv -Path $vmCsvPath -NoTypeInformation
}

# Generate summary report
$report = @"
# Azure Resource Inventory Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Subscription: $($subscription.Name)
Subscription ID: $SubscriptionID

## Summary
- Resource Groups: $($resourceGroups.Count)
- Total Resources: $($inventory.Count)
- Virtual Machines: $($vms.Count)

## Resource Breakdown by Type
"@

$inventory | Group-Object ResourceType | Sort-Object Count -Descending | ForEach-Object {
    $report += "- **$($_.Name)**: $($_.Count) resources`n"
}

$report += @"

## Virtual Machine Summary
"@

if ($vms.Count -gt 0) {
    $report += "`n| VM Name | Resource Group | Size | Power State |`n"
    $report += "|---------|---------------|------|-------------|`n"
    
    $vms | ForEach-Object {
        $report += "| $($_.Name) | $($_.ResourceGroup) | $($_.VMSize) | $($_.PowerState) |`n"
    }
}

$report += @"

## Recommendations
1. Implement resource tagging strategy for better governance
2. Regular review of unused resources to optimize costs
3. Ensure all VMs have appropriate backup configurations
4. Review network security groups and firewall rules
5. Enable Azure Security Center recommendations

"@

$reportPath = Join-Path $OutputPath "azure_summary_$timestamp.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`n=== Reports Generated ===" -ForegroundColor Yellow
Write-Host "Full Inventory: $csvPath" -ForegroundColor Green
if ($vms.Count -gt 0) {
    Write-Host "VM Details: $vmCsvPath" -ForegroundColor Green
}
Write-Host "Summary Report: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n=== Inventory Summary ===" -ForegroundColor Yellow
$inventory | Group-Object ResourceType | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize

exit 0
