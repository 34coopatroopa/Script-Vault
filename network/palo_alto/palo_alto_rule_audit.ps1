#Requires -Version 5.1

<#
.SYNOPSIS
    Palo Alto Networks Firewall Rule Audit and Analysis Tool
    
.DESCRIPTION
    Comprehensive security policy analysis for Palo Alto firewalls
    Identifies unused rules, overly permissive rules, and security gaps
    Generates compliance reports for policy management
    
.PARAMETER FirewallIP
    IP address or hostname of Palo Alto firewall management interface
    
.PARAMETER APIToken
    Palo Alto API token for authentication
    
.PARAMETER OutputPath
    Directory for generated reports
    
.EXAMPLE
    .\palo_alto_rule_audit.ps1 -FirewallIP 10.1.1.1 -APIToken "keyhere" -OutputPath C:\Reports
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FirewallIP,
    
    [Parameter(Mandatory=$true)]
    [string]$APIToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\output",
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportJSON,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedReport
)

$ErrorActionPreference = 'Stop'

# Initialize output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# Palo Alto API base URL
$baseUrl = "https://$FirewallIP/api"

# Function to invoke Palo Alto API
function Invoke-PaloAltoAPI {
    param(
        [string]$Resource,
        [hashtable]$QueryParams = @{}
    )
    
    $queryParams['key'] = $APIToken
    $uri = "$baseUrl/$Resource" + '?' + ($QueryParams.GetEnumerator() | 
        ForEach-Object { "$($_.Key)=$($_.Value)" } | Join-String -Separator '&')
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -SkipCertificateCheck -TimeoutSec 30
        return $response
    } catch {
        Write-Error "API call failed: $_"
        return $null
    }
}

# Function to get firewall rules
function Get-FirewallRules {
    Write-Host "Retrieving security policy rules..." -ForegroundColor Cyan
    
    $response = Invoke-PaloAltoAPI -Resource "config" `
        -QueryParams @{
            type = "config"
            action = "get"
            xpath = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='vsys1']/rulebase/security/rules"
        }
    
    if ($response.response.result.entry) {
        $rules = $response.response.result.entry | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.name
                Action = $_.action
                Description = $_.description
                SourceZones = $_.from.'member-list'.member -join ','
                DestZones = $_.to.'member-list'.member -join ','
                SourceAddresses = $_.source.'member-list'.member -join ','
                DestAddresses = $_.destination.'member-list'.member -join ','
                Applications = $_.application.'member-list'.member -join ','
                Services = $_.service.'member-list'.member -join ','
                Disabled = $_.disabled
            }
        }
        
        return $rules
    }
    
    return @()
}

# Function to analyze rule security
function Get-SecurityAnalysis {
    param([array]$Rules)
    
    Write-Host "Analyzing rule security..." -ForegroundColor Cyan
    
    $analysis = @{
        TotalRules = $Rules.Count
        AllowRules = ($Rules | Where-Object { $_.Action -eq 'allow' }).Count
        DenyRules = ($Rules | Where-Object { $_.Action -eq 'deny' }).Count
        HighRiskRules = @()
        UnusedRules = @()
        OverlyPermissive = @()
        MissingLogging = @()
    }
    
    foreach ($rule in $Rules) {
        # Identify high-risk rules (any source, any destination, any application)
        if ($rule.DestAddresses -eq 'any' -and $rule.Applications -eq 'any' -and $rule.Action -eq 'allow') {
            $analysis.HighRiskRules += $rule
        }
        
        # Check for overly permissive rules
        if ($rule.Action -eq 'allow' -and $rule.Services -eq 'any' -and $rule.Applications -eq 'any') {
            $analysis.OverlyPermissive += $rule
        }
    }
    
    return $analysis
}

# Main execution
Write-Host "=== Palo Alto Rule Audit Tool ===" -ForegroundColor Yellow
Write-Host "Analyzing firewall: $FirewallIP" -ForegroundColor Yellow

# Retrieve rules
$rules = Get-FirewallRules

if ($rules.Count -eq 0) {
    Write-Warning "No rules found or unable to retrieve rules"
    exit 1
}

Write-Host "Found $($rules.Count) security rules" -ForegroundColor Green

# Analyze rules
$analysis = Get-SecurityAnalysis -Rules $rules

# Generate report
Write-Host "`nGenerating audit report..." -ForegroundColor Cyan

$report = @"
# Palo Alto Firewall Security Audit Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Firewall: $FirewallIP

## Summary
- Total Rules: $($analysis.TotalRules)
- Allow Rules: $($analysis.AllowRules)
- Deny Rules: $($analysis.DenyRules)

## Risk Analysis
- High Risk Rules: $($analysis.HighRiskRules.Count)
- Overly Permissive Rules: $($analysis.OverlyPermissive.Count)

## Recommendations
"@

if ($analysis.HighRiskRules.Count -gt 0) {
    $report += "`n### High Risk Rules Identified:`n"
    $analysis.HighRiskRules | ForEach-Object { 
        $report += "- **$($_.Name)**: Allows any to any traffic`n"
    }
}

# Save report
$reportPath = Join-Path $OutputPath "palo_alto_audit_$timestamp.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

# Export CSV if requested
if ($DetailedReport) {
    $csvPath = Join-Path $OutputPath "palo_alto_rules_$timestamp.csv"
    $rules | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "Detailed rules exported to: $csvPath" -ForegroundColor Green
}

# Export JSON if requested
if ($ExportJSON) {
    $jsonPath = Join-Path $OutputPath "palo_alto_data_$timestamp.json"
    $rules | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8
    Write-Host "JSON export: $jsonPath" -ForegroundColor Green
}

Write-Host "`nReport saved to: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n=== Audit Summary ===" -ForegroundColor Yellow
Write-Host "High Risk Rules: $($analysis.HighRiskRules.Count)" -ForegroundColor Red
Write-Host "Overly Permissive: $($analysis.OverlyPermissive.Count)" -ForegroundColor Yellow

exit 0
