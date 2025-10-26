#Requires -Version 5.1
#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Get Active Directory Computers and Export to CSV
    
.DESCRIPTION
    Retrieves all Active Directory computers from a specified OU
    and exports their name and last modified date to CSV
    
.PARAMETER SearchBase
    Distinguished name of the OU to search
    Example: "OU=Servers,DC=domain,DC=com"
    
.PARAMETER OutputPath
    Path to save the CSV file (default: current directory)
    
.EXAMPLE
    .\get_ad_computers.ps1 -SearchBase "OU=Servers,DC=example,DC=com" -OutputPath "C:\Reports"
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SearchBase,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\output",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Properties = @("Name", "WhenChanged", "OperatingSystem", "LastLogonDate")
)

$ErrorActionPreference = 'Stop'

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "=== Get AD Computers Tool ===" -ForegroundColor Yellow
Write-Host "Search Base: $SearchBase" -ForegroundColor Cyan

try {
    # Get AD Computers
    $computers = Get-ADComputer -Filter * -SearchBase $SearchBase -Properties $Properties -ErrorAction Stop
    
    if ($computers.Count -eq 0) {
        Write-Warning "No computers found in the specified OU"
        exit 0
    }
    
    Write-Host "Found $($computers.Count) computers" -ForegroundColor Green
    
    # Export to CSV
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputFile = Join-Path $OutputPath "ad_computers_$timestamp.csv"
    
    $computers | Select-Object $Properties | Export-Csv -Path $outputFile -NoTypeInformation
    
    Write-Host "Results exported to: $outputFile" -ForegroundColor Green
    
    # Display summary
    Write-Host "`n=== Summary ===" -ForegroundColor Yellow
    $computers | Select-Object Name, OperatingSystem, WhenChanged -First 10 | Format-Table -AutoSize
    
} catch {
    Write-Error "Failed to retrieve AD computers: $_"
    exit 1
}

exit 0
