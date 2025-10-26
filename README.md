# ScriptVault - IT Infrastructure Automation Library

Comprehensive PowerShell and Python automation library for IT infrastructure management, network administration, cloud operations, and security auditing. Designed for RSM IT Infrastructure Consultants.

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
**File:** `network/cisco/cisco_config_backup.ps1`

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
**File:** `network/palo_alto/palo_alto_rule_audit.ps1`

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
**File:** `network/meraki/meraki_device_inventory.ps1`

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
**File:** `server/windows/windows_server_audit.ps1`

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

### **Linux Server Security Hardening**
**File:** `server/linux/linux_server_hardening.ps1`

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
**File:** `cloud/azure/azure_resource_inventory.ps1`

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
**File:** `cloud/aws/aws_resource_inventory.ps1`

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
**File:** `utilities/powershell/infrastructure_reporting.ps1`

Unified reporting framework for cross-platform infrastructure.

**Usage:**
```powershell
.\infrastructure_reporting.ps1 -ReportType summary -GenerateDashboard -OutputPath C:\Reports
```

---

### **Network Analyzer (Python)**
**File:** `utilities/python/network_analyzer.py`

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

## 🧪 Testing

### **Test Suite**
**File:** `tests/test_network_tools.ps1`

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
- Contact: RSM IT Infrastructure Team
- Documentation: See individual script headers

---

## 📝 License

Proprietary - RSM Internal Use Only

---

## 🔄 Version History

- **v1.0.0** (2025-01-10)
  - Initial release
  - Core network automation scripts
  - Cloud inventory tools
  - Windows/Linux audit capabilities

---

**Last Updated:** January 2025  
**Maintainer:** RSM IT Infrastructure Team
