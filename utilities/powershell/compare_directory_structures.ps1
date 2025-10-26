#Requires -Version 5.1

<#
.SYNOPSIS
    Compare Directory Structures Between Two Paths
    
.DESCRIPTION
    Compares file structures between two directory paths
    Identifies files that exist in one location but not the other
    
.PARAMETER Path1
    First directory path to compare
    
.PARAMETER Path2
    Second directory path to compare
    
.PARAMETER OutputPath
    Directory to save comparison results
    
.EXAMPLE
    .\compare_directory_structures.ps1 -Path1 "C:\Program Files" -Path2 "E:\Program Files" -OutputPath "C:\Reports"
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path1,
    
    [Parameter(Mandatory=$true)]
    [string]$Path2,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\output"
)

$ErrorActionPreference = 'Stop'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "=== Directory Structure Comparison Tool ===" -ForegroundColor Yellow

# Verify paths exist
if (-not (Test-Path $Path1)) {
    Write-Error "Path not found: $Path1"
    exit 1
}

if (-not (Test-Path $Path2)) {
    Write-Error "Path not found: $Path2"
    exit 1
}

Write-Host "`nComparing directories..." -ForegroundColor Cyan
Write-Host "Path 1: $Path1" -ForegroundColor Gray
Write-Host "Path 2: $Path2" -ForegroundColor Gray

try {
    # Collect relative file paths
    Write-Host "`nScanning Path 1..." -ForegroundColor Cyan
    $files1 = Get-ChildItem -Path $Path1 -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $_.FullName.Replace($Path1, "").TrimStart('\')
    }
    
    Write-Host "Found $($files1.Count) files in Path 1" -ForegroundColor Green
    
    Write-Host "Scanning Path 2..." -ForegroundColor Cyan
    $files2 = Get-ChildItem -Path $Path2 -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $_.FullName.Replace($Path2, "").TrimStart('\')
    }
    
    Write-Host "Found $($files2.Count) files in Path 2" -ForegroundColor Green
    
    # Compare and find differences
    Write-Host "`nComparing file structures..." -ForegroundColor Cyan
    
    $missingInPath2 = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -PassThru | 
        Where-Object { $_ -in $files1 }
    
    $missingInPath1 = Compare-Object -ReferenceObject $files2 -DifferenceObject $files1 -PassThru | 
        Where-Object { $_ -in $files2 }
    
    # Save results
    $outputFile = Join-Path $OutputPath "comparison_$timestamp.txt"
    
    $report = @"
Directory Structure Comparison Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Source Path 1: $Path1
Source Path 2: $Path2

SUMMARY
=======
Files in Path 1: $($files1.Count)
Files in Path 2: $($files2.Count)
Files only in Path 1: $($missingInPath2.Count)
Files only in Path 2: $($missingInPath1.Count)

FILES ONLY IN PATH 1
=====================
$(if ($missingInPath2.Count -gt 0) { $missingInPath2 | ForEach-Object { "  $_" } } else { "  (none)" })


FILES ONLY IN PATH 2
=====================
$(if ($missingInPath1.Count -gt 0) { $missingInPath1 | ForEach-Object { "  $_" } } else { "  (none)" })
"@

    $report | Out-File -FilePath $outputFile -Encoding utf8
    
    Write-Host "`nResults saved to: $outputFile" -ForegroundColor Green
    
    # Display summary
    Write-Host "`n=== Summary ===" -ForegroundColor Yellow
    Write-Host "Files only in Path 1: $($missingInPath2.Count)" -ForegroundColor Cyan
    Write-Host "Files only in Path 2: $($missingInPath1.Count)" -ForegroundColor Cyan
    
} catch {
    Write-Error "Failed to compare directories: $_"
    exit 1
}

exit 0
