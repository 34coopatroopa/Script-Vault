#Requires -Version 5.1

<#
.SYNOPSIS
    Intelligent Web Script Scraper with Smart Naming
    
.DESCRIPTION
    Scrapes scripts from various sources (GitHub Gist, Pastebin, GreasyFork)
    and saves them with intelligent naming conventions based on content analysis
    
.PARAMETER Source
    Type of source to scrape: 'gist', 'pastebin', 'greasyfork', or 'all'
    
.PARAMETER Query
    Search query for scripts
    
.PARAMETER Count
    Number of scripts to retrieve (default: 10)
    
.PARAMETER Language
    Programming language to filter (PowerShell, Python, JavaScript, etc.)
    
.PARAMETER OutputPath
    Directory to save scraped scripts
    
.PARAMETER GitHubToken
    GitHub Personal Access Token (optional, for authenticated API access)
    Get one at: https://github.com/settings/tokens
    
.EXAMPLE
    .\web_script_scraper.ps1 -Source gist -Query "active directory" -Count 20 -Language PowerShell
    
.EXAMPLE
    .\web_script_scraper.ps1 -GitHubToken "ghp_your_token_here" -Query "powershell automation" -Count 10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('gist', 'pastebin', 'greasyfork', 'all')]
    [string]$Source = 'gist',
    
    [Parameter(Mandatory=$false)]
    [string]$Query = "powershell automation",
    
    [Parameter(Mandatory=$false)]
    [int]$Count = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$Language = "PowerShell",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\scraped_scripts",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken
)

$ErrorActionPreference = 'Continue'

# Function to sanitize filenames
function Get-SafeFileName {
    param([string]$Name)
    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $safeName = $Name -replace "[$([regex]::Escape($invalidChars))]", '_'
    $safeName = $safeName -replace '\s+', '_'
    $safeName = $safeName.Trim('_', ' ')
    return $safeName.Substring(0, [Math]::Min(100, $safeName.Length))
}

# Function to analyze script content for intelligent naming
function Get-IntelligentName {
    param(
        [string]$Content,
        [string]$OriginalName
    )
    
    # Common keywords and patterns for categorization
    $patterns = @{
        'ActiveDirectory' = @('Get-ADUser', 'Get-ADGroup', 'New-ADUser', 'Import-Module ActiveDirectory', 'ADUsers', 'DomainController')
        'Network' = @('Test-Connection', 'Test-NetConnection', 'Invoke-WebRequest', 'ssh', 'telnet', 'ping', 'network', 'ipconfig')
        'FileManagement' = @('Get-ChildItem', 'Copy-Item', 'Move-Item', 'Remove-Item', 'New-Item', 'Get-Content', 'Set-Content')
        'SystemInfo' = @('Get-ComputerInfo', 'Get-Process', 'Get-Service', 'Get-WmiObject', 'Get-CimInstance', 'systeminfo')
        'Security' = @('Get-Acl', 'Set-Acl', 'Firewall', 'Security', 'Permission', 'Certificate', 'Encryption')
        'Azure' = @('Az', 'Azure', 'Connect-AzAccount', 'Get-AzResource', 'New-AzResource')
        'AWS' = @('AWS', 'Get-S3Object', 'aws s3', 'AWS CLI', 'EC2')
        'Email' = @('Send-MailMessage', 'Outlook', 'Exchange', 'SMTP', 'email')
        'Database' = @('SQL', 'MySQL', 'PostgreSQL', 'Invoke-Sqlcmd', 'database')
        'Backup' = @('Backup', 'Archive', 'Compress', 'Export', 'Dump')
        'Monitoring' = @('Monitor', 'EventLog', 'Log', 'Alert', 'Check', 'Health')
    }
    
    # Detect file extension from content
    $extension = if ($Content -match '#!/usr/bin/env python') { '.py' }
                 elseif ($Content -match 'import sys' -and $Content -match 'def main') { '.py' }
                 elseif ($Content -match 'require\(') { '.js' }
                 elseif ($Content -match 'powershell' -or $Content -match 'function ') { '.ps1' }
                 elseif ($Content -match '<html') { '.html' }
                 else { '.txt' }
    
    # Try to extract function names or common patterns
    $functionMatches = $Content | Select-String -Pattern 'function\s+(\w+-[\w-]+)' -AllMatches
    if ($functionMatches.Matches.Count -gt 0) {
        $firstFunction = $functionMatches.Matches[0].Groups[1].Value
        $firstFunction = $firstFunction -replace '-', '_'
        if ($firstFunction.Length -gt 3) {
            return Get-SafeFileName "$firstFunction$extension"
        }
    }
    
    # Categorize based on content
    foreach ($category in $patterns.Keys) {
        $matchCount = 0
        foreach ($pattern in $patterns[$category]) {
            if ($Content -match $pattern) {
                $matchCount++
            }
        }
        if ($matchCount -ge 2) {
            return Get-SafeFileName "${category}_script_$(Get-Random -Minimum 1000 -Maximum 9999)$extension"
        }
    }
    
    # Use original name with timestamp if no patterns match
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = if ($OriginalName) { $OriginalName } else { "script_$timestamp" }
    return Get-SafeFileName "$name$extension"
}

# Function to scrape GitHub Gist
function Get-GitHubGist {
    param(
        [string]$Query,
        [int]$Count,
        [string]$Token
    )
    
    Write-Host "`nScraping GitHub Gist..." -ForegroundColor Cyan
    $gists = @()
    
    try {
        $searchUrl = "https://api.github.com/search/code?q=$Query+extension:ps1&per_page=$Count"
        $headers = @{
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'ScriptVault-Scraper'
        }
        
        # Add authentication if token provided
        if ($Token) {
            $headers['Authorization'] = "Bearer $Token"
            Write-Host "Using authenticated GitHub API access" -ForegroundColor Green
        } else {
            Write-Host "Note: Using unauthenticated access (limited results)" -ForegroundColor Yellow
            Write-Host "For better results, use -GitHubToken parameter" -ForegroundColor Yellow
        }
        
        $response = Invoke-RestMethod -Uri $searchUrl -Headers $headers -TimeoutSec 30
        Write-Host "Found $($response.items.Count) potential scripts" -ForegroundColor Green
        
        foreach ($item in $response.items) {
            try {
                $gistUrl = $item.html_url -replace '/blob/', '/raw/'
                $content = Invoke-RestMethod -Uri $gistUrl -TimeoutSec 30
                
                $gists += [PSCustomObject]@{
                    Name = $item.name
                    Content = $content
                    URL = $item.html_url
                    Source = 'GitHub Gist'
                    Language = $item.name.Split('.')[-1]
                }
                
                Write-Host "  [OK] Retrieved: $($item.name)" -ForegroundColor Green
                Start-Sleep -Milliseconds 500  # Rate limiting
            } catch {
                Write-Warning "Failed to retrieve $($item.name): $_"
            }
        }
    } catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -like "*authentication*" -or $errorMessage -like "*401*") {
            Write-Warning "GitHub API requires authentication for Code Search"
            Write-Host "`nTo fix this, you have two options:" -ForegroundColor Yellow
            Write-Host "1. Create a GitHub Personal Access Token:" -ForegroundColor Cyan
            Write-Host "   - Go to: https://github.com/settings/tokens" -ForegroundColor Gray
            Write-Host "   - Generate a token with 'public_repo' scope" -ForegroundColor Gray
            Write-Host "   - Run: .\web_script_scraper.ps1 -GitHubToken 'your_token' -Query 'powershell' -Count 10" -ForegroundColor Gray
            Write-Host "`n2. Manual scraping alternative:" -ForegroundColor Cyan
            Write-Host "   Search manually at https://gist.github.com/search?q=powershell" -ForegroundColor Gray
            Write-Host "   Copy script URLs and download individually" -ForegroundColor Gray
        } else {
            Write-Error "Error accessing GitHub Gist: $_"
        }
    }
    
    return $gists
}

# Function to scrape Pastebin (public pastes only)
function Get-Pastebin {
    param(
        [string]$Query,
        [int]$Count
    )
    
    Write-Host "`nScraping Pastebin (Note: Requires Pastebin API key for search)..." -ForegroundColor Yellow
    Write-Host "Pastebin scraping requires API access. Using sample data." -ForegroundColor Yellow
    
    # Note: Actual Pastebin scraping requires API key
    # This is a placeholder implementation
    $pastes = @()
    
    return $pastes
}

# Function to get GitHub raw content
function Get-GitHubRawContent {
    param([string]$URL)
    
    if ($URL -match 'github\.com/([^/]+)/([^/]+)/blob/(.+)$') {
        $user = $Matches[1]
        $repo = $Matches[2]
        $path = $Matches[3]
        return "https://raw.githubusercontent.com/$user/$repo/$path"
    }
    return $URL
}

# Main execution
Write-Host "=== Intelligent Web Script Scraper ===" -ForegroundColor Yellow
Write-Host "Source: $Source" -ForegroundColor Cyan
Write-Host "Query: $Query" -ForegroundColor Cyan
Write-Host "Count: $Count" -ForegroundColor Cyan
Write-Host "Language: $Language" -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "`nCreated output directory: $OutputPath" -ForegroundColor Green
}

$allScripts = @()

# Scrape based on source
switch ($Source) {
    'gist' {
        $allScripts += Get-GitHubGist -Query $Query -Count $Count -Token $GitHubToken
    }
    'pastebin' {
        $allScripts += Get-Pastebin -Query $Query -Count $Count
    }
    'all' {
        $allScripts += Get-GitHubGist -Query $Query -Count $Count -Token $GitHubToken
        $allScripts += Get-Pastebin -Query $Query -Count $Count
    }
}

# Save scripts with intelligent naming
Write-Host "`nSaving scripts with intelligent naming..." -ForegroundColor Cyan
$savedCount = 0

foreach ($script in $allScripts) {
    try {
        $intelligentName = Get-IntelligentName -Content $script.Content -OriginalName $script.Name
        $filePath = Join-Path $OutputPath $intelligentName
        
        # Add metadata as comment at top of file
        $metadata = @"
# Scraped by ScriptVault Web Scraper
# Source: $($script.Source)
# Original Name: $($script.Name)
# Scraped: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# URL: $($script.URL)

"@
        
        $contentToSave = $metadata + $script.Content
        $contentToSave | Out-File -FilePath $filePath -Encoding UTF8
        
        Write-Host "  [OK] Saved: $intelligentName" -ForegroundColor Green
        $savedCount++
        
    } catch {
        Write-Warning "Failed to save script: $_"
    }
}

# Generate summary report
Write-Host "`n=== Scraping Summary ===" -ForegroundColor Yellow
Write-Host "Scripts retrieved: $($allScripts.Count)" -ForegroundColor Cyan
Write-Host "Scripts saved: $savedCount" -ForegroundColor Green
Write-Host "Output location: $OutputPath" -ForegroundColor Cyan

# Create index file
$indexPath = Join-Path $OutputPath "SCRAPER_INDEX.txt"
$indexContent = @"
ScriptVault Web Scraper Index
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source: $Source
Query: $Query

Scripts Saved ($savedCount):
"@

foreach ($script in $allScripts) {
    $intelligentName = Get-IntelligentName -Content $script.Content -OriginalName $script.Name
    $indexContent += "`n- $intelligentName"
    $indexContent += "  Original: $($script.Name)"
    $indexContent += "  URL: $($script.URL)"
}

$indexContent | Out-File -FilePath $indexPath -Encoding UTF8

Write-Host "`nIndex created: $indexPath" -ForegroundColor Green
Write-Host "`nScraping complete!" -ForegroundColor Yellow
