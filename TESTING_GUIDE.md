# Testing Guide - ScriptVault

This guide shows you multiple ways to test and validate the ScriptVault scripts.

## 🎯 Testing Methods

### 1. **Syntax Check (PowerShell Linting)**
Verify script syntax without executing:

```powershell
# Check a specific script for syntax errors
$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = "network\cisco\cisco_config_backup.ps1"
$errors = $null
$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$errors)
if ($errors) {
    Write-Host "❌ Syntax errors found:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red }
} else {
    Write-Host "✅ No syntax errors found!" -ForegroundColor Green
}
```

### 2. **WhatIf Mode (Safe Testing)**
Test scripts without making changes:

```powershell
# Example: AD Group Membership (has -WhatIf support)
.\server\windows\copy_ad_group_membership.ps1 -SourceUser "testuser" -DestinationUser "newuser" -WhatIf
```

### 3. **Dry Run Scripts**
Create test scenarios without affecting production:

```powershell
# Network Analyzer (Python) - Safe network tests
cd utilities\python
python network_analyzer.py --ping google.com
python network_analyzer.py --ping 192.168.1.1
```

### 4. **Test Environment Setup**
Create isolated test environments:

```powershell
# Create test directories
New-Item -ItemType Directory -Path "C:\TestEnvironment" -Force
New-Item -ItemType Directory -Path "C:\TestEnvironment\Source" -Force
New-Item -ItemType Directory -Path "C:\TestEnvironment\Destination" -Force

# Test directory comparison
.\utilities\powershell\compare_directory_structures.ps1 `
    -Path1 "C:\TestEnvironment\Source" `
    -Path2 "C:\TestEnvironment\Destination" `
    -OutputPath "C:\TestEnvironment\Reports"
```

### 5. **Mock Data Testing**
Create sample input files:

```powershell
# Create sample device list for Cisco backup
$sampleDevices = @"
Hostname,IPAddress,Vendor
test-switch-01,192.168.1.10,Cisco
test-router-01,192.168.1.11,Cisco
"@

$sampleDevices | Out-File -FilePath ".\test_devices.csv" -Encoding utf8

# Create sample server list for Linux audit
$sampleServers = @"
IPAddress,Hostname,Username
10.0.0.10,test-linux-01,admin
10.0.0.11,test-linux-02,admin
"@

$sampleServers | Out-File -FilePath ".\test_servers.csv" -Encoding utf8
```

---

## 📋 Script-Specific Testing

### **Windows Server Audit**
```powershell
# Test on localhost first
.\server\windows\windows_server_audit.ps1 -ComputerName localhost -OutputPath ".\output\test"

# Test on remote computer
.\server\windows\windows_server_audit.ps1 -ComputerName "YOUR-SERVER-NAME" -OutputPath ".\output\test"
```

### **Directory Comparison (Safe to Run)**
```powershell
# Compare two existing directories
.\utilities\powershell\compare_directory_structures.ps1 `
    -Path1 "C:\Windows" `
    -Path2 "C:\Windows.old" `
    -OutputPath ".\output"
```

### **Get AD Computers (Requires AD Module)**
```powershell
# Check if AD module is available
Get-Module -ListAvailable -Name ActiveDirectory

# Test with a specific OU
.\server\windows\get_ad_computers.ps1 `
    -SearchBase "OU=Computers,DC=contoso,DC=com" `
    -OutputPath ".\output"
```

### **Network Analyzer (Python)**
```powershell
# Test ping functionality
python utilities\python\network_analyzer.py --ping 8.8.8.8

# Test DNS resolution
python utilities\python\network_analyzer.py --dns google.com

# Test port scan (safe on your own systems)
python utilities\python\network_analyzer.py --scan 127.0.0.1 --ports 80,443
```

### **Infrastructure Reporting**
```powershell
# Generate a summary report
.\utilities\powershell\infrastructure_reporting.ps1 -ReportType summary -OutputPath ".\output"
```

---

## 🔧 Module Verification

Check if required modules are installed:

```powershell
# Check all required modules
$modules = @(
    'Posh-SSH',
    'ActiveDirectory',
    'Az.Accounts',
    'Az.Resources',
    'Az.Compute'
)

foreach ($module in $modules) {
    $installed = Get-Module -ListAvailable -Name $module
    if ($installed) {
        Write-Host "✅ $module is installed (Version: $($installed.Version))" -ForegroundColor Green
    } else {
        Write-Host "❌ $module is NOT installed" -ForegroundColor Red
        Write-Host "   Install with: Install-Module -Name $module" -ForegroundColor Yellow
    }
}
```

---

## 🚀 Quick Test Script

Create this file to test multiple scripts at once:

```powershell
# Save as: Run-QuickTests.ps1

Write-Host "=== ScriptVault Quick Tests ===" -ForegroundColor Yellow
Write-Host ""

# Test 1: Directory comparison (always safe)
Write-Host "Test 1: Directory Comparison" -ForegroundColor Cyan
$testDir1 = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
$testDir2 = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }

"Test file" | Out-File -FilePath "$testDir1\test.txt"

.\utilities\powershell\compare_directory_structures.ps1 `
    -Path1 $testDir1.FullName `
    -Path2 $testDir2.FullName `
    -OutputPath ".\output"

Write-Host "✅ Directory comparison test completed" -ForegroundColor Green
Write-Host ""

# Test 2: Network analyzer
Write-Host "Test 2: Network Analyzer" -ForegroundColor Cyan
if (Get-Command python -ErrorAction SilentlyContinue) {
    python utilities\python\network_analyzer.py --ping google.com 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Network analyzer test completed" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Python not found, skipping network analyzer test" -ForegroundColor Yellow
}
Write-Host ""

# Test 3: Syntax check
Write-Host "Test 3: Syntax Validation" -ForegroundColor Cyan
$scripts = Get-ChildItem -Recurse -Filter "*.ps1" | Where-Object { $_.FullName -notlike "*\tests\*" }

$syntaxErrors = 0
foreach ($script in $scripts) {
    $errors = $null
    [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$errors) | Out-Null
    
    if ($errors) {
        Write-Host "❌ Syntax error in: $($script.Name)" -ForegroundColor Red
        $syntaxErrors++
    } else {
        Write-Host "✓ $($script.Name)" -ForegroundColor Green
    }
}

if ($syntaxErrors -eq 0) {
    Write-Host "`n✅ All scripts passed syntax validation!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Found $syntaxErrors script(s) with syntax errors" -ForegroundColor Red
}
```

---

## 🎬 Running the Test Suite

```powershell
# Run the built-in test suite
.\tests\test_network_tools.ps1

# Run with verbose output
.\tests\test_network_tools.ps1 -Verbose
```

---

## ⚠️ Important Safety Notes

1. **Network Scripts**: Test on isolated networks or with permission
2. **AD Scripts**: Use test OUs, not production
3. **Cloud Scripts**: Use test subscriptions or read-only permissions
4. **Server Scripts**: Test on non-production servers first
5. **Always use -WhatIf when available**

---

## 📊 Expected Results

When tests pass, you should see:

- ✅ Syntax validation passes for all scripts
- ✅ Help text displays correctly (Get-Help script.ps1)
- ✅ Parameters are accepted without errors
- ✅ Output files are created in specified directories
- ✅ Logs show successful operations

---

## 🐛 Troubleshooting

### "Module not found" errors
```powershell
# Install missing modules
Install-Module -Name Posh-SSH -Force
Install-Module -Name ActiveDirectory -Force  # Requires RSAT
```

### "Execution Policy" errors
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Access Denied" errors
```powershell
# Run PowerShell as Administrator for system-level scripts
```

### Python not found
```powershell
# Check if Python is installed
python --version

# Or use full path
C:\Python39\python.exe utilities\python\network_analyzer.py
```

---

## 💡 Pro Tips

1. Start with script syntax validation (safest)
2. Test with -WhatIf parameter when available
3. Use test directories and mock data
4. Test on localhost first, then remote systems
5. Review output files before considering tests passed
6. Check script help: `Get-Help .\script.ps1 -Full`

---

**Happy Testing! 🎉**
