$drive1 = "C:\Program Files\"
$drive2 = "E:\Program Files\"

# Collect relative file paths
$files1 = Get-ChildItem -Path $drive1 -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Found in C: $($_.FullName)"
    $_.FullName.Replace($drive1, "")
}

$files2 = Get-ChildItem -Path $drive2 -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Found in E: $($_.FullName)"
    $_.FullName.Replace($drive2, "")
}

# Check if either list is empty
if (-not $files1 -or -not $files2) {
    Write-Host "CHECK PATHS"
    return
}

# Compare and find files missing in E:
$missingInE = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -PassThru | Where-Object { $_ -in $files1 }

Write-Host "Saving Results"

# Save to file
$missingInE | Out-File "C:\missingFiles.txt"
