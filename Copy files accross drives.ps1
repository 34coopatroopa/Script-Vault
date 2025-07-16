$sourceDir = "C:\Windows\System32\drivers"
$destDir = "E:\Windows\System32\drivers"

# Ensure destination directory exists
if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force
}

# List of driver files to copy
$driverFiles = @(
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

# Copy each file if it exists
foreach ($file in $driverFiles) {
    $sourcePath = Join-Path $sourceDir $file
    $destPath = Join-Path $destDir $file

    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "Copied: $file"
    } else {
        Write-Host "Missing: $file"
    }
}
