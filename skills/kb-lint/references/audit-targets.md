# KB Lint — Per-document audit targets

Apply the orphan/missing/drift pattern from Step 2 of SKILL.md to each row.

| KB document | Code source | Orphan/missing key | Drift check |
|-------------|-------------|-------------------|-------------|
| `component-graph.md` | `src/components/**/*.tsx` exports | Component name (PascalCase) | Mermaid `A uses B` vs actual imports |
| `entity-map.md` | TS types/interfaces/schemas | Type name (skip `Props`, `Params`) | Documented fields vs type definition |
| `screen-inventory.md` | `app/` or `pages/` route files | URL path | Screenshot mtime vs route file mtime |
| `user-flows.md` | Routes + screen-inventory | Screen and component names in flow steps | Routes with user input not covered by any flow |
| `visual-language.md` | CSS vars, Tailwind config, token-audit.md | Token name | Documented value vs actual value; sample 2–3 components per pattern |
