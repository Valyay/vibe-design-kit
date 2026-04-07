# Output Templates

Templates for each vault document produced by the onboarding skill.

## product-overview.md

- One paragraph: what the product does, in plain language
- Who uses it (user types/roles)
- What value each user type gets
- Key terminology — domain language (e.g., "Hunt" = job listing, "Case" = candidate application)
- Business constraints (multi-tenant? subscription tiers? public/private?)
- External context section (clearly separated, sourced with `> [External source: ...]`)
- Designer context section (from Step 0 answers)

## entity-map.md

For each entity:
- Name and plain-language meaning
- Designer-relevant fields (not internal IDs/timestamps)
- Lifecycle states (draft → published → archived)
- Where it appears in UI (list, detail, card, form, mention)
- Actions users perform (create, edit, delete, assign, share)

Diagrams:
1. **Relationship overview** — `graph LR` for quick orientation
2. **ER diagram** — `erDiagram` with cardinality and key fields (designer-relevant only)

Use `||--o{` for one-to-many, `}o--||` for many-to-one, `||--||` for one-to-one.
Cross-reference each entity to screens and components.

## screen-inventory.md

For each screen:
```markdown
## /path — Screen Name

![desktop](screenshots/name--desktop.png)
![mobile](screenshots/name--mobile.png)

**Purpose**: What users do here
**Entities on screen**: Entity1, Entity2
**Components used**: ComponentA, ComponentB
**Entry points**: How users get here
**Exit points**: Where users go from here
**States captured**: populated, empty, loading
**Issues noticed**: Notable UX/UI problems
```

## component-graph.md

> Source: graphify AST analysis (import edges are exact) + manual designer metadata (entity bindings, health, status).

Start with Mermaid `graph TD` derived from graphify's import graph:
- Edges come from `graphify-cache/graph.json` — accurate, not inferred
- `subgraph` groups come from graphify's community clusters, mapped to design roles (Layout, Navigation, Data Display, Data Input, Feedback, Atoms)
- Color page nodes with `fill:#e0f2fe`

Note the graphify source at top:
```markdown
> Graph edges sourced from graphify AST analysis ([date]). Designer metadata (entity bindings, states, health) added manually.
> Re-run `graphify analyze` after major refactors to refresh structural data.
```

Then detailed composition as a tree (from graphify wiki articles if available, otherwise manual):
```
PageName (/route)
├── ComponentA
│   ├── SubComponent × N (Entity.field1, Entity.field2)
│   └── data source: GET /api/endpoint
└── ComponentB
    └── links to: OtherPage
```

For each component note: status (active/legacy/deprecated), variants, implemented states
(loading/error/empty/populated/partial), design issues.

Group by role matching graphify community clusters.

## user-flows.md

Start with flow map — `flowchart LR` showing all screens and navigation paths.
Solid arrows = primary paths, dashed = error/edge case. Color key screens.

Then per-flow documentation:
```markdown
## Flow Name

**Actor**: Role
**Goal**: What they're trying to do

1. **Screen** (/route) → action description
2. **Screen** (/route) → action description
3. **Submit** → API call → redirect

**Error path**: What happens on failure
**Empty state path**: What happens with no data
```

Flag missing flows (no delete? no 403 handling?).

## visual-language.md

### Colors in practice
- From tokens (good) — token name and swatch
- Hardcoded but consistent (fixable) — frequency and suggested token
- Inconsistent (problem) — conflicting values for same purpose

### Typography — fonts loaded, sizes used, inconsistencies
### Spacing — common gaps, consistency assessment
### Component styling — buttons, cards, forms, tables, empty states (real examples)
### Consistency report — what's good, what's broken, what's missing

Reference `token-audit.md` for raw data.
