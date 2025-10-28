#!/usr/bin/env python3
"""
ScriptVault UI - Simple Web Interface for Navigating Scripts
Lightweight Flask-based web interface
"""

from flask import Flask, render_template, jsonify, send_file, request
import os
import json
from pathlib import Path

app = Flask(__name__)

# Get the ScriptVault root directory (go up from utilities/python)
SCRIPT_VAULT_ROOT = Path(__file__).parent.parent.parent

@app.route('/')
def index():
    """Main index page"""
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>ScriptVault Navigator</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 20px;
            }
            .container {
                max-width: 1200px;
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
            .search-box {
                width: 100%;
                padding: 15px;
                font-size: 16px;
                border: 2px solid #667eea;
                border-radius: 10px;
                margin-bottom: 20px;
                box-sizing: border-box;
            }
            .categories {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 20px;
                margin-bottom: 20px;
            }
            .category-card {
                background: white;
                padding: 25px;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                cursor: pointer;
                transition: all 0.3s;
            }
            .category-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            }
            .category-icon {
                font-size: 3em;
                margin-bottom: 10px;
            }
            .category-title {
                font-size: 1.5em;
                color: #667eea;
                margin-bottom: 10px;
            }
            .category-count {
                color: #666;
                font-size: 0.9em;
            }
            .scripts-panel {
                background: white;
                padding: 25px;
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.2);
                display: none;
            }
            .scripts-panel.show {
                display: block;
            }
            .script-item {
                padding: 15px;
                border: 2px solid #f0f0f0;
                border-radius: 10px;
                margin-bottom: 10px;
                cursor: pointer;
                transition: all 0.3s;
            }
            .script-item:hover {
                border-color: #667eea;
                background: #f8f9ff;
            }
            .script-name {
                font-weight: bold;
                color: #667eea;
                margin-bottom: 5px;
            }
            .script-path {
                color: #666;
                font-family: 'Courier New', monospace;
                font-size: 0.9em;
            }
            .back-btn {
                display: inline-block;
                padding: 10px 20px;
                background: #667eea;
                color: white;
                text-decoration: none;
                border-radius: 10px;
                margin-bottom: 20px;
                cursor: pointer;
                border: none;
            }
            .back-btn:hover {
                background: #764ba2;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔍 ScriptVault Navigator</h1>
                <p>Browse and navigate your scripts easily</p>
            </div>
            
            <input type="text" class="search-box" id="searchBox" placeholder="Search scripts...">
            
            <div class="categories" id="categories"></div>
            
            <div class="scripts-panel" id="scriptsPanel">
                <button class="back-btn" onclick="showCategories()">← Back to Categories</button>
                <div id="scriptsList"></div>
            </div>
        </div>
        
        <script>
            let allScripts = {};
            let currentCategory = '';
            
            // Load script data
            fetch('/api/scripts')
                .then(res => res.json())
                .then(data => {
                    allScripts = data;
                    renderCategories();
                });
            
            function renderCategories() {
                const categoriesDiv = document.getElementById('categories');
                const categories = {};
                
                // Count scripts by category
                Object.keys(allScripts).forEach(path => {
                    const category = getCategory(path);
                    if (!categories[category]) {
                        categories[category] = { count: 0, icon: getIcon(category) };
                    }
                    categories[category].count++;
                });
                
                // Render category cards
                Object.keys(categories).sort().forEach(cat => {
                    const card = document.createElement('div');
                    card.className = 'category-card';
                    card.innerHTML = `
                        <div class="category-icon">${categories[cat].icon}</div>
                        <div class="category-title">${cat}</div>
                        <div class="category-count">${categories[cat].count} scripts</div>
                    `;
                    card.onclick = () => showScripts(cat);
                    categoriesDiv.appendChild(card);
                });
            }
            
            function getCategory(path) {
                if (path.includes('network/')) return 'Network Tools';
                if (path.includes('server/')) return 'Server Management';
                if (path.includes('cloud/')) return 'Cloud Automation';
                if (path.includes('utilities/')) return 'Utilities';
                if (path.includes('tests/')) return 'Testing';
                return 'Other';
            }
            
            function getIcon(category) {
                const icons = {
                    'Network Tools': '🌐',
                    'Server Management': '🖥️',
                    'Cloud Automation': '☁️',
                    'Utilities': '🔧',
                    'Testing': '🧪',
                    'Other': '📄'
                };
                return icons[category] || '📁';
            }
            
            function showScripts(category) {
                currentCategory = category;
                document.querySelector('.categories').style.display = 'none';
                document.getElementById('scriptsPanel').classList.add('show');
                
                const filteredScripts = Object.entries(allScripts)
                    .filter(([path, _]) => getCategory(path) === category);
                
                renderScripts(filteredScripts);
            }
            
            function showCategories() {
                document.querySelector('.categories').style.display = 'grid';
                document.getElementById('scriptsPanel').classList.remove('show');
                document.getElementById('searchBox').value = '';
            }
            
            function renderScripts(scripts) {
                const scriptsList = document.getElementById('scriptsList');
                scriptsList.innerHTML = '';
                
                scripts.sort((a, b) => a[0].localeCompare(b[0]));
                
                scripts.forEach(([path, name]) => {
                    const item = document.createElement('div');
                    item.className = 'script-item';
                    item.innerHTML = `
                        <div class="script-name">${name}</div>
                        <div class="script-path">📁 ${path}</div>
                    `;
                    item.onclick = () => window.open(`/view?path=${encodeURIComponent(path)}`, '_blank');
                    scriptsList.appendChild(item);
                });
            }
            
            // Search functionality
            document.getElementById('searchBox').addEventListener('input', (e) => {
                const query = e.target.value.toLowerCase();
                
                if (!query) {
                    if (document.getElementById('scriptsPanel').classList.contains('show')) {
                        showScripts(currentCategory);
                    }
                    return;
                }
                
                const filtered = Object.entries(allScripts)
                    .filter(([path, name]) => 
                        name.toLowerCase().includes(query) || path.toLowerCase().includes(query)
                    );
                
                document.querySelector('.categories').style.display = 'none';
                document.getElementById('scriptsPanel').classList.add('show');
                renderScripts(filtered);
            });
        </script>
    </body>
    </html>
    """

@app.route('/api/scripts')
def get_scripts():
    """Get all scripts as JSON"""
    scripts = {}
    
    # Find all .ps1 and .py files
    for ext in ['*.ps1', '*.py']:
        for script_path in SCRIPT_VAULT_ROOT.rglob(ext):
            # Skip scraped scripts and test files
            if 'scraped_scripts' in str(script_path) or 'tests' in str(script_path):
                continue
            
            rel_path = str(script_path.relative_to(SCRIPT_VAULT_ROOT))
            scripts[rel_path] = script_path.name
    
    return jsonify(scripts)

@app.route('/view')
def view_script():
    """View a script file"""
    import urllib.parse
    path = urllib.parse.unquote(request.args.get('path', ''))
    script_path = SCRIPT_VAULT_ROOT / path
    
    if not script_path.exists():
        return "Script not found", 404
    
    return send_file(script_path)

if __name__ == '__main__':
    print("=" * 60)
    print("🔍 ScriptVault UI - Starting...")
    print("=" * 60)
    print(f"Root directory: {SCRIPT_VAULT_ROOT}")
    print("\n🌐 Opening browser at http://localhost:5000")
    print("Press Ctrl+C to stop")
    print("=" * 60)
    
    import webbrowser
    import time
    
    def open_browser():
        time.sleep(1)
        webbrowser.open('http://localhost:5000')
    
    import threading
    threading.Thread(target=open_browser).start()
    
    app.run(debug=False, port=5000)

