import requests
import json
import tkinter as tk
from tkinter import filedialog, messagebox

# ------------------------- 01 | Input File Path ----------------------------
#region  -- - - - - |  FILE PATH  | - - - - 

# URL to the raw file structure data
file_url = "https://raw.githubusercontent.com/Adam-Noble-01/RE10_I_GitHub_I_Public_Repo/main/04_Public_Python/NS02_02_01_File_Tree_Mapper/File_Mapper_Output_01_Test.txt"

#endregion

# ------------------------- 02 | File Parsing ----------------------------
#region  -- - - - - |  FILE PARSING  | - - - - 

# Function to fetch the file content from the URL
def fetch_file(url):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an error for bad HTTP status codes
        return response.text
    except requests.exceptions.RequestException as e:
        messagebox.showerror("Error", f"Failed to fetch the file: {e}")
        raise

# Function to parse the file structure based on custom hierarchy symbols (│, ├──)
def parse_file_structure(file_content):
    lines = file_content.splitlines()
    root = {"name": "root", "children": []}
    stack = [root]

    for line in lines:
        stripped_line = line.strip()
        if not stripped_line:
            continue  # Skip empty lines
        
        # Calculate the depth based on occurrences of '│' or '├──'
        depth = line.count('│') + line.count('├──')

        # Create a new node for the current file/folder
        node = {"name": stripped_line.replace("├── ", "").replace("│ ", ""), "children": []}

        # Adjust the stack based on depth
        while len(stack) > depth + 1:
            stack.pop()

        # Add as a child of the current top-level stack node
        stack[-1]["children"].append(node)
        stack.append(node)

    return root["children"][0] if root["children"] else {}

#endregion

# ------------------------- 03 | Save Dialog Handling ----------------------------
#region  -- - - - - |  SAVE FILE HANDLING  | - - - - 

# Function to display a save dialog and save the JSON content
def save_file(data):
    root = tk.Tk()
    root.withdraw()  # Hide the main tkinter window

    # Open a file dialog for saving
    file_path = filedialog.asksaveasfilename(
        defaultextension=".json",
        filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
        title="Save File"
    )
    
    if file_path:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=4)
            messagebox.showinfo("Success", f"File saved successfully at {file_path}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save the file: {e}")

#endregion

# ------------------------- 04 | JSON Structure for D3.js ----------------------------
#region  -- - - - - |  JSON GENERATION  | - - - - 

# Main function to convert the file to D3.js-compatible JSON structure
def convert_to_d3_json(url):
    # Step 1: Fetch the file
    file_content = fetch_file(url)

    # Step 2: Parse the file content into a hierarchical structure
    hierarchy = parse_file_structure(file_content)

    # Debugging: Print the parsed hierarchy
    print("Final hierarchy:", hierarchy)

    # Step 3: Show save dialog to store the JSON output
    save_file(hierarchy)

#endregion

# ------------------------- 05 | Execution ----------------------------
#region  -- - - - - |  EXECUTION  | - - - - 

if __name__ == "__main__":
    # Start the conversion process
    convert_to_d3_json(file_url)

#endregion
