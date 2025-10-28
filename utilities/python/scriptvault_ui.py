#!/usr/bin/env python3
"""
ScriptVault UI - Standalone Desktop Application
Tkinter-based GUI for navigating scripts
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import os
from pathlib import Path
import webbrowser
import subprocess
import platform

# Get the ScriptVault root directory
SCRIPT_VAULT_ROOT = Path(__file__).parent.parent.parent

class ScriptVaultGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("ScriptVault Navigator")
        self.root.geometry("1200x800")
        self.root.configure(bg='#f0f0f0')
        
        # Configure window icon (if available)
        try:
            self.root.iconbitmap(default='icon.ico')
        except:
            pass
        
        # Style configuration
        self.setup_styles()
        
        # Data
        self.scripts = {}
        self.filtered_scripts = {}
        self.current_category = 'All'
        self.load_scripts()
        
        # UI Components
        self.create_widgets()
        
    def setup_styles(self):
        """Configure modern styling"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Configure colors
        style.configure('Title.TLabel', 
                       font=('Segoe UI', 18, 'bold'),
                       background='#667eea',
                       foreground='white')
        
        style.configure('Category.TLabel',
                       font=('Segoe UI', 12, 'bold'),
                       background='#f8f9ff',
                       foreground='#667eea')
        
        style.configure('Count.TLabel',
                       font=('Segoe UI', 10),
                       background='#f8f9ff',
                       foreground='#666')
    
    def load_scripts(self):
        """Load all scripts from ScriptVault"""
        print("Loading scripts...")
        
        # First load regular scripts
        for ext in ['*.ps1', '*.py']:
            for script_path in SCRIPT_VAULT_ROOT.rglob(ext):
                # Skip test files
                if 'tests' in str(script_path):
                    continue
                
                # Skip scraped scripts for now (will load separately)
                if 'scraped_scripts' in str(script_path):
                    continue
                
                rel_path = str(script_path.relative_to(SCRIPT_VAULT_ROOT))
                
                # Try to get description from script
                description = self.get_script_description(script_path)
                
                self.scripts[rel_path] = {
                    'name': script_path.name,
                    'full_path': str(script_path),
                    'category': self.get_category(rel_path, False),
                    'description': description,
                    'lines': self.count_lines(script_path),
                    'scraped': False
                }
        
        # Then load scraped scripts from sorted folder
        scraped_dir = SCRIPT_VAULT_ROOT / "utilities" / "powershell" / "scraped_scripts" / "sorted"
        if scraped_dir.exists():
            print(f"Loading scraped scripts from: {scraped_dir}")
            for ext in ['*.ps1', '*.py', '*.txt', '*.html']:
                for script_path in scraped_dir.rglob(ext):
                    if script_path.name in ['SCRAPER_INDEX.txt', 'SORTED_INDEX.txt']:
                        continue
                    
                    rel_path = str(script_path.relative_to(SCRIPT_VAULT_ROOT))
                    
                    # Try to get description from script
                    description = self.get_script_description(script_path)
                    
                    self.scripts[rel_path] = {
                        'name': script_path.name,
                        'full_path': str(script_path),
                        'category': self.get_category(str(script_path), True),
                        'description': description,
                        'lines': self.count_lines(script_path),
                        'scraped': True
                    }
        
        self.filtered_scripts = self.scripts.copy()
        print(f"Loaded {len(self.scripts)} scripts ({sum(1 for s in self.scripts.values() if s['scraped'])} scraped)")
    
    def get_script_description(self, script_path):
        """Extract description from script header"""
        try:
            with open(script_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                # Look for .SYNOPSIS or description in first 20 lines
                for i, line in enumerate(lines[:20]):
                    if '.SYNOPSIS' in line.upper() and i + 1 < len(lines):
                        desc = lines[i + 1].strip()
                        if desc and not desc.startswith('.'):
                            return desc[:60] + '...' if len(desc) > 60 else desc
                    elif '# Description' in line and i + 1 < len(lines):
                        desc = lines[i + 1].strip()
                        if desc and not desc.startswith('#'):
                            return desc[:60] + '...' if len(desc) > 60 else desc
        except:
            pass
        return "No description available"
    
    def count_lines(self, script_path):
        """Count lines in script"""
        try:
            with open(script_path, 'r', encoding='utf-8', errors='ignore') as f:
                return len(f.readlines())
        except:
            return 0
    
    def get_category(self, path, is_scraped=False):
        """Determine script category"""
        if is_scraped:
            # Determine category from scraped script name/content
            if any(word in path.lower() for word in ['azure', 'aws', 'cloud']):
                return '☁️ Scraped - Cloud'
            elif any(word in path.lower() for word in ['network', 'cisco', 'meraki']):
                return '🌐 Scraped - Network'
            elif any(word in path.lower() for word in ['security', 'admin', 'permission']):
                return '🔒 Scraped - Security'
            elif any(word in path.lower() for word in ['database', 'sql', 'mysql']):
                return '💾 Scraped - Database'
            else:
                return '📥 Scraped Scripts'
        elif 'network' in path:
            return '🌐 Network Tools'
        elif 'server' in path:
            return '🖥️ Server Management'
        elif 'cloud' in path:
            return '☁️ Cloud Automation'
        elif 'utilities' in path:
            return '🔧 Utilities'
        elif 'tests' in path:
            return '🧪 Testing'
        else:
            return '📄 Other'
    
    def create_widgets(self):
        """Create and layout all UI components"""
        # Header
        header = tk.Frame(self.root, bg='#667eea', height=80)
        header.pack(fill='x')
        
        title = tk.Label(header, text="🔍 ScriptVault Navigator", 
                        font=('Segoe UI', 24, 'bold'),
                        bg='#667eea', fg='white')
        title.pack(pady=20)
        
        # Main container
        main_frame = tk.Frame(self.root, bg='#f0f0f0')
        main_frame.pack(fill='both', expand=True, padx=20, pady=20)
        
        # Left panel - Categories and Search
        left_panel = tk.Frame(main_frame, bg='white', width=300)
        left_panel.pack(side='left', fill='both', padx=(0, 10))
        left_panel.pack_propagate(False)
        
        # Search box
        search_label = tk.Label(left_panel, text="Search:", 
                               font=('Segoe UI', 10, 'bold'),
                               bg='white')
        search_label.pack(pady=(20, 5), padx=20, anchor='w')
        
        self.search_var = tk.StringVar()
        self.search_var.trace('w', self.on_search)
        search_entry = ttk.Entry(left_panel, textvariable=self.search_var,
                                font=('Segoe UI', 11))
        search_entry.pack(fill='x', padx=20, pady=(0, 20))
        
        # Statistics
        stats_label = tk.Label(left_panel, 
                              text=f"📊 Total: {len(self.scripts)} scripts",
                              font=('Segoe UI', 10),
                              bg='white', fg='#666')
        stats_label.pack(padx=20, pady=(0, 20))
        
        # Categories
        categories_label = tk.Label(left_panel, text="Categories:",
                                   font=('Segoe UI', 10, 'bold'),
                                   bg='white')
        categories_label.pack(pady=(0, 10), padx=20, anchor='w')
        
        self.categories_frame = tk.Frame(left_panel, bg='white')
        self.categories_frame.pack(fill='both', expand=True, padx=20)
        
        self.update_categories()
        
        # Right panel - Script list
        right_panel = tk.Frame(main_frame, bg='white')
        right_panel.pack(side='right', fill='both', expand=True)
        
        # Script list header with count
        header_frame = tk.Frame(right_panel, bg='white')
        header_frame.pack(fill='x', padx=20, pady=(20, 10))
        
        list_header = tk.Label(header_frame, text="📁 Scripts",
                              font=('Segoe UI', 14, 'bold'),
                              bg='white')
        list_header.pack(side='left')
        
        self.count_label = tk.Label(header_frame, text="",
                                    font=('Segoe UI', 10),
                                    bg='white', fg='#666')
        self.count_label.pack(side='left', padx=(10, 0))
        
        # Treeview for better display
        tree_frame = tk.Frame(right_panel, bg='white')
        tree_frame.pack(fill='both', expand=True, padx=20, pady=(0, 20))
        
        # Create Treeview with columns
        columns = ('name', 'path', 'lines')
        self.script_tree = ttk.Treeview(tree_frame, columns=columns, show='tree headings',
                                        selectmode='browse', height=20)
        
        # Configure columns
        self.script_tree.heading('#0', text='Category')
        self.script_tree.heading('name', text='Script Name')
        self.script_tree.heading('path', text='Path')
        self.script_tree.heading('lines', text='Lines')
        
        self.script_tree.column('#0', width=150)
        self.script_tree.column('name', width=250)
        self.script_tree.column('path', width=400)
        self.script_tree.column('lines', width=80)
        
        # Scrollbar
        scrollbar = ttk.Scrollbar(tree_frame, orient='vertical', command=self.script_tree.yview)
        self.script_tree.configure(yscrollcommand=scrollbar.set)
        
        self.script_tree.pack(side='left', fill='both', expand=True)
        scrollbar.pack(side='right', fill='y')
        
        # Bind events
        self.script_tree.bind('<Double-Button-1>', self.open_script)
        self.script_tree.bind('<Button-1>', self.on_select)
        
        # Details panel
        details_frame = tk.Frame(right_panel, bg='#f8f9ff', relief='groove', bd=2)
        details_frame.pack(fill='x', padx=20, pady=(0, 10))
        
        self.details_text = scrolledtext.ScrolledText(details_frame, 
                                                       height=4,
                                                       font=('Segoe UI', 9),
                                                       bg='white',
                                                       wrap=tk.WORD,
                                                       relief='flat')
        self.details_text.pack(fill='both', expand=True, padx=5, pady=5)
        self.details_text.config(state='disabled')
        
        # Buttons
        button_frame = tk.Frame(right_panel, bg='white')
        button_frame.pack(fill='x', padx=20, pady=(0, 20))
        
        open_btn = tk.Button(button_frame, text="📖 Open Script",
                            font=('Segoe UI', 11, 'bold'),
                            bg='#667eea', fg='white',
                            relief='flat', padx=20, pady=10,
                            command=self.open_script,
                            cursor='hand2')
        open_btn.pack(side='left', padx=5)
        
        browse_btn = tk.Button(button_frame, text="📂 Browse Folder",
                              font=('Segoe UI', 11),
                              bg='#e0e0e0',
                              relief='flat', padx=20, pady=10,
                              command=self.browse_folder,
                              cursor='hand2')
        browse_btn.pack(side='left', padx=5)
        
        refresh_btn = tk.Button(button_frame, text="🔄 Refresh",
                               font=('Segoe UI', 11),
                               bg='#28a745',
                               fg='white',
                               relief='flat', padx=20, pady=10,
                               command=self.refresh_scripts,
                               cursor='hand2')
        refresh_btn.pack(side='left', padx=5)
        
        scraper_btn = tk.Button(button_frame, text="🌐 Web Scraper",
                               font=('Segoe UI', 11, 'bold'),
                               bg='#e83e8c',
                               fg='white',
                               relief='flat', padx=20, pady=10,
                               command=self.open_scraper,
                               cursor='hand2')
        scraper_btn.pack(side='left', padx=5)
        
        # Populate script list
        self.update_script_list()
        
        # Focus on search
        search_entry.focus()
    
    def update_categories(self):
        """Update category list with counts"""
        # Clear existing widgets
        for widget in self.categories_frame.winfo_children():
            widget.destroy()
        
        # Count scripts by category
        categories = {}
        for path, info in self.filtered_scripts.items():
            cat = info['category']
            if cat not in categories:
                categories[cat] = 0
            categories[cat] += 1
        
        # Create "All" button
        all_btn = tk.Button(self.categories_frame,
                           text=f"All Categories\n({len(self.scripts)} scripts)",
                           font=('Segoe UI', 9, 'bold'),
                           bg='#667eea' if self.current_category == 'All' else '#f8f9ff',
                           fg='white' if self.current_category == 'All' else '#667eea',
                           relief='flat',
                           padx=10, pady=8,
                           command=lambda: self.filter_by_category('All'),
                           cursor='hand2')
        all_btn.pack(fill='x', pady=(0, 10))
        
        # Create category buttons
        for cat, count in sorted(categories.items()):
            btn = tk.Button(self.categories_frame,
                          text=f"{cat}\n({count} scripts)",
                          font=('Segoe UI', 9),
                          bg='#667eea' if self.current_category == cat else '#f8f9ff',
                          fg='white' if self.current_category == cat else '#667eea',
                          relief='flat',
                          padx=10, pady=8,
                          command=lambda c=cat: self.filter_by_category(c),
                          cursor='hand2')
            btn.pack(fill='x', pady=5)
    
    def filter_by_category(self, category):
        """Filter scripts by category"""
        self.current_category = category
        
        if category == 'All':
            self.filtered_scripts = self.scripts.copy()
        else:
            self.filtered_scripts = {
                path: info for path, info in self.scripts.items()
                if info['category'] == category
            }
        
        # Reapply search if there's a query
        query = self.search_var.get().lower()
        if query:
            self.filtered_scripts = {
                path: info for path, info in self.filtered_scripts.items()
                if query in path.lower() or query in info['name'].lower()
            }
        
        self.update_script_list()
        self.update_categories()
    
    def on_search(self, *args):
        """Handle search input"""
        query = self.search_var.get().lower()
        
        # Apply category filter first
        if self.current_category == 'All':
            base_scripts = self.scripts
        else:
            base_scripts = {
                path: info for path, info in self.scripts.items()
                if info['category'] == self.current_category
            }
        
        # Then apply search filter
        if not query:
            self.filtered_scripts = base_scripts
        else:
            self.filtered_scripts = {
                path: info for path, info in base_scripts.items()
                if query in path.lower() or query in info['name'].lower() or query in info['description'].lower()
            }
        
        self.update_script_list()
    
    def update_script_list(self):
        """Update the script treeview"""
        # Clear existing items
        for item in self.script_tree.get_children():
            self.script_tree.delete(item)
        
        # Update count label
        count = len(self.filtered_scripts)
        self.count_label.config(text=f"({count} scripts)")
        
        if count == 0:
            self.script_tree.insert('', 'end', values=('No scripts found', '', ''))
            return
        
        # Sort by path
        sorted_scripts = sorted(self.filtered_scripts.items())
        
        # Group by category
        categories = {}
        for path, info in sorted_scripts:
            cat = info['category']
            if cat not in categories:
                categories[cat] = []
            categories[cat].append((path, info))
        
        # Insert into treeview
        for cat in sorted(categories.keys()):
            parent = self.script_tree.insert('', 'end', text=cat, values=('', '', f"{len(categories[cat])} scripts"))
            for path, info in categories[cat]:
                # Add scraped indicator
                name = info['name']
                if info.get('scraped', False):
                    name = f"📥 {name}"
                
                self.script_tree.insert(parent, 'end', text='',
                                       values=(name, path, info['lines']))
    
    def on_select(self, event):
        """Handle script selection"""
        selection = self.script_tree.selection()
        if not selection:
            return
        
        item = selection[0]
        values = self.script_tree.item(item, 'values')
        
        if not values or not values[0]:
            return
        
        # Find the script info
        script_name = values[0]
        for path, info in self.filtered_scripts.items():
            if info['name'] == script_name:
                # Update details panel
                self.details_text.config(state='normal')
                self.details_text.delete('1.0', tk.END)
                details = f"📄 {info['name']}\n"
                details += f"📁 {path}\n"
                details += f"🔢 {info['lines']} lines\n"
                details += f"📋 {info['description']}"
                self.details_text.insert('1.0', details)
                self.details_text.config(state='disabled')
                break
    
    def open_script(self, event=None):
        """Open the selected script"""
        selection = self.script_tree.selection()
        if not selection:
            messagebox.showinfo("No Selection", "Please select a script first")
            return
        
        item = selection[0]
        values = self.script_tree.item(item, 'values')
        
        if not values or not values[0]:
            return
        
        # Find the script
        script_name = values[0]
        script_path = None
        for path, info in self.filtered_scripts.items():
            if info['name'] == script_name:
                script_path = info['full_path']
                break
        
        if not script_path:
            return
        
        # Open with default application
        try:
            if platform.system() == 'Windows':
                os.startfile(script_path)
            elif platform.system() == 'Darwin':  # macOS
                subprocess.run(['open', script_path])
            else:  # Linux
                subprocess.run(['xdg-open', script_path])
        except Exception as e:
            messagebox.showerror("Error", f"Could not open script:\n{e}")
    
    def browse_folder(self):
        """Open the ScriptVault folder"""
        try:
            if platform.system() == 'Windows':
                os.startfile(SCRIPT_VAULT_ROOT)
            elif platform.system() == 'Darwin':  # macOS
                subprocess.run(['open', SCRIPT_VAULT_ROOT])
            else:  # Linux
                subprocess.run(['xdg-open', SCRIPT_VAULT_ROOT])
        except Exception as e:
            messagebox.showerror("Error", f"Could not open folder:\n{e}")
    
    def refresh_scripts(self):
        """Reload all scripts from disk"""
        self.scripts.clear()
        self.current_category = 'All'
        self.search_var.set('')
        self.load_scripts()
        self.update_script_list()
        self.update_categories()
        messagebox.showinfo("Refresh Complete", f"Reloaded {len(self.scripts)} scripts")
    
    def open_scraper(self):
        """Open web scraper dialog"""
        scraper_window = tk.Toplevel(self.root)
        scraper_window.title("🌐 Web Script Scraper")
        scraper_window.geometry("600x500")
        scraper_window.configure(bg='#f0f0f0')
        
        # Info frame
        info_frame = tk.Frame(scraper_window, bg='#e83e8c', height=80)
        info_frame.pack(fill='x')
        
        title = tk.Label(info_frame, text="🌐 Web Script Scraper",
                        font=('Segoe UI', 16, 'bold'),
                        bg='#e83e8c', fg='white')
        title.pack(pady=20)
        
        # Main container
        main_frame = tk.Frame(scraper_window, bg='white', relief='groove', bd=2)
        main_frame.pack(fill='both', expand=True, padx=20, pady=20)
        
        # GitHub Token
        tk.Label(main_frame, text="GitHub Token (optional):",
                font=('Segoe UI', 10, 'bold'),
                bg='white').pack(pady=(20, 5), anchor='w', padx=20)
        token_var = tk.StringVar()
        token_entry = tk.Entry(main_frame, textvariable=token_var, font=('Segoe UI', 10), width=50)
        token_entry.pack(fill='x', padx=20)
        
        tk.Label(main_frame, text="Get token: https://github.com/settings/tokens",
                font=('Segoe UI', 8),
                bg='white', fg='#666').pack(anchor='w', padx=20, pady=5)
        
        # Query
        tk.Label(main_frame, text="Search Query:",
                font=('Segoe UI', 10, 'bold'),
                bg='white').pack(pady=(20, 5), anchor='w', padx=20)
        query_var = tk.StringVar(value="powershell")
        query_entry = tk.Entry(main_frame, textvariable=query_var, font=('Segoe UI', 10))
        query_entry.pack(fill='x', padx=20)
        
        # Count
        tk.Label(main_frame, text="Number of scripts:",
                font=('Segoe UI', 10, 'bold'),
                bg='white').pack(pady=(20, 5), anchor='w', padx=20)
        count_var = tk.IntVar(value=10)
        count_entry = tk.Entry(main_frame, textvariable=count_var, font=('Segoe UI', 10))
        count_entry.pack(fill='x', padx=20)
        
        # Status
        status_text = scrolledtext.ScrolledText(main_frame, height=8, font=('Consolas', 9))
        status_text.pack(fill='both', expand=True, padx=20, pady=20)
        
        def run_scraper():
            """Run the scraper"""
            token = token_var.get().strip()
            query = query_var.get().strip()
            count = count_var.get()
            
            if not query:
                messagebox.showwarning("Input Required", "Please enter a search query")
                return
            
            status_text.config(state='normal')
            status_text.delete('1.0', tk.END)
            status_text.insert('1.0', "🔄 Starting scraper...\n")
            scraper_window.update()
            
            try:
                # Run the PowerShell scraper
                import subprocess
                ps_script = SCRIPT_VAULT_ROOT / "utilities" / "powershell" / "web_script_scraper.ps1"
                
                cmd = ['powershell', '-ExecutionPolicy', 'Bypass', '-File', str(ps_script)]
                
                if token:
                    cmd.extend(['-GitHubToken', token])
                
                cmd.extend(['-Query', query, '-Count', str(count)])
                
                status_text.insert('end', f"📡 Query: {query}\n")
                status_text.insert('end', f"📊 Count: {count}\n")
                status_text.insert('end', "⏳ Running scraper...\n")
                scraper_window.update()
                
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
                
                status_text.insert('end', "\n✅ Scraper completed!\n")
                status_text.insert('end', "\nOutput:\n")
                status_text.insert('end', result.stdout)
                
                if result.returncode == 0:
                    messagebox.showinfo("Success", "Scraping completed! Use Refresh to see new scripts.")
                    scraper_window.after(2000, lambda: (scraper_window.destroy(), self.refresh_scripts()))
                else:
                    messagebox.showerror("Error", f"Scraper failed:\n{result.stderr}")
                    
            except Exception as e:
                status_text.insert('end', f"\n❌ Error: {str(e)}\n")
                messagebox.showerror("Error", f"Failed to run scraper:\n{e}")
            
            status_text.config(state='disabled')
        
        # Buttons
        btn_frame = tk.Frame(scraper_window, bg='#f0f0f0')
        btn_frame.pack(fill='x', padx=20, pady=20)
        
        run_btn = tk.Button(btn_frame, text="🚀 Start Scraping",
                           font=('Segoe UI', 11, 'bold'),
                           bg='#28a745', fg='white',
                           relief='flat', padx=30, pady=10,
                           command=run_scraper,
                           cursor='hand2')
        run_btn.pack(side='left')
        
        cancel_btn = tk.Button(btn_frame, text="Cancel",
                              font=('Segoe UI', 11),
                              bg='#e0e0e0',
                              relief='flat', padx=30, pady=10,
                              command=scraper_window.destroy,
                              cursor='hand2')
        cancel_btn.pack(side='left', padx=10)


def main():
    print("=" * 60)
    print("🔍 ScriptVault Navigator - Starting...")
    print("=" * 60)
    print(f"Root directory: {SCRIPT_VAULT_ROOT}")
    print("=" * 60)
    print()
    
    root = tk.Tk()
    app = ScriptVaultGUI(root)
    root.mainloop()


if __name__ == '__main__':
    main()
