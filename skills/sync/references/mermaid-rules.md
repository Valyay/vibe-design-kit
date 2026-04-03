# Mermaid Diagram Update Rules

## Which diagrams to update

| Document | Diagram type | What to update |
|----------|-------------|----------------|
| entity-map.md | `graph LR` (overview) | Add/remove entity nodes and edges |
| entity-map.md | `erDiagram` | Add/remove entities, update fields and cardinality |
| component-graph.md | `graph TD` | Add/remove components in subgroups, update edges from pages |
| user-flows.md | `flowchart LR` (map) | Add/remove screens and navigation paths |
| user-flows.md | `flowchart TD` (per-flow) | Update steps for changed flows, add diagrams for new flows |

## Rules

- Only update diagrams when the underlying data changed (don't regenerate unchanged diagrams)
- Keep diagrams in sync with the text content in the same document
- If a diagram exceeds 20 nodes, split into sub-diagrams per domain area
- Keep page nodes colored with `fill:#e0f2fe` in component-graph.md
