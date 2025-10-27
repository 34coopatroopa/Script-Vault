#Requires -Version 5.1

<#
.SYNOPSIS
    Generate Searchable Repository Index
    
.DESCRIPTION
    Creates a comprehensive searchable HTML index of all scripts in the ScriptVault
    with filtering, categorization, and search capabilities
    
.PARAMETER OutputPath
    Output directory for the searchable index
    
.EXAMPLE
    .\generate_searchable_index.ps1 -OutputPath ".\docs"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\docs"
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Generating Searchable Repository Index ===" -ForegroundColor Yellow

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Find all scripts
$scripts = Get-ChildItem -Recurse -Filter "*.ps1" | Where-Object {
    $_.FullName -notlike "*\Run-QuickValidation.ps1" -and
    $_.FullName -notlike "*\tests\*" -and
    $_.FullName -notlike "*\scraped_scripts\*"
}

$pythonScripts = Get-ChildItem -Recurse -Filter "*.py" | Where-Object {
    $_.FullName -notlike "*\scraped_scripts\*"
}

$allScripts = @($scripts) + @($pythonScripts)

Write-Host "Found $($allScripts.Count) scripts to index" -ForegroundColor Green

# Categorize scripts
$categorizedScripts = @{
    'Network Tools' = @()
    'Server Management' = @()
    'Cloud Automation' = @()
    'Utilities' = @()
    'Testing' = @()
    'Other' = @()
}

foreach ($script in $allScripts) {
    $relativePath = $script.FullName.Replace((Get-Location).Path, "").TrimStart('\')
    
    # Get help information
    $help = Get-Help -Path $script.FullName -ErrorAction SilentlyContinue
    $synopsis = if ($help -and $help.Synopsis) { $help.Synopsis } else { "No description available" }
    $description = if ($help -and $help.Description) { $help.Description.Text -join ' ' } else { $synopsis }
    
    # Categorize
    $category = "Other"
    if ($relativePath -like "*\network\*") {
        $category = "Network Tools"
    } elseif ($relativePath -like "*\server\*") {
        $category = "Server Management"
    } elseif ($relativePath -like "*\cloud\*") {
        $category = "Cloud Automation"
    } elseif ($relativePath -like "*\utilities\*") {
        $category = "Utilities"
    } elseif ($relativePath -like "*\tests\*") {
        $category = "Testing"
    }
    
    $scriptData = @{
        Name = $script.Name
        Path = $relativePath
        Category = $category
        Synopsis = $synopsis
        Description = $description
        Lines = (Get-Content $script.FullName).Count
        Modified = $script.LastWriteTime
        Extension = $script.Extension
    }
    
    $categorizedScripts[$category] += $scriptData
}

# Read scraped scripts if they exist
$scrapedScripts = @()
if (Test-Path ".\utilities\powershell\scraped_scripts\sorted") {
    $scrapedFiles = Get-ChildItem -Path ".\utilities\powershell\scraped_scripts\sorted" -Filter "*.ps1" -File | Where-Object { $_.Name -ne "SORTED_INDEX.txt" }
    foreach ($file in $scrapedFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            $firstLines = ($content -split "`n")[0..20] -join "`n"
            
            $scrapedScripts += @{
                Name = $file.Name
                Path = "scraped_scripts/sorted/" + $file.Name
                Category = "Scraped Scripts"
                Synopsis = "Scraped from web"
                Description = $firstLines.Substring(0, [Math]::Min(200, $firstLines.Length))
                Lines = $content.Split("`n").Count
                Modified = $file.LastWriteTime
                Extension = $file.Extension
            }
        } catch {}
    }
    Write-Host "Found $($scrapedFiles.Count) scraped scripts" -ForegroundColor Green
}

# Generate JSON index for programmatic access
$jsonIndex = @{
    generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalScripts = $allScripts.Count + $scrapedScripts.Count
    categories = @{}
    scripts = @()
}

# Add all scripts to JSON
foreach ($category in $categorizedScripts.Keys) {
    $jsonIndex.categories[$category] = $categorizedScripts[$category].Count
    foreach ($script in $categorizedScripts[$category]) {
        $jsonIndex.scripts += $script
    }
}

$jsonIndex.categories['Scraped Scripts'] = $scrapedScripts.Count
foreach ($script in $scrapedScripts) {
    $jsonIndex.scripts += $script
}

$jsonPath = Join-Path $OutputPath "index.json"
$jsonIndex | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "JSON index created: $jsonPath" -ForegroundColor Green

# Generate interactive HTML search page
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ScriptVault - Searchable Repository Index</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 20px;
            text-align: center;
        }
        
        .header h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #666;
            font-size: 1.1em;
        }
        
        .search-container {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 20px;
        }
        
        .search-box {
            width: 100%;
            padding: 15px;
            font-size: 16px;
            border: 2px solid #667eea;
            border-radius: 10px;
            margin-bottom: 15px;
        }
        
        .search-box:focus {
            outline: none;
            border-color: #764ba2;
        }
        
        .filters {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .filter-tag {
            padding: 8px 15px;
            background: #f0f0f0;
            border: 2px solid #667eea;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .filter-tag:hover {
            background: #667eea;
            color: white;
        }
        
        .filter-tag.active {
            background: #667eea;
            color: white;
        }
        
        .stats {
            background: white;
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
        }
        
        .stat-item {
            text-align: center;
        }
        
        .stat-number {
            font-size: 2.5em;
            color: #667eea;
            font-weight: bold;
        }
        
        .stat-label {
            color: #666;
            font-size: 0.9em;
        }
        
        .results {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        
        .result-item {
            padding: 20px;
            border: 2px solid #f0f0f0;
            border-radius: 10px;
            margin-bottom: 15px;
            transition: all 0.3s;
        }
        
        .result-item:hover {
            border-color: #667eea;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
        }
        
        .result-item.hidden {
            display: none;
        }
        
        .result-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .result-name {
            font-size: 1.3em;
            color: #667eea;
            font-weight: bold;
        }
        
        .result-badge {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 0.85em;
            background: #667eea;
            color: white;
        }
        
        .result-path {
            color: #666;
            font-family: 'Courier New', monospace;
            margin: 5px 0;
        }
        
        .result-description {
            color: #888;
            margin-top: 10px;
            line-height: 1.6;
        }
        
        .result-meta {
            display: flex;
            gap: 20px;
            margin-top: 10px;
            font-size: 0.9em;
            color: #aaa;
        }
        
        .highlight {
            background: yellow;
            padding: 2px 4px;
            border-radius: 3px;
        }
        
        @media (max-width: 768px) {
            .header h1 {
                font-size: 1.8em;
            }
            
            .filters {
                flex-direction: column;
            }
            
            .stats {
                flex-direction: column;
                gap: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 ScriptVault</h1>
            <p>Searchable Repository Index | Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
        
        <div class="search-container">
            <input type="text" id="searchBox" class="search-box" placeholder="Search scripts... (Try: 'network', 'azure', 'active directory')">
            <div class="filters" id="filters"></div>
        </div>
        
        <div class="stats">
            <div class="stat-item">
                <div class="stat-number" id="totalScripts">0</div>
                <div class="stat-label">Total Scripts</div>
            </div>
            <div class="stat-item">
                <div class="stat-number" id="visibleScripts">0</div>
                <div class="stat-label">Visible</div>
            </div>
            <div class="stat-item">
                <div class="stat-number" id="categories">0</div>
                <div class="stat-label">Categories</div>
            </div>
        </div>
        
        <div class="results" id="results"></div>
    </div>
    
    <script>
        const data = $($jsonIndex | ConvertTo-Json -Compress);
        
        function init() {
            // Display stats
            document.getElementById('totalScripts').textContent = data.totalScripts;
            document.getElementById('visibleScripts').textContent = data.totalScripts;
            document.getElementById('categories').textContent = Object.keys(data.categories).length;
            
            // Create category filters
            const filtersDiv = document.getElementById('filters');
            Object.keys(data.categories).forEach(cat => {
                const tag = document.createElement('div');
                tag.className = 'filter-tag';
                tag.textContent = cat + ' (' + data.categories[cat] + ')';
                tag.onclick = () => filterByCategory(cat);
                filtersDiv.appendChild(tag);
            });
            
            // Add 'All' filter
            const allTag = document.createElement('div');
            allTag.className = 'filter-tag active';
            allTag.textContent = 'All';
            allTag.onclick = () => filterByCategory('All');
            filtersDiv.insertBefore(allTag, filtersDiv.firstChild);
            
            // Render all scripts
            renderScripts(data.scripts);
            
            // Setup search
            document.getElementById('searchBox').addEventListener('input', handleSearch);
        }
        
        function renderScripts(scripts) {
            const resultsDiv = document.getElementById('results');
            resultsDiv.innerHTML = '';
            
            if (scripts.length === 0) {
                resultsDiv.innerHTML = '<p style="text-align:center;color:#999;padding:40px;">No scripts found</p>';
                return;
            }
            
            scripts.forEach(script => {
                const div = document.createElement('div');
                div.className = 'result-item';
                div.dataset.category = script.Category;
                
                div.innerHTML = \`
                    <div class="result-header">
                        <span class="result-name">\${escapeHtml(script.Name)}</span>
                        <span class="result-badge">\${script.Category}</span>
                    </div>
                    <div class="result-path">📁 \${script.Path}</div>
                    <div class="result-description">\${escapeHtml(script.Synopsis)}</div>
                    <div class="result-meta">
                        <span>📊 \${script.Lines} lines</span>
                        <span>🔧 \${script.Extension}</span>
                        <span>📅 \${new Date(script.Modified).toLocaleDateString()}</span>
                    </div>
                \`;
                
                resultsDiv.appendChild(div);
            });
            
            updateVisibleCount();
        }
        
        function handleSearch() {
            const query = document.getElementById('searchBox').value.toLowerCase();
            const category = document.querySelector('.filter-tag.active')?.textContent.split(' (')[0];
            
            let filtered = data.scripts;
            
            // Filter by category
            if (category && category !== 'All') {
                filtered = filtered.filter(s => s.Category === category);
            }
            
            // Filter by search query
            if (query) {
                filtered = filtered.filter(script => 
                    script.Name.toLowerCase().includes(query) ||
                    script.Synopsis.toLowerCase().includes(query) ||
                    script.Path.toLowerCase().includes(query) ||
                    (script.Description && script.Description.toLowerCase().includes(query))
                );
            }
            
            renderScripts(filtered);
            highlightSearch(query);
        }
        
        function filterByCategory(category) {
            // Update active tag
            document.querySelectorAll('.filter-tag').forEach(tag => tag.classList.remove('active'));
            event.target.classList.add('active');
            
            handleSearch();
        }
        
        function highlightSearch(query) {
            if (!query) return;
            
            const items = document.querySelectorAll('.result-item:not(.hidden)');
            items.forEach(item => {
                const escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\`$&');
                const regex = new RegExp(escapedQuery, 'gi');
                item.innerHTML = item.innerHTML.replace(
                    regex,
                    match => '<span class="highlight">' + match + '</span>'
                );
            });
        }
        
        function updateVisibleCount() {
            const visible = document.querySelectorAll('.result-item:not(.hidden)').length;
            document.getElementById('visibleScripts').textContent = visible;
        }
        
        function escapeHtml(text) {
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return text.replace(/[&<>"']/g, m => map[m]);
        }
        
        // Initialize on page load
        init();
    </script>
</body>
</html>
"@

$htmlPath = Join-Path $OutputPath "index.html"
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "HTML index created: $htmlPath" -ForegroundColor Green

Write-Host "`n=== Index Generation Complete ===" -ForegroundColor Yellow
Write-Host "Total scripts indexed: $($allScripts.Count)" -ForegroundColor Cyan
Write-Host "Scraped scripts indexed: $($scrapedScripts.Count)" -ForegroundColor Cyan
Write-Host "Categories: $($categorizedScripts.Keys.Count)" -ForegroundColor Cyan
Write-Host "`nOpen index.html in your browser to search!" -ForegroundColor Green

