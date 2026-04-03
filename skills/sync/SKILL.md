# Sync Skill

Synchronize the knowledge base with the current state of the codebase.
Detect what changed, update stale documents, and flag conflicts with designer's annotations.

## When to use

- Periodically (start of a work session, weekly)
- After major changes by other team members (pull from main, merge)
- When the designer says "update the vault" or "something feels out of date"
- After onboarding, to keep the knowledge base alive

## What this skill does

### Step 1: Detect changes since last sync

Read the vault's `_sync-log.md` for the last sync timestamp.
Compare against git log to find what changed:

```bash
git log --since="LAST_SYNC_DATE" --name-only --pretty=format:"%h %s"
```

Categorize changes:
- **New files** — components, pages, routes added
- **Modified files** — existing UI code changed
- **Deleted files** — components or pages removed
- **Dependency changes** — package.json, lock files

### Step 2: Check each vault document against reality

For each primary vault document, compare what it says vs what the code shows now:

**product-overview.md**:
- Are there new roles, features, or routes not mentioned?
- Has the domain language changed (renamed entities, new terms)?

**entity-map.md**:
- New database models or types not in the map?
- Changed relationships?
- New fields that affect UI?

**screen-inventory.md**:
- New routes that don't have entries?
- Deleted pages still listed?
- Re-screenshot changed pages (mark old screenshots as outdated)

**component-graph.md**:
- New components not in the graph?
- Removed components still listed?
- Changed composition (component moved, reparented, props changed)?

**user-flows.md**:
- New navigation paths?
- Changed flows (form fields added/removed, new steps)?
- Broken flows (deleted pages or components referenced)?

**visual-language.md**:
- New tokens added?
- Hardcoded values added or removed?
- Consistency changes (better or worse)?
- If token changes are detected, suggest running `vdk-sync-tokens` for a full
  three-way reconciliation (Figma ↔ DESIGN.md ↔ Code)

### Step 3: Preserve designer annotations

The vault contains two types of content:
1. **Generated** — extracted from code (can be safely updated)
2. **Annotated** — written by the designer (must be preserved)

Rules:
- Lines starting with `> [Designer]` or inside `<!-- designer note -->` blocks are annotations
- Generated tables and graphs can be updated, but designer-added rows must stay
- If a generated fact conflicts with an annotation, **flag it** — don't overwrite

Example:
```markdown
## Component: HuntCard
Status: Active    ← generated, can update
Variants: v1, v2  ← generated, can update
> [Designer] v1 is legacy, do not use for new features  ← PRESERVE
```

### Step 4: Update documents

For each stale document:
1. Show the designer what changed (diff summary)
2. Update generated content
3. Preserve all annotations
4. Add new entries for new items
5. Mark removed items as `[Removed since YYYY-MM-DD]` instead of deleting

### Step 5: Update Mermaid diagrams

Mermaid diagrams in vault documents are generated content — update them when relationships change.

**entity-map.md** — update both diagrams:
- `graph LR` (relationship overview): add/remove entity nodes and edges
- `erDiagram` (ER diagram): add/remove entities, update fields and cardinality

**component-graph.md** — update the `graph TD` dependency diagram:
- Add new components to appropriate subgroups (Pages, Layout, Data Display, etc.)
- Add edges from pages to their components
- Remove deleted components
- Keep page nodes colored with `fill:#e0f2fe`

**user-flows.md** — update both levels:
- Flow map (`flowchart LR`): add/remove screens and navigation paths
- Per-flow diagrams (`flowchart TD`): update steps for changed flows, add diagrams for new flows

**Rules**:
- Only update diagrams when the underlying data changed (don't regenerate unchanged diagrams)
- Keep diagrams in sync with the text content in the same document
- If a diagram gets too large (>20 nodes), split into sub-diagrams per domain area

### Step 6: Re-capture screenshots if possible

If the app is running locally or a staging URL is available:
- Re-screenshot pages that changed
- Save new screenshots alongside old ones (don't overwrite)
- Name: `page--desktop--YYYY-MM-DD.png`

If the app is not running:
- Skip screenshots
- Note which pages need re-capturing

### Step 7: Update master index

Update `_index.md` to reflect the current state of the vault:

1. **Update summaries** — each document's one-line summary should reflect current content, not stale descriptions
2. **Update dates** — set "Last updated" to today for documents that were modified in this sync
3. **Update detail layer table** — add entries for new detail documents, remove entries for deleted ones
4. **Update quick lookup table** — cross-reference entities with their current screens, components, and flows
5. **Update annotations count** — recount designer annotations across all files
6. **Update "Last sync" date** in the header

**Why this matters**: AI reads `_index.md` first. If the index is stale, AI will read wrong documents
or miss new ones. Keep the index accurate — it's the vault's table of contents.

### Step 8: Update sync log

Write to `_sync-log.md`:
```markdown
## Sync: YYYY-MM-DD HH:MM

**Changes detected**: 12 files modified, 3 new, 1 deleted
**Documents updated**: component-graph.md, screen-inventory.md, entity-map.md
**Designer annotations preserved**: 4
**Conflicts flagged**: 1 (HuntCard status: code says deprecated, designer note says active)
**Screenshots**: 2 re-captured, 3 need manual capture
**New items added**: TaskPriority entity, PriorityBadge component, /tasks/[id]/history page

### Actions for designer
- [ ] Review conflict: HuntCard status
- [ ] Provide screenshots for: /settings/billing, /onboarding
- [ ] Update entity-map.md with TaskPriority lifecycle
```

## Output

- Updated vault documents (with preserved annotations)
- Sync log entry
- Summary for designer: what changed, what needs attention

## Example invocation

```
Sync the vault — I pulled main and there were a lot of changes.
Show me what's different and update the documentation.
```
