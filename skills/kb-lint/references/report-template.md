# KB Lint — Report template

Copy this template into the conversation when presenting findings to the designer.

```markdown
## Knowledge Base Health Report

**Checked on:** YYYY-MM-DD
**KB last synced:** YYYY-MM-DD (from _sync-log.md)
**Code changes since sync:** N files

### Summary

| Check | OK | Issues |
|-------|-----|--------|
| Components | 12 | 3 orphans, 2 missing |
| Entities | 8 | 1 orphan |
| Screens | 6 | 0 |
| Flows | 4 | 1 stale reference |
| Visual language | — | 2 drifted tokens |
| Cross-document | — | 1 inconsistency |

### Issues

#### Components
| Issue | Name | Details | Suggested fix |
|-------|------|---------|---------------|
| Orphan | `OldCard` | Listed in component-graph.md but not found in code | Remove from KB |
| Missing | `PricingTable` | Found in src/components/ but not in KB | Add to component-graph.md |
| Stale | `Button → Icon` | Import removed in code, still in Mermaid diagram | Update diagram |

#### Entities
...

#### Cross-document
| Doc A | Doc B | Inconsistency |
|-------|-------|---------------|
| entity-map.md calls it "Project" | component-graph.md calls it "Campaign" | Align naming |
```
