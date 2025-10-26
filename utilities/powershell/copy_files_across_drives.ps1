#Requires -Version 5.1

<#
.SYNOPSIS
    Copy Specific Files Across Drives
    
.DESCRIPTION
    Copies a specified list of files from a source directory to a destination directory
    Useful for backup or migration scenarios
    
.PARAMETER SourcePath
    Source directory containing files to copy
    
.PARAMETER DestinationPath
    Destination directory where files will be copied
    
.PARAMETER FileList
    Array of file names to copy
    
.PARAMETER FileListPath
    Path to a text file containing list of files to copy (one per line)
    
.EXAMPLE
    $files = @("file1.txt", "file2.txt")
    .\copy_files_across_drives.ps1 -SourcePath "C:\Source" -DestinationPath "E:\Dest" -FileList $files
    
.EXAMPLE
    .\copy_files_across_drives.ps1 -SourcePath "C:\Drivers" -DestinationPath "E:\Backup\Drivers" -FileListPath "C:\filelist.txt"
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "C:\Windows\System32\drivers",
    
    [Parameter(Mandatory=$false)]
    [string]$DestinationPath = "E:\Windows\System32\drivers",
    
    [Parameter(Mandatory=$false)]
    [string[]]$FileList,
    
    [Parameter(Mandatory=$false)]
    [string]$FileListPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

Write-Host "=== File Copy Across Drives Tool ===" -ForegroundColor Yellow

# Validate paths
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path not found: $SourcePath"
    exit 1
}

# Determine file list
if ($FileListPath -and (Test-Path $FileListPath)) {
    Write-Host "Loading file list from: $FileListPath" -ForegroundColor Cyan
    $filesToCopy = Get-Content $FileListPath
} elseif ($FileList) {
    $filesToCopy = $FileList
} else {
    # Default driver files if nothing specified
    Write-Host "Using default driver file list" -ForegroundColor Yellow
    $filesToCopy = @(
        "pnpmem.sys",
        "SET81E0.tmp",
        "SET8C05.tmp",
        "SET96D0.tmp",
        "SETB2B4.tmp",
        "SETB363.tmp",
        "vmhgfs.sys",
        "vmrawdsk.sys",
        "vmxnet3n61x64.sys",
        "vnetWFP.sys",
        "vsepflt.sys"
    )
}

Write-Host "`nSource: $SourcePath" -ForegroundColor Gray
Write-Host "Destination: $DestinationPath" -ForegroundColor Gray
Write-Host "Files to copy: $($filesToCopy.Count)" -ForegroundColor Cyan

# Ensure destination directory exists
Write-Host "`nCreating destination directory..." -ForegroundColor Cyan
if (-not (Test-Path -Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    Write-Host "Created: $DestinationPath" -ForegroundColor Green
}

# Copy files
$copiedCount = 0
$missingCount = 0
$errorCount = 0

Write-Host "`nCopying files..." -ForegroundColor Cyan

foreach ($file in $filesToCopy) {
    $sourceFile = Join-Path $SourcePath $file
    $destFile = Join-Path $DestinationPath $file
    
    try {
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination $destFile -Force -ErrorAction Stop
            Write-Host "  ✓ Copied: $file" -ForegroundColor Green
            $copiedCount++
        } else {
            Write-Host "  ✗ Missing: $file" -ForegroundColor Yellow
            $missingCount++
        }
    } catch {
        Write-Warning "Error copying $file`: $_"
        $errorCount++
    }
}

# Summary
Write-Host "`n=== Copy Summary ===" -ForegroundColor Yellow
Write-Host "Successfully copied: $copiedCount" -ForegroundColor Green
Write-Host "Files not found: $missingCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

exit 0
