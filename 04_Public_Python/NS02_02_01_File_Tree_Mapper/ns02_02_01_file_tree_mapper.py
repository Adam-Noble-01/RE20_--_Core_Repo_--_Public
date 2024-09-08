import os
import tkinter as tk
from tkinter import filedialog
import subprocess

def select_directory():
    root = tk.Tk()
    root.withdraw()
    return filedialog.askdirectory(title="Select Parent Directory")

def generate_tree(startpath):
    tree = []
    for root, dirs, files in os.walk(startpath):
        level = root.replace(startpath, '').count(os.sep)
        indent = '│   ' * (level - 1) + '├── ' if level > 0 else ''
        tree.append(f'{indent}{os.path.basename(root)}/')
        for f in files:
            tree.append(f'{indent}│   ├── {f}')
    return '\n'.join(tree)

def save_tree(tree):
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.asksaveasfilename(
        defaultextension=".txt",
        filetypes=[("Text files", "*.txt")],
        title="Save Tree File"
    )
    if file_path:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(tree)
        return file_path
    return None

def open_file(file_path):
    if tk.messagebox.askyesno("Open File", "Do you want to open the generated file?"):
        subprocess.Popen(['start', '', file_path], shell=True)

def main():
    # Select parent directory
    parent_dir = select_directory()
    if not parent_dir:
        print("No directory selected. Exiting.")
        return

    # Generate tree
    tree = generate_tree(parent_dir)

    # Save tree
    saved_file = save_tree(tree)
    if saved_file:
        print(f"File saved successfully to: {saved_file}")
        open_file(saved_file)
    else:
        print("File not saved.")

if __name__ == "__main__":
    main()
