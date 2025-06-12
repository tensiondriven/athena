# Force-Directed Charts in Markdown: 2025 Guide

*Research Date: 2025-06-11*

## 🎯 Quick Start (Easiest Method)

```html
<div id="graph" style="width: 600px; height: 400px;"></div>
<script src="https://cdn.jsdelivr.net/npm/force-graph"></script>
<script>
const data = {
  nodes: [
    { id: "concept1", name: "Zero-Touch" },
    { id: "concept2", name: "AIX" },
    { id: "concept3", name: "Collaboration" }
  ],
  links: [
    { source: "concept1", target: "concept2" },
    { source: "concept2", target: "concept3" }
  ]
};

ForceGraph()(document.getElementById('graph'))
  .graphData(data)
  .nodeLabel('name');
</script>
```

**Works in**: GitHub Pages, Jekyll, Hugo, any static site → **so that** you can visualize immediately

## 🏆 Top 5 Solutions Ranked by Ease

### 1. force-graph (Winner for Simplicity)
- **Setup Time**: 2 minutes
- **CDN**: `https://cdn.jsdelivr.net/npm/force-graph`
- **AIX Score**: 10/10 - Just works
- **Best For**: Quick concept maps, relationship diagrams

### 2. Vis.js Network
- **Setup Time**: 5 minutes  
- **CDN**: `https://unpkg.com/vis-network/standalone/umd/vis-network.min.js`
- **AIX Score**: 9/10 - Great docs, smooth interaction
- **Best For**: Large networks (1000+ nodes)

### 3. Mermaid.js
- **Setup Time**: 0 minutes (native in GitHub)
- **AIX Score**: 8/10 - Limited to simple layouts
- **Best For**: Documentation diagrams
```mermaid
graph TD
    A[Idea] --> B[Research]
    B --> C[Implement]
    A --> C
```

### 4. D3.js Force
- **Setup Time**: 30+ minutes
- **CDN**: `https://d3js.org/d3.v7.min.js`
- **AIX Score**: 5/10 - Powerful but complex
- **Best For**: Custom visualizations

### 5. Cytoscape.js
- **Setup Time**: 15 minutes
- **AIX Score**: 7/10 - Scientific focus
- **Best For**: Biological/scientific networks

### 6. Vega/Vega-Lite (Design Iteration Champion)
- **Setup Time**: 10 minutes
- **CDN**: `https://cdn.jsdelivr.net/npm/vega@5` + `vega-lite@5` + `vega-embed@6`
- **AIX Score**: 9/10 - Declarative, version-controlled specs
- **Best For**: Rapid iteration, design exploration
- **Key Advantage**: JSON specs can be generated/modified programmatically
```html
<div id="vis"></div>
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
<script>
const spec = {
  "$schema": "https://vega.github.io/schema/vega/v5.json",
  "width": 700, "height": 500,
  "data": [{
    "name": "node-data",
    "values": [
      {"id": 1, "name": "A"}, {"id": 2, "name": "B"}
    ]
  }],
  "forces": [
    {"force": "link", "links": "link-data"},
    {"force": "charge", "strength": -30},
    {"force": "center", "x": 350, "y": 250}
  ]
};
vegaEmbed('#vis', spec);
</script>
```

## 📦 Copy-Paste Templates

### Template 1: Concept Relationship Graph
```html
<!-- Paste this directly in your markdown -->
<div id="concepts" style="width: 100%; height: 500px;"></div>
<script src="https://cdn.jsdelivr.net/npm/force-graph"></script>
<script>
// Your glossary concepts as nodes
const concepts = {
  nodes: [
    { id: 1, name: "Zero-Touch", group: 1 },
    { id: 2, name: "Sidequest", group: 2 },
    { id: 3, name: "AIX", group: 1 },
    { id: 4, name: "Reflection Protocol", group: 2 }
  ],
  links: [
    { source: 1, target: 3, value: 2 },
    { source: 2, target: 4, value: 1 }
  ]
};

const Graph = ForceGraph()
  (document.getElementById('concepts'))
  .graphData(concepts)
  .nodeAutoColorBy('group')
  .nodeLabel('name')
  .linkDirectionalArrowLength(6);
</script>
```

### Template 2: Interactive Network (Vis.js)
```html
<div id="network" style="width: 100%; height: 500px;"></div>
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<script>
const nodes = new vis.DataSet([
  { id: 1, label: 'Node 1' },
  { id: 2, label: 'Node 2' }
]);
const edges = new vis.DataSet([
  { from: 1, to: 2 }
]);
const container = document.getElementById('network');
const data = { nodes: nodes, edges: edges };
const options = {};
const network = new vis.Network(container, data, options);
</script>
```

## 🚀 Integration by Platform

### GitHub Pages / Jekyll
1. Add to `_includes/force-graph.html`
2. Include in posts: `{% include force-graph.html %}`

### Hugo  
1. Create shortcode: `layouts/shortcodes/forcegraph.html`
2. Use in content: `{{< forcegraph >}}`

### Plain Markdown
Just paste the HTML/Script blocks directly!

## 💡 AIX Tips

1. **Start Simple**: Use force-graph with CDN first
2. **Test Locally**: Open HTML file directly in browser
3. **Data Format**: Keep nodes/links structure consistent
4. **Responsive**: Set width: 100% for mobile
5. **Fallback**: Include static image for RSS/email

## 🎨 Design Iteration Workflow

### Why Vega/Vega-Lite for Iterations
1. **Declarative JSON** → Version control your designs
2. **Programmatic generation** → Create variations easily
3. **Live reload** → See changes instantly
4. **Share specs** → Send JSON to collaborate

### Rapid Iteration Process
```javascript
// Base template for variations
const baseSpec = {
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data": {"url": "data.json"},
  // Generate variations by modifying...
};

// Option 1: Different layouts
const layouts = ['force', 'tree', 'radial', 'matrix'];

// Option 2: Different encodings  
const colorSchemes = ['category10', 'dark2', 'set3'];

// Option 3: Different interactions
const interactions = ['hover', 'click', 'drag', 'zoom'];
```

### Observable Notebooks for Prototyping
1. Create cells for each variation
2. Use sliders for real-time parameter tuning
3. Fork and modify existing examples
4. Export final spec as JSON

## 🔗 Resources

- [force-graph docs](https://github.com/vasturiano/force-graph)
- [Vis.js examples](https://visjs.github.io/vis-network/examples/)
- [Observable notebooks](https://observablehq.com/@d3/force-directed-graph) for prototyping
- [Vega force-directed examples](https://vega.github.io/vega/examples/force-directed-layout/)
- [Vega-Lite gallery](https://vega.github.io/vega-lite/examples/)

---

*Next: Create glossary visualization using force-graph*