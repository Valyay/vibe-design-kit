# Document Comparison Checklists

Per-document checks for Step 2 of the sync workflow.

## product-overview.md
- New roles, features, or routes not mentioned?
- Domain language changed (renamed entities, new terms)?

## entity-map.md
- New database models or types not in the map?
- Changed relationships?
- New fields that affect UI?

## screen-inventory.md
- New routes without entries?
- Deleted pages still listed?
- Changed pages need re-screenshot (mark old as outdated)

## component-graph.md
- New components not in the graph?
- Removed components still listed?
- Changed composition (moved, reparented, props changed)?

## user-flows.md
- New navigation paths?
- Changed flows (form fields added/removed, new steps)?
- Broken flows (deleted pages or components referenced)?

## visual-language.md
- New tokens added?
- Hardcoded values added or removed?
- Consistency changes (better or worse)?
- If token changes detected, suggest running `vdk-sync-tokens` for full three-way reconciliation
