# Web Script Scraper - Quick Guide

## 🎯 Features

- ✅ **Intelligent Naming**: Automatically categorizes scripts by content
- ✅ **Alphabetical Sorting**: Sorts scraped scripts by name
- ✅ **Auto GitHub Update**: Automatically commits and pushes to your vault
- ✅ **Smart Categorization**: Identifies ActiveDirectory, Network, Azure, AWS, etc.
- ✅ **Metadata Headers**: Adds source URL and date to each script

## 📝 Usage

### Basic Usage
```powershell
.\web_script_scraper.ps1 -GitHubToken "your_token" -Query "powershell automation" -Count 10
```

### Real Examples
```powershell
# Scrape Active Directory scripts
.\web_script_scraper.ps1 -GitHubToken "ghp_xxx" -Query "active directory" -Count 20

# Scrape network automation
.\web_script_scraper.ps1 -GitHubToken "ghp_xxx" -Query "network" -Count 15

# Scrape Azure scripts
.\web_script_scraper.ps1 -GitHubToken "ghp_xxx" -Query "azure automation" -Count 10
```

## 📂 Output Structure

After scraping, you'll have:

```
scraped_scripts/
├── ActiveDirectory_script_1234.ps1
├── Network_automation_5678.ps1
├── Azure_script_9012.ps1
├── SCRAPER_INDEX.txt           # Full list with URLs
├── sorted/                      # Alphabetically sorted
│   ├── ActiveDirectory_script_1234.ps1
│   ├── Azure_script_9012.ps1
│   ├── Network_automation_5678.ps1
│   └── SORTED_INDEX.txt        # Alphabetical list
```

## 🔑 Getting a GitHub Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "ScriptVault Scraper")
4. Select scopes: `public_repo` and `read:packages`
5. Click "Generate token"
6. Copy the token (starts with `ghp_`)

## ✨ What Happens Automatically

1. **Scrapes** scripts from GitHub Gist
2. **Analyzes** content for smart naming
3. **Saves** to `scraped_scripts/` folder
4. **Sorts** alphabetically in `sorted/` subfolder
5. **Commits** to Git automatically
6. **Pushes** to GitHub automatically

## 📋 Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-Source` | Source type | `gist`, `pastebin`, `all` |
| `-Query` | Search terms | `"powershell automation"` |
| `-Count` | Number of scripts | `10`, `20`, `50` |
| `-Language` | Filter by language | `PowerShell`, `Python` |
| `-OutputPath` | Save location | `".\my_scripts"` |
| `-GitHubToken` | Your token | `"ghp_xxxxx"` |

## 🎓 Categories Detected

The scraper automatically categorizes scripts into:
- **ActiveDirectory** (Get-ADUser, Get-ADGroup, etc.)
- **Network** (Test-Connection, SSH, etc.)
- **Azure** (Az commands)
- **AWS** (AWS CLI, S3, EC2)
- **Security** (Firewall, Certificates, etc.)
- **FileManagement** (Copy-Item, Get-Content, etc.)
- **SystemInfo** (Get-Process, Get-Service, etc.)
- **Email** (Send-MailMessage, SMTP)
- **Database** (SQL, MySQL)
- **Backup** (Archive, Compress)
- **Monitoring** (EventLog, Health checks)

## 💡 Pro Tips

1. **Start Small**: Test with `-Count 5` first
2. **Use Specific Queries**: More specific = better results
3. **Check Sorted Folder**: Organized alphabetically for easy browsing
4. **Review Index Files**: Lists all scraped scripts with URLs

## 🚀 Quick Start

```powershell
# 1. Get your token
# Visit: https://github.com/settings/tokens

# 2. Run scraper
.\web_script_scraper.ps1 -GitHubToken "YOUR_TOKEN" -Query "powershell" -Count 10

# 3. Check results
cd scraped_scripts\sorted
ls
```

Enjoy building your ScriptVault! 🎉

