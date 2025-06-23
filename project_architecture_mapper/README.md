# Project Architecture Mapper

This tool scans the repository for HTML, CSS and JavaScript files and produces a simple dependency graph.

## Usage

1. From this directory run:
   ```sh
   node generate_map.js
   ```
   This creates `project_map.html` in the same directory.
2. Open `project_map.html` in your browser to view the graph.

Nodes are colored by file type (HTML, JS, CSS or external resource). Links show which files reference each other.
