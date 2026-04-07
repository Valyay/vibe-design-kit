---
name: kb-lint
description: Cross-reference knowledge base documents against the codebase to find inconsistencies, orphaned references, missing entries, and stale content. Use when sync-freshness reports drift, after major refactors, or periodically to keep the knowledge base accurate. Reports issues in a designer-readable table and offers to fix them.
---

# KB Lint Skill

Cross-reference knowledge base documents against the codebase. Find what drifted, what's missing, what's stale. Fix it — or report it so the designer knows the KB is honest.

## When to use

- `check-sync-freshness.sh` reports many changed files since last sync
- `check-kb-drift.sh` fired multiple reminders in the current session
- Designer says "is the knowledge base accurate?", "audit the docs", "clean up the vault"
- After a major refactor, migration, or component library overhaul
- Periodically (monthly) as a health check

## When NOT to use

- For simple post-task KB updates — just update the relevant doc directly
- For token sync — use `vdk-sync-tokens` instead
- For Figma comparison — use `vdk-figma-audit` instead

## Core principle

**Report first, fix second.**

Show the designer a clear summary of what's wrong. Ask before making bulk changes.
Individual corrections (renaming a component reference) can be fixed inline.
Structural changes (removing an entity, reorganizing sections) need designer approval.

---

## Step 1: Locate the knowledge base

Find the KB directory (same logic as hooks):

```bash
find "$CLAUDE_PROJECT_DIR" -path "*/design-knowledge/*/_index.md" \
  -not -path "*/_project-template/*" | head -1
```

If not found, tell the designer: "No knowledge base found. Run the onboarding skill first."

Read `_index.md` to understand the current KB scope.

## Step 2: Component graph audit

Cross-reference `component-graph.md` against the actual codebase.

**Find orphans** — components listed in KB but missing in code:

```
For each component name in component-graph.md:
  → Search codebase for the file or export
  → If not found: orphan (renamed? deleted?)
```

**Find missing** — components in code but not in KB:

```
For each component file in src/components/ (or equivalent):
  → Search component-graph.md for the component name
  → If not found: missing from KB
```

**Check relationships** — import graph vs KB dependency diagram:

```
For each "A uses B" relationship in the Mermaid diagram:
  → Verify A actually imports B in code
  → If not: stale relationship
```

## Step 3: Entity map audit

Cross-reference `entity-map.md` against types, models, and schemas.

**Find orphans** — entities in KB but not in code:

```
For each entity in entity-map.md:
  → Search for matching TypeScript type, interface, schema, or model
  → If not found: orphan
```

**Find missing** — types/models in code but not in KB:

```
For each major type (skip utility types like Props, Params):
  → Search entity-map.md for it
  → If not found and it has >3 fields: probably worth adding
```

**Check fields** — do documented fields match the actual type:

```
For each entity with documented fields:
  → Compare against the type definition
  → Flag: added fields, removed fields, type changes
```

## Step 4: Screen inventory audit

Cross-reference `screen-inventory.md` against routes and pages.

**Find orphans** — screens in KB but no matching route:

```
For each screen in screen-inventory.md:
  → Search for the route in the codebase (app/ or pages/ directory)
  → If not found: orphan
```

**Find missing** — routes in code but not in KB:

```
For each page/route file:
  → Search screen-inventory.md for the URL path
  → If not found: missing from KB
```

**Check screenshots** — are they current:

```
For each screenshot referenced in screen-inventory.md:
  → Check if the file exists in screenshots/
  → Check last modified date vs the route file's last change
  → If screenshot is older: potentially stale
```

## Step 5: User flows audit

Cross-reference `user-flows.md` against routes and interactions.

**Check flow steps** — do referenced screens still exist:

```
For each step in a flow diagram:
  → If it names a screen: verify it exists in screen-inventory.md AND code
  → If it names a component: verify it exists in component-graph.md AND code
```

**Check flow completeness** — are there obvious gaps:

```
For each route that handles user input (forms, buttons, API calls):
  → Is it part of at least one documented flow?
  → If not: potentially undocumented user flow
```

## Step 6: Visual language audit

Cross-reference `visual-language.md` against `token-audit.md` and actual code.

**Check documented tokens** — do they match reality:

```
For each token mentioned in visual-language.md:
  → Verify it exists in the token system (CSS vars, Tailwind config, etc.)
  → If value differs: drift
```

**Check descriptions** — do pattern descriptions match the code:

```
For each pattern described (e.g. "cards have 8px radius"):
  → Sample 2-3 actual components that should follow this
  → If they don't: either the pattern or the components drifted
```

## Step 7: Cross-document consistency

Check that documents agree with each other.

**Entity ↔ Component** — entities referenced by components should exist in entity-map:

```
For each component in component-graph.md that displays an entity:
  → Verify the entity appears in entity-map.md
  → Verify field names match
```

**Screen ↔ Flow** — screens in flows should exist in screen-inventory:

```
For each screen referenced in user-flows.md:
  → Verify it appears in screen-inventory.md
```

**Component ↔ Screen** — components listed on screens should exist in component-graph:

```
For each component mentioned in a screen description:
  → Verify it appears in component-graph.md
```

## Step 8: Index audit

Check that `_index.md` is consistent with the actual KB contents.

**Check completeness** — all primary docs listed:

```
For each primary doc (component-graph.md, entity-map.md, etc.):
  → Verify it appears in _index.md
  → If missing: add it
```

**Check summaries** — one-line descriptions match doc contents:

```
For each entry in _index.md:
  → Compare summary against actual doc heading/purpose
  → If summary is misleading or outdated: flag
```

**Check last-updated dates** — if _index.md includes dates:

```
For each date in _index.md:
  → Compare against _sync-log.md entries
  → If date is wrong: update
```

## Step 9: Report

Present findings (including _index.md issues from Step 8) as a structured report to the designer.

### Report format

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

### After the report

Ask the designer:

> "I found N issues across the knowledge base. Want me to:
> 1. Fix all automatically (I'll preserve your annotations)
> 2. Fix only the safe ones (orphan removal, missing additions) and flag the rest
> 3. Just save this report to `issues/kb-health-report.md` for now"

Default recommendation: option 2.

## Step 10: Fix and log

For each fix applied:
- Update the relevant KB document
- Preserve all designer annotations
- Update Mermaid diagrams to match text changes
- Update `_index.md` summaries

After all fixes, append to `_sync-log.md`:

```markdown
## YYYY-MM-DD HH:MM — kb-lint health check
- Checked: component-graph.md, entity-map.md, screen-inventory.md, user-flows.md, visual-language.md
- Fixed: N orphans removed, N missing entries added, N stale references updated
- Flagged: N issues require designer input (see issues/kb-health-report.md)
- Preserved: N designer annotations
```
