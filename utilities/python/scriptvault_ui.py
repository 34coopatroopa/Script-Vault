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
        self.root.geometry("1000x700")
        self.root.configure(bg='#f0f0f0')
        
        # Style configuration
        self.setup_styles()
        
        # Data
        self.scripts = {}
        self.filtered_scripts = {}
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
        for ext in ['*.ps1', '*.py']:
            for script_path in SCRIPT_VAULT_ROOT.rglob(ext):
                # Skip scraped scripts and test files
                if 'scraped_scripts' in str(script_path) or 'tests' in str(script_path):
                    continue
                
                rel_path = str(script_path.relative_to(SCRIPT_VAULT_ROOT))
                self.scripts[rel_path] = {
                    'name': script_path.name,
                    'full_path': str(script_path),
                    'category': self.get_category(rel_path)
                }
        
        self.filtered_scripts = self.scripts.copy()
    
    def get_category(self, path):
        """Determine script category"""
        if 'network' in path:
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
        
        # Script list header
        list_header = tk.Label(right_panel, text="📁 Scripts",
                              font=('Segoe UI', 14, 'bold'),
                              bg='white')
        list_header.pack(pady=20)
        
        # Listbox with scrollbar
        list_frame = tk.Frame(right_panel)
        list_frame.pack(fill='both', expand=True, padx=20, pady=(0, 20))
        
        scrollbar = ttk.Scrollbar(list_frame)
        scrollbar.pack(side='right', fill='y')
        
        self.script_listbox = tk.Listbox(list_frame, 
                                         font=('Consolas', 10),
                                         yscrollcommand=scrollbar.set,
                                         selectmode='browse',
                                         bg='white',
                                         relief='flat',
                                         activestyle='none')
        self.script_listbox.pack(side='left', fill='both', expand=True)
        scrollbar.config(command=self.script_listbox.yview)
        
        # Double-click to open
        self.script_listbox.bind('<Double-Button-1>', self.open_script)
        self.script_listbox.bind('<Return>', self.open_script)
        
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
        
        # Create category buttons
        for cat, count in sorted(categories.items()):
            btn = tk.Button(self.categories_frame,
                          text=f"{cat}\n({count} scripts)",
                          font=('Segoe UI', 9),
                          bg='#f8f9ff',
                          fg='#667eea',
                          relief='flat',
                          padx=10, pady=8,
                          command=lambda c=cat: self.filter_by_category(c),
                          cursor='hand2')
            btn.pack(fill='x', pady=5)
    
    def filter_by_category(self, category):
        """Filter scripts by category"""
        self.filtered_scripts = {
            path: info for path, info in self.scripts.items()
            if info['category'] == category
        }
        self.update_script_list()
    
    def on_search(self, *args):
        """Handle search input"""
        query = self.search_var.get().lower()
        
        if not query:
            self.filtered_scripts = self.scripts.copy()
        else:
            self.filtered_scripts = {
                path: info for path, info in self.scripts.items()
                if query in path.lower() or query in info['name'].lower()
            }
        
        self.update_script_list()
        self.update_categories()
    
    def update_script_list(self):
        """Update the script listbox"""
        self.script_listbox.delete(0, tk.END)
        
        # Sort by path
        sorted_scripts = sorted(self.filtered_scripts.items())
        
        for path, info in sorted_scripts:
            self.script_listbox.insert(tk.END, f"{info['category']:20} | {path}")
        
        # Show count
        if len(sorted_scripts) == 0:
            self.script_listbox.insert(0, "No scripts found")
    
    def open_script(self, event=None):
        """Open the selected script"""
        selection = self.script_listbox.curselection()
        if not selection:
            messagebox.showinfo("No Selection", "Please select a script first")
            return
        
        idx = selection[0]
        sorted_scripts = sorted(self.filtered_scripts.items())
        
        if idx >= len(sorted_scripts):
            return
        
        path, info = sorted_scripts[idx]
        script_path = info['full_path']
        
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
