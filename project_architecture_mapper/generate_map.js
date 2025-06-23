// Script to generate dependency graph of HTML/JS/CSS files
const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const outputFile = path.join(__dirname, 'project_map.html');

// Data containers
const nodes = [];
const edges = [];
const nodeIndex = new Map(); // map path -> index

function addNode(filePath, type) {
  if (!nodeIndex.has(filePath)) {
    const index = nodes.length;
    nodes.push({ id: index, label: filePath, type });
    nodeIndex.set(filePath, index);
  }
  return nodeIndex.get(filePath);
}

function addEdge(fromPath, toPath) {
  const from = addNode(fromPath, getType(fromPath));
  const to = addNode(toPath, getType(toPath));
  edges.push({ source: from, target: to });
}

function getType(file) {
  if (file.startsWith('http://') || file.startsWith('https://')) return 'external';
  const ext = path.extname(file).toLowerCase();
  if (ext === '.html') return 'html';
  if (ext === '.css') return 'css';
  if (ext === '.js') return 'js';
  return 'other';
}

function scanDir(dir) {
  fs.readdirSync(dir, { withFileTypes: true }).forEach(entry => {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      scanDir(fullPath);
    } else if (['.html', '.js', '.css'].includes(path.extname(entry.name).toLowerCase())) {
      parseFile(fullPath);
    }
  });
}

function parseFile(file) {
  const ext = path.extname(file).toLowerCase();
  if (ext === '.html') parseHTML(file);
  else if (ext === '.js') parseJS(file);
  else if (ext === '.css') parseCSS(file);
}

function parseHTML(file) {
  const content = fs.readFileSync(file, 'utf8');
  const dir = path.dirname(file);
  const scriptRegex = /<script[^>]*src=["']([^"']+)["']/gi;
  const linkRegex = /<link[^>]*href=["']([^"']+)["']/gi;

  let match;
  while ((match = scriptRegex.exec(content))) {
    const dep = resolvePath(dir, match[1]);
    addEdge(file, dep);
  }
  while ((match = linkRegex.exec(content))) {
    const dep = resolvePath(dir, match[1]);
    addEdge(file, dep);
  }
}

function parseJS(file) {
  const content = fs.readFileSync(file, 'utf8');
  const dir = path.dirname(file);
  const importRegex = /import\s+[^'"\n]*['"]([^'"\n]+)['"]/g;
  const requireRegex = /require\(['"]([^'"\n]+)['"]\)/g;
  let match;
  while ((match = importRegex.exec(content))) {
    const dep = resolvePath(dir, match[1]);
    addEdge(file, dep);
  }
  while ((match = requireRegex.exec(content))) {
    const dep = resolvePath(dir, match[1]);
    addEdge(file, dep);
  }
}

function parseCSS(file) {
  const content = fs.readFileSync(file, 'utf8');
  const dir = path.dirname(file);
  const importRegex = /@import\s+["']([^"']+)["']/g;
  let match;
  while ((match = importRegex.exec(content))) {
    const dep = resolvePath(dir, match[1]);
    addEdge(file, dep);
  }
}

function resolvePath(base, ref) {
  if (ref.startsWith('http://') || ref.startsWith('https://')) {
    return ref;
  }
  return path.normalize(path.join(base, ref)).replace(/\\/g, '/');
}

// Start scanning
scanDir(rootDir);

const graphData = { nodes, edges };

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>Project Architecture Map</title>
<script src="https://d3js.org/d3.v7.min.js"></script>
<style>
  html, body { margin:0; padding:0; height:100%; }
  #graph { width:100%; height:100%; }
  text { font-family: sans-serif; font-size: 10px; pointer-events: none; }
  .html { fill: #1f77b4; }
  .js { fill: #ff7f0e; }
  .css { fill: #2ca02c; }
  .external { fill: #d62728; }
  circle { stroke: #fff; stroke-width: 1.5px; }
</style>
</head>
<body>
<svg id="graph"></svg>
<script>
var graph = ${JSON.stringify(graphData)};
var width = window.innerWidth;
var height = window.innerHeight;
var svg = d3.select('#graph')
    .attr('width', width)
    .attr('height', height);

var color = function(d){
  return d.type && svg.select('style').text().includes('.' + d.type) ? null : null;
};

var simulation = d3.forceSimulation(graph.nodes)
  .force('link', d3.forceLink(graph.edges).id(d => d.id).distance(60))
  .force('charge', d3.forceManyBody().strength(-200))
  .force('center', d3.forceCenter(width / 2, height / 2));

var link = svg.append('g')
  .attr('stroke', '#999')
  .attr('stroke-opacity', 0.6)
  .selectAll('line')
  .data(graph.edges)
  .enter().append('line')
  .attr('stroke-width', 1);

var node = svg.append('g')
  .attr('stroke', '#fff')
  .attr('stroke-width', 1.5)
  .selectAll('circle')
  .data(graph.nodes)
  .enter().append('circle')
  .attr('r', 6)
  .attr('class', d => d.type)
  .call(drag(simulation));

var label = svg.append('g')
  .selectAll('text')
  .data(graph.nodes)
  .enter().append('text')
  .attr('dy', -8)
  .text(d => d.label.substring(d.label.lastIndexOf('/')+1));

simulation.on('tick', () => {
  link.attr('x1', d => d.source.x)
      .attr('y1', d => d.source.y)
      .attr('x2', d => d.target.x)
      .attr('y2', d => d.target.y);

  node.attr('cx', d => d.x)
      .attr('cy', d => d.y);

  label.attr('x', d => d.x)
       .attr('y', d => d.y);
});

function drag(simulation) {
  function dragstarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }
  function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
  }
  function dragended(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
  return d3.drag()
    .on('start', dragstarted)
    .on('drag', dragged)
    .on('end', dragended);
}
</script>
</body>
</html>`;

fs.writeFileSync(outputFile, html);
console.log('Generated', outputFile);

