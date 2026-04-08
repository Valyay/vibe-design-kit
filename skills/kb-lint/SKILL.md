---
name: kb-lint
description: Cross-reference knowledge base documents against the codebase to find inconsistencies, orphaned references, missing entries, and stale content. Use when docs feel out of date, documentation doesn't match code, after major refactors, or periodically to keep the knowledge base accurate. Reports issues in a designer-readable table and offers to fix them.
---

# KB Lint Skill

Cross-reference knowledge base documents against the codebase. Find what drifted, what's missing, what's stale. Fix it — or report it so the designer knows the KB is honest.

## When to use

- Designer says "docs feel out of date", "documentation doesn't match code", "is the KB accurate?", "audit the docs", "clean up the vault"
- `check-kb-drift.sh` fired multiple reminders in the current session
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

## Step 2: Audit pattern (apply to all documents)

For each KB document, run three checks:

| Check | What it means | Action |
|-------|--------------|--------|
| **Orphans** | Item listed in KB but not found in code | Mark as orphan — likely renamed or deleted |
| **Missing** | Item exists in code but not in KB | Candidate to add |
| **Drift** | Item exists in both but details differ | Flag the specific fields/values that differ |

**Executable example — component orphan detection:**

```bash
KB_DOC="path/to/design-knowledge/component-graph.md"
SRC_DIR="src/components"

# Components listed in KB (PascalCase identifiers)
grep -oE '\b[A-Z][a-zA-Z]+\b' "$KB_DOC" | sort -u > /tmp/kb-components.txt

# Components exported from code
grep -rh --include="*.tsx" --include="*.jsx" \
  -E "^export (default |const |function |class )[A-Z]" "$SRC_DIR" \
  | grep -oE '\b[A-Z][a-zA-Z]+\b' | sort -u > /tmp/code-components.txt

echo "=== Orphans (in KB, not in code) ==="
comm -23 /tmp/kb-components.txt /tmp/code-components.txt

echo "=== Missing (in code, not in KB) ==="
comm -13 /tmp/kb-components.txt /tmp/code-components.txt
```

Apply the same orphan/missing/drift logic to each document below.

## Step 3: Per-document audit targets

See [`references/audit-targets.md`](references/audit-targets.md) for the full table of KB documents, code sources, and drift checks.

## Step 4: Cross-document consistency

Check that documents agree with each other:

| Pair | What to verify |
|------|---------------|
| Entity ↔ Component | For each screen that uses a data-displaying component (DataTable, List, Card with fields), check whether the entity it shows (User, Task, Project, etc.) exists in `entity-map.md`. Look at the screen's purpose and component list to infer which entity is displayed. Flag if the entity is missing or if field names referenced in screen descriptions don't match `entity-map.md`. |
| Screen ↔ Flow | Every screen named in `user-flows.md` appears in `screen-inventory.md` (and vice versa) |
| Component ↔ Screen | Every component mentioned in a screen description exists in `component-graph.md` |

## Step 5: Index audit

Check that `_index.md` is consistent with the actual KB contents:

- **Completeness** — every primary doc (`component-graph.md`, `entity-map.md`, etc.) is listed; add any missing
- **Summaries** — one-line descriptions match each doc's current heading and purpose; flag misleading ones
- **Dates** — last-updated dates match `_sync-log.md` entries; correct any that are wrong

## Step 6: Report

Present findings (including _index.md issues from Step 5) as a structured report to the designer.

Use the template from [`references/report-template.md`](references/report-template.md).

### After the report

Ask the designer:

> "I found N issues across the knowledge base. Want me to:
> 1. Fix all automatically (I'll preserve your annotations)
> 2. Fix only the safe ones (orphan removal, missing additions) and flag the rest
> 3. Just save this report to `issues/kb-health-report.md` for now"

Default recommendation: option 2.

## Step 7: Fix and log

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
