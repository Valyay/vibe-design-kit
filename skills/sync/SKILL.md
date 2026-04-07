---
name: sync
description: Synchronize the knowledge base with the current state of the codebase. Use when the designer says "sync the vault", "update docs", "something feels out of date", or at the start of a work session after pulling changes. Detects what changed in code, updates stale vault documents, preserves designer annotations, and flags conflicts.
---

# Sync Skill

Synchronize the knowledge base with the current state of the codebase.
Detect what changed, update stale documents, and flag conflicts with designer's annotations.

## When to use

- Periodically (start of a work session, weekly)
- After major changes by other team members (pull from main, merge)
- When the designer says "update the vault" or "something feels out of date"
- After onboarding, to keep the knowledge base alive

## Step 1: Detect changes since last sync

Each primary KB document carries a `last_synced` date in its YAML frontmatter.
Read per-document staleness first — a document can be individually stale even when
the overall vault was recently synced.

```bash
# Read last_synced from a document's frontmatter
awk '/^---$/{n++; if(n==2) exit; next} n==1 && /^last_synced:/' entity-map.md \
  | sed 's/last_synced: *//'
```

Use the **oldest `last_synced`** across primary documents as the effective sync baseline.
Fall back to `_sync-log.md` only if frontmatter dates are all `null` (vault pre-dates this feature).

```bash
LAST_SYNC=$(grep -m1 '## Sync:' _sync-log.md | sed 's/## Sync: //')
git log --since="$LAST_SYNC" --name-only --pretty=format:"%h %s" -- '*.ts' '*.tsx' '*.css' '*.json'
```

Categorize: **new files**, **modified**, **deleted**, **dependency changes**.

For component/route detection, extract concrete lists:

```bash
# New/changed components
git diff --name-only "$LAST_SYNC"..HEAD -- 'src/components/**' 'app/components/**'

# New/changed routes
git diff --name-only "$LAST_SYNC"..HEAD -- 'src/app/**/page.*' 'src/pages/**' 'app/**/route.*'

# New/changed models or types
git diff --name-only "$LAST_SYNC"..HEAD -- 'prisma/schema.prisma' 'src/types/**' 'src/models/**'
```

## Step 2: Check each vault document against reality

For each document, compare its claims against the current codebase.
See `references/document-checklists.md` for per-document checks.

**Comparison approach**: read the vault document, extract its listed items (entities, components, routes, flows), then glob/grep the codebase for the actual current set. Diff the two lists:

```bash
# Example: find all current route paths
find src/app -name 'page.tsx' -o -name 'page.ts' | sed 's|src/app||;s|/page\.tsx\?||'

# Example: find all current components
find src/components -name '*.tsx' -maxdepth 2 | sed 's|.*/||;s|\.tsx||' | sort -u
```

Items in code but not in vault → **add**. Items in vault but not in code → **mark removed**.

## Step 3: Preserve designer annotations

Two types of content exist in vault documents:
1. **Generated** — extracted from code (safe to update)
2. **Annotated** — written by the designer (must be preserved)

Rules:
- Lines starting with `> [Designer]` or inside `<!-- designer note -->` blocks are annotations
- Generated tables can be updated, but designer-added rows must stay
- If a generated fact conflicts with an annotation, **flag it** — don't overwrite

## Step 4: Update documents

For each stale document:
1. Show the designer a diff summary before making changes
2. Update generated content
3. Preserve all annotations
4. Add new entries for new items
5. Mark removed items as `[Removed since YYYY-MM-DD]` instead of deleting

**Diff summary format**:
```
📋 screen-inventory.md — 3 changes detected:
  + /tasks/[id]/history — new route, needs entry
  ~ /projects — ProjectCard props changed (added `priority`)
  - /onboarding — route deleted, marking as removed
```

**After updating each document, write updated frontmatter:**

```yaml
last_synced: YYYY-MM-DD          # today's date
designer_annotations: N          # recount lines starting with "> [Designer]" or "<!-- designer note"
```

Count `designer_annotations` by scanning the updated document:
```bash
grep -cE '^\> \[Designer\]|<!-- designer note' document.md || true
```

Do not change `title`, `type`, `source_files`, or `generated_by` — those are set by onboarding.

## Step 5: Update Mermaid diagrams

Update diagrams in vault documents when relationships change.
See `references/mermaid-rules.md` for which diagrams to update and conventions.

## Step 6: Re-capture screenshots if possible

If the app is running locally or a staging URL is available:
- Re-screenshot changed pages, save as `page--desktop--YYYY-MM-DD.png`
- Don't overwrite old screenshots

If the app is not running, note which pages need re-capturing.

## Step 7: Update master index

Update `_index.md`: summaries, dates, detail layer table, quick lookup table,
annotations count, and "Last sync" date. AI reads `_index.md` first — keep it accurate.

## Step 8: Update sync log

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
