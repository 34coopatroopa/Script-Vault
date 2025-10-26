#Requires -Version 5.1

<#
.SYNOPSIS
    Quick Validation Script for ScriptVault
    
.DESCRIPTION
    Validates all scripts for syntax errors and displays help information
    Safe to run - does not execute any destructive operations
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ScriptVault - Quick Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create output directory
$outputDir = ".\validation_output"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Step 1: Checking PowerShell Script Syntax..." -ForegroundColor Yellow
Write-Host ""

# Get all PowerShell scripts
$scripts = Get-ChildItem -Recurse -Filter "*.ps1" | 
    Where-Object { 
        $_.FullName -notlike "*\Run-QuickValidation.ps1" -and
        $_.FullName -notlike "*\tests\*"
    }

$syntaxResults = @()
$errorCount = 0

foreach ($script in $scripts) {
    Write-Host "  Checking: $($script.Name)" -NoNewline
    
    $errors = $null
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$errors)
        
        if ($errors) {
            Write-Host " - ❌ FAILED" -ForegroundColor Red
            $errorCount++
            $syntaxResults += [PSCustomObject]@{
                Script = $script.Name
                Status = "Failed"
                Errors = $errors.Count
                Location = $script.DirectoryName.Replace((Get-Location).Path, ".")
            }
        } else {
            Write-Host " - ✓ OK" -ForegroundColor Green
            $syntaxResults += [PSCustomObject]@{
                Script = $script.Name
                Status = "Passed"
                Errors = 0
                Location = $script.DirectoryName.Replace((Get-Location).Path, ".")
            }
        }
    } catch {
        Write-Host " - ❌ ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "Step 2: Checking Required Modules..." -ForegroundColor Yellow
Write-Host ""

$modules = @(
    @{Name='Posh-SSH'; Required='network\cisco, network\palo_alto, network\meraki, server\linux'},
    @{Name='ActiveDirectory'; Required='server\windows\get_ad_computers, server\windows\copy_ad_group_membership'},
    @{Name='Az.Accounts'; Required='cloud\azure'},
    @{Name='Az.Resources'; Required='cloud\azure'},
    @{Name='Az.Compute'; Required='cloud\azure'}
)

$moduleResults = @()
foreach ($module in $modules) {
    $installed = Get-Module -ListAvailable -Name $module.Name -ErrorAction SilentlyContinue
    
    if ($installed) {
        Write-Host "  ✓ $($module.Name) - Installed (v$($installed.Version.ToString()))" -ForegroundColor Green
        $moduleResults += [PSCustomObject]@{
            Module = $module.Name
            Status = "Installed"
            Version = $installed.Version.ToString()
        }
    } else {
        Write-Host "  ⚠ $($module.Name) - NOT Installed (Required for: $($module.Required))" -ForegroundColor Yellow
        $moduleResults += [PSCustomObject]@{
            Module = $module.Name
            Status = "Not Installed"
            Version = "N/A"
        }
    }
}

Write-Host ""
Write-Host "Step 3: Testing Help Documentation..." -ForegroundColor Yellow
Write-Host ""

$helpResults = @()
foreach ($script in $scripts) {
    $help = Get-Help -Path $script.FullName -ErrorAction SilentlyContinue
    
    if ($help -and $help.Synopsis) {
        Write-Host "  ✓ $($script.Name) - Has documentation" -ForegroundColor Green
        $helpResults += [PSCustomObject]@{
            Script = $script.Name
            HasHelp = $true
        }
    } else {
        Write-Host "  ⚠ $($script.Name) - Missing help documentation" -ForegroundColor Yellow
        $helpResults += [PSCustomObject]@{
            Script = $script.Name
            HasHelp = $false
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalScripts = $scripts.Count
$passedScripts = $totalScripts - $errorCount
$passRate = [math]::Round(($passedScripts / $totalScripts) * 100, 1)

Write-Host "Total Scripts: $totalScripts" -ForegroundColor White
Write-Host "Passed: $passedScripts" -ForegroundColor Green
Write-Host "Failed: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host ""

# Export results
$syntaxResults | Export-Csv -Path "$outputDir\syntax_validation.csv" -NoTypeInformation
$moduleResults | Export-Csv -Path "$outputDir\module_check.csv" -NoTypeInformation
$helpResults | Export-Csv -Path "$outputDir\help_check.csv" -NoTypeInformation

Write-Host "Results exported to: $outputDir\" -ForegroundColor Cyan
Write-Host ""

# Display failed scripts if any
if ($errorCount -gt 0) {
    Write-Host "Scripts with syntax errors:" -ForegroundColor Red
    $syntaxResults | Where-Object { $_.Status -eq "Failed" } | ForEach-Object {
        Write-Host "  - $($_.Location)\$($_.Script)" -ForegroundColor Red
    }
    Write-Host ""
}

if ($errorCount -eq 0) {
    Write-Host "✅ All scripts passed syntax validation!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review TESTING_GUIDE.md for detailed testing instructions" -ForegroundColor White
    Write-Host "  2. Install missing modules if needed" -ForegroundColor White
    Write-Host "  3. Run script-specific tests with -WhatIf parameter" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠️  Some scripts have syntax errors. Please review and fix." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Validation complete!" -ForegroundColor Cyan
