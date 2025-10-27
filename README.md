# ScriptVault - IT Infrastructure Automation Library

Comprehensive PowerShell and Python automation library for IT infrastructure management, network administration, cloud operations, and security auditing.

## 🚀 Quick Links - All Scripts

### Network Tools
- [Cisco Configuration Backup](network/cisco/cisco_config_backup.ps1) | [Palo Alto Firewall Audit](network/palo_alto/palo_alto_rule_audit.ps1) | [Meraki Device Inventory](network/meraki/meraki_device_inventory.ps1)

### Server Management
- [Windows Server Audit](server/windows/windows_server_audit.ps1) | [Linux Server Hardening](server/linux/linux_server_hardening.ps1) | [Get AD Computers](server/windows/get_ad_computers.ps1) | [Copy AD Group Membership](server/windows/copy_ad_group_membership.ps1)

### Cloud Automation
- [Azure Resource Inventory](cloud/azure/azure_resource_inventory.ps1) | [AWS Resource Inventory](cloud/aws/aws_resource_inventory.ps1)

### Utilities
- [Infrastructure Reporting](utilities/powershell/infrastructure_reporting.ps1) | [Network Analyzer](utilities/python/network_analyzer.py) | [Compare Directories](utilities/powershell/compare_directory_structures.ps1) | [Copy Files](utilities/powershell/copy_files_across_drives.ps1) | [Web Script Scraper](utilities/powershell/web_script_scraper.ps1)

### Testing
- [Test Suite](tests/test_network_tools.ps1)

---

## 📁 Directory Structure

```
ScriptVault/
├── network/
│   ├── cisco/              # Cisco device automation
│   ├── palo_alto/          # Palo Alto Networks management
│   └── meraki/             # Meraki network management
├── server/
│   ├── windows/            # Windows Server management
│   └── linux/              # Linux server management
├── cloud/
│   ├── azure/              # Azure resource management
│   └── aws/                # AWS resource management
├── utilities/
│   ├── powershell/         # PowerShell utilities
│   └── python/             # Python utilities
└── tests/                  # Test suites
```

---

## 🔧 Network Tools

### **Cisco Configuration Backup**
📄 [**View Script**](network/cisco/cisco_config_backup.ps1) | **File:** `network/cisco/cisco_config_backup.ps1`

Automated configuration backup for Cisco devices (IOS, IOS-XE, NX-OS, ASA).

**Requirements:**
```powershell
Install-Module -Name Posh-SSH
```

**Usage:**
```powershell
# Create device list CSV
# Format: Hostname,IPAddress
# Example devices.csv:
# switch-01,192.168.1.1
# router-01,192.168.1.2

.\cisco_config_backup.ps1 -DeviceList devices.csv -OutputPath C:\Backups
```

**Features:**
- Multi-threading for bulk operations (default: 5 concurrent)
- SSH/Telnet support
- Configuration change tracking
- Detailed error reporting

---

### **Palo Alto Firewall Rule Audit**
📄 [**View Script**](network/palo_alto/palo_alto_rule_audit.ps1) | **File:** `network/palo_alto/palo_alto_rule_audit.ps1`

Security policy analysis and compliance checking for Palo Alto firewalls.

**Usage:**
```powershell
.\palo_alto_rule_audit.ps1 -FirewallIP 10.1.1.1 -APIToken "your-key" -OutputPath C:\Reports -DetailedReport
```

**Capabilities:**
- Unused rule identification
- High-risk rule detection
- Compliance reporting
- JSON/CSV export options

**API Token:**
Generate in: Device > Setup > Management > Generate API Key

---

### **Meraki Device Inventory**
📄 [**View Script**](network/meraki/meraki_device_inventory.ps1) | **File:** `network/meraki/meraki_device_inventory.ps1`

Automated Meraki network and device discovery.

**Usage:**
```powershell
# List organizations
.\meraki_device_inventory.ps1 -APIKey "your-key"

# Full inventory
.\meraki_device_inventory.ps1 -APIKey "your-key" -OrganizationID "123456" -IncludeDevices -IncludeClients -OutputPath C:\Meraki
```

**Features:**
- Multi-organization support
- Device status monitoring
- Client activity tracking
- Network topology discovery

**API Key:**
Generate in: Meraki Dashboard > Organization > Settings > Enable API access

---

## 🖥️ Server Management

### **Windows Server Security Audit**
📄 [**View Script**](server/windows/windows_server_audit.ps1) | **File:** `server/windows/windows_server_audit.ps1`

Comprehensive Windows security and compliance auditing.

**Requirements:**
```powershell
# Run as Administrator
```

**Usage:**
```powershell
.\windows_server_audit.ps1 -ComputerName DC01,FS01 -OutputPath C:\Audits -IncludeHotfixCheck -IncludeServiceAudit
```

**Audit Checks:**
- Security policy compliance
- Windows Update status
- Service configuration
- Firewall settings
- Local security policy
- Windows Defender status
- RDP configuration

---

### **Get Active Directory Computers**
📄 [**View Script**](server/windows/get_ad_computers.ps1) | **File:** `server/windows/get_ad_computers.ps1`

Retrieve and export Active Directory computers from specified OUs to CSV.

**Requirements:**
```powershell
Install-Module -Name ActiveDirectory
```

**Usage:**
```powershell
.\get_ad_computers.ps1 -SearchBase "OU=Servers,DC=domain,DC=com" -OutputPath C:\Reports
```

**Features:**
- Export computer inventory to CSV
- Include OS version and last logon
- Customize exported properties

---

### **Copy Active Directory Group Membership**
📄 [**View Script**](server/windows/copy_ad_group_membership.ps1) | **File:** `server/windows/copy_ad_group_membership.ps1`

Copy all group memberships from one AD user to another.

**Requirements:**
```powershell
Install-Module -Name ActiveDirectory
```

**Usage:**
```powershell
.\copy_ad_group_membership.ps1 -SourceUser "jsmith" -DestinationUser "jdoe" -WhatIf
```

**Features:**
- Copy all group memberships
- Preview changes with -WhatIf
- Error handling and validation

---

### **Linux Server Security Hardening**
📄 [**View Script**](server/linux/linux_server_hardening.ps1) | **File:** `server/linux/linux_server_hardening.ps1`

Automated Linux security audit via SSH.

**Requirements:**
```powershell
Install-Module -Name Posh-SSH
```

**Usage:**
```powershell
# Create server list CSV
# Format: IPAddress,Hostname,Username
# Example servers.csv:
# 10.1.1.10,web01,root
# 10.1.1.11,db01,root

.\linux_server_hardening.ps1 -ServerList servers.csv -Credential (Get-Credential) -OutputPath C:\Reports
```

**Security Checks:**
- SSH configuration
- Firewall status
- SELinux status
- Kernel version
- Patch level
- User privilege audit

---

## ☁️ Cloud Management

### **Azure Resource Inventory**
📄 [**View Script**](cloud/azure/azure_resource_inventory.ps1) | **File:** `cloud/azure/azure_resource_inventory.ps1`

Azure resource discovery and compliance checking.

**Requirements:**
```powershell
Install-Module -Name Az.Accounts, Az.Resources, Az.Compute
```

**Usage:**
```powershell
# Login to Azure
Connect-AzAccount

# Run inventory
.\azure_resource_inventory.ps1 -SubscriptionID "your-sub-id" -OutputPath C:\AzureReports
```

**Capabilities:**
- Resource group enumeration
- VM inventory
- Resource tagging audit
- Compliance recommendations
- Cost optimization suggestions

---

### **AWS Resource Inventory**
📄 [**View Script**](cloud/aws/aws_resource_inventory.ps1) | **File:** `cloud/aws/aws_resource_inventory.ps1`

AWS resource discovery and security auditing.

**Requirements:**
```bash
# Install AWS CLI
# https://aws.amazon.com/cli/
```

**Usage:**
```powershell
# Using AWS profile
.\aws_resource_inventory.ps1 -Region us-east-1 -ProfileName default -IncludeSecurityChecks -OutputPath C:\AWSReports
```

**Resource Discovery:**
- EC2 instances
- S3 buckets
- Security groups
- VPCs and subnets
- High-risk rule detection

**Security Checks:**
- Overly permissive security groups
- Public S3 bucket identification
- Security group rule analysis

---

## 🛠️ Utilities

### **Infrastructure Reporting**
📄 [**View Script**](utilities/powershell/infrastructure_reporting.ps1) | **File:** `utilities/powershell/infrastructure_reporting.ps1`

Unified reporting framework for cross-platform infrastructure.

**Usage:**
```powershell
.\infrastructure_reporting.ps1 -ReportType summary -GenerateDashboard -OutputPath C:\Reports
```

---

### **Network Analyzer (Python)**
📄 [**View Script**](utilities/python/network_analyzer.py) | **File:** `utilities/python/network_analyzer.py`

Network diagnostic and troubleshooting tool.

**Usage:**
```bash
# Ping test
python network_analyzer.py --ping google.com

# Port scan
python network_analyzer.py --scan 192.168.1.1 --ports 80,443,22

# Network sweep
python network_analyzer.py --sweep 192.168.1.0/24 --output scan_report.txt

# DNS resolution
python network_analyzer.py --dns example.com
```

---

### **Compare Directory Structures**
📄 [**View Script**](utilities/powershell/compare_directory_structures.ps1) | **File:** `utilities/powershell/compare_directory_structures.ps1`

Compare file structures between two directory paths to identify missing files.

**Usage:**
```powershell
.\compare_directory_structures.ps1 -Path1 "C:\Program Files" -Path2 "E:\Program Files" -OutputPath C:\Reports
```

**Features:**
- Find files unique to each location
- Generate detailed comparison reports
- Identify backup gaps

---

### **Copy Files Across Drives**
📄 [**View Script**](utilities/powershell/copy_files_across_drives.ps1) | **File:** `utilities/powershell/copy_files_across_drives.ps1`

Copy specific files from one location to another across drives.

**Usage:**
```powershell
$files = @("file1.txt", "file2.txt")
.\copy_files_across_drives.ps1 -SourcePath "C:\Source" -DestinationPath "E:\Backup" -FileList $files
```

**Features:**
- Copy specific file lists
- Load files from text file
- Progress tracking and error reporting

---

### **Web Script Scraper**
📄 [**View Script**](utilities/powershell/web_script_scraper.ps1) | **File:** `utilities/powershell/web_script_scraper.ps1`

Intelligent web scraper that finds and downloads scripts from public repositories with smart naming conventions.

**Usage:**
```powershell
# Scrape GitHub Gists for PowerShell scripts
.\web_script_scraper.ps1 -Source gist -Query "active directory" -Count 20 -Language PowerShell

# Scrape all sources
.\web_script_scraper.ps1 -Source all -Query "network automation" -Count 15
```

**Features:**
- Intelligent content analysis for smart naming
- Automatic categorization (ActiveDirectory, Network, Azure, AWS, etc.)
- Extracts function names from scripts
- Saves metadata with each script
- Creates comprehensive index of scraped scripts
- Supports GitHub Gist, Pastebin (requires API key)
- Rate limiting to respect API restrictions

**Intelligent Naming:**
The scraper analyzes script content to generate intelligent filenames:
- Extracts function names (e.g., `Get-ADUserInventory_1234.ps1`)
- Categorizes by topic (e.g., `Network_script_5678.ps1`)
- Detects file type automatically
- Sanitizes invalid characters

**Output:**
```
scraped_scripts/
├── Get-ADUserInventory_1234.ps1
├── Network_script_5678.ps1
├── Azure_automation_9012.ps1
└── SCRAPER_INDEX.txt
```

---

## 🧪 Testing

### **Test Suite**
📄 [**View Script**](tests/test_network_tools.ps1) | **File:** `tests/test_network_tools.ps1`

Automated test framework for validating scripts.

**Usage:**
```powershell
.\test_network_tools.ps1
```

---

## 📚 Quick Reference

### **Common Parameters**

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-OutputPath` | Output directory | `C:\Reports` |
| `-Credential` | Credential object | `(Get-Credential)` |
| `-ComputerName` | Target computer | `DC01` or `@('DC01','FS01')` |
| `-ThreadCount` | Concurrent threads | `10` |

### **Module Installation**

```powershell
# Install all required modules
Install-Module -Name Posh-SSH
Install-Module -Name Az.Accounts, Az.Resources, Az.Compute, Az.Compute
```

---

## 🔐 Security Best Practices

1. **Credential Management**
   - Never hardcode credentials in scripts
   - Use `Get-Credential` or credential objects
   - Store sensitive data in Windows Credential Manager
   - Use Azure Key Vault for cloud credentials

2. **API Keys**
   - Rotate API keys regularly
   - Use read-only API permissions where possible
   - Never commit API keys to version control

3. **Execution Policy**
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Network Security**
   - Use SSH key authentication instead of passwords
   - Enable SSH key exchange logging
   - Restrict API access by IP address

---

## 📊 Sample Reports

All scripts generate:
- **CSV files** for data analysis
- **Markdown reports** for documentation
- **Timestamped files** for historical tracking

Example output structure:
```
output/
├── cisco_backup_20250110_143022.csv
├── palo_alto_audit_20250110_143022.md
└── azure_inventory_20250110_143022.csv
```

---

## 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd ScriptVault
   ```

2. **Install dependencies:**
   ```powershell
   .\setup\Install-Dependencies.ps1
   ```

3. **Run a test:**
   ```powershell
   .\tests\test_network_tools.ps1
   ```

4. **Create configuration files:**
   - Device lists (CSV format)
   - Server inventories
   - API credentials

---

## 📞 Support

For issues, questions, or contributions:
- Open an issue in the repository
- Documentation: See individual script headers

---

## 📝 License

MIT License - Personal Project

---

## 🔄 Version History

- **v1.0.0** (2025-01-10)
  - Initial release
  - Core network automation scripts
  - Cloud inventory tools
  - Windows/Linux audit capabilities

---

**Last Updated:** January 2025  
**Maintainer:** Personal Project
