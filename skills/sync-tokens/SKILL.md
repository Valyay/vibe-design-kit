---
name: sync-tokens
description: Reconcile design tokens across Figma Variables, DESIGN.md, and code. Use when the designer mentions token sync, token drift, pastes a Figma URL asking about tokens, or after code changes to token files (CSS variables, Tailwind config, theme). Performs a three-way diff, shows the designer what's in sync vs drifted, and asks before writing any changes.
---

# Sync Tokens Skill

Reconcile design tokens across three sources: Figma Variables, DESIGN.md, and code.
Show the designer what's in sync, what drifted, and what's missing — then ask before changing anything.

## When to use

- Designer pastes a Figma URL and says "sync tokens" or "update tokens"
- After pulling code changes that touched token files (CSS variables, Tailwind config, theme)
- Designer filled in DESIGN.md manually and wants to push tokens to code
- Periodically, to catch drift between Figma and implementation
- Designer says "check if tokens match" or "are my tokens up to date?"

## Core principle

**Always ask the designer before writing anything.**

This skill collects, compares, and reports. It proposes changes as snippets.
The designer reviews and says "do it" — only then does the skill write.

Never silently update DESIGN.md, code files, or any other artifact.

---

## Step 1: Detect and collect tokens

Check which sources are available, then collect tokens from each.
See [token-sources.md](token-sources.md) for detection rules, parsing formats, and normalization.

| Source | How to detect | What to extract |
|--------|--------------|-----------------|
| **Figma** | Figma URL in DESIGN.md + Figma MCP connected | Call `get_variable_defs`, normalize names |
| **DESIGN.md** | Parse token tables, skip placeholder comments | Token name, value, usage |
| **Code** | Scan CSS vars, Tailwind config, theme files | Token name, value, file path, line |

If a source is unavailable (no Figma URL, empty DESIGN.md, no token files), skip it and note it.

---

## Step 2: Three-way diff

Compare tokens across all available sources. Assign each token a status:

| Symbol | Status | Meaning |
|--------|--------|---------|
| `✓` | In sync | Same value in all sources |
| `≈` | Equivalent | Different format, same value (`#EF4444` = `rgba(239,68,68,1)`) |
| `⚠` | Drift | Different values between sources |
| `+` | New | Exists in one source only |
| `−` | Removed | Missing from a source where expected |

**These exact symbols are mandatory in the report — never substitute words like "OK", "match", "added", or "missing".**

See [token-sources.md](token-sources.md) for value equivalence rules (color formats, rem/px conversion, Figma rounding tolerance).

---

## Step 3: Auto-detect direction

Infer which source is authoritative from context, then suggest — never assume.

| Signal | Direction | Suggested action |
|--------|-----------|-----------------|
| Designer pasted Figma URL | Figma → Code | "Figma has N new tokens. Add to DESIGN.md and code?" |
| Designer said "pull from Figma" / "Figma has the latest" | Figma → Code | Same as above |
| Skill invoked after `git pull` or sync | Code → DESIGN.md | "Code has N tokens not in DESIGN.md. Update docs?" |
| Designer said "I updated DESIGN.md" / "use my values" | DESIGN.md → Code | "DESIGN.md has N values that differ from code. Generate updated code?" |
| No clear signal | Diff only | Show full report, ask: "Which source is correct?" |

The designer can always override: "no, take from code" / "no, Figma is right".

---

## Step 4: Present reconciliation report

Show the designer a clear report:

```
Token Reconciliation
─────────────────────────────────────────

Sources found:
  Figma:     ✓ connected (N variables in M collections)
  DESIGN.md: ✓ parsed (N tokens with values)
  Code:      ✓ scanned (N tokens in path/to/file.css)

Overview (all 5 rows always present, use 0 if none):
  ✓  15 tokens in sync
  ≈   2 tokens equivalent (format differs)
  ⚠   3 tokens drifted
  +   4 tokens new (in one source only)
  −   1 token removed

─── Drift (needs your decision) ─────────

  --color-primary
    Figma: #2563EB  DESIGN.md: #3B82F6  Code: #3B82F6
    → Figma updated? Or code/docs are correct?

─── New tokens ──────────────────────────

  Only in Figma:    --color-brand-secondary: #7C3AED
  Only in Code:     --color-surface-hover: #F3F4F6
  Only in DESIGN.md: --shadow-xl: 0 20px 25px rgba(0,0,0,0.1)

─── Format differences (no action needed) ─

  --color-error  Figma: rgba(239,68,68,1)  Code: #EF4444  → Same color ✓

─────────────────────────────────────────
Want me to log this sync to `_sync-log.md`?
```

**The `_sync-log.md` offer is a required closing line of the report — always include it, even before any changes are applied.**

---

## Step 5: Ask what to do

**Protocol: after presenting the report, send ONE question and stop. Do not add code snippets to the same message. Do not list multiple decisions. Wait for the designer's reply, then ask the next question.**

Work through issues in this order: drifted → new → removed. One token per message.

- Drifted: "**--color-primary**: Figma says #2563EB, code says #3B82F6. Which one should it be?"
- New: "Figma has `--color-brand-secondary: #7C3AED` not in code yet. Want me to add it? I'll show the snippet first."
- Removed: "Code has `--color-surface-hover` but it's gone from Figma. Keep or remove?"

After the designer answers, ask about the next token. Only show a code snippet once the designer has confirmed what to do with that specific token.

---

## Step 6: Generate code snippets (on approval)

Generate output matching the project's token system. **Show snippet, ask before writing.**

For CSS: add to the `:root` block in the project's CSS file.
For Tailwind: add to `theme.extend` in `tailwind.config.{ts,js}`.
For theme objects: add to the existing export in the theme file.
For DESIGN.md: show a diff of the table row changes.
For dark mode: generate a `.dark { }` or `[data-theme="dark"] { }` override block using only
the tokens in DESIGN.md's `### Dark mode overrides` table. Match the strategy already in code
(class-based vs. attribute-based vs. `prefers-color-scheme`) — do not introduce a new one.

Always include the target file path: "Here's the CSS to add to `src/styles/globals.css`. Want me to insert it?"

---

## Step 7: Update audit and log

After presenting the report (whether or not any changes were applied):

1. **_sync-log.md** — always offer a log entry, even if no changes were made:
   ```
   ## Token sync: YYYY-MM-DD HH:MM
   Sources: Figma (18 vars), Code (21 tokens), DESIGN.md (24 tokens)
   Added: 2 from Figma, Resolved: 1 drift, Skipped: 1 code-only kept
   ```
   Ask: "Want me to log this sync to `_sync-log.md`?"

2. **token-audit.md** — if changes were applied, offer to update token counts:
   "Want me to update token-audit.md? (Tokenized: 85% → 89%)"

---

## Edge cases

See [edge-cases.md](edge-cases.md) for handling:
- Figma not connected
- DESIGN.md empty (all placeholders)
- No token system in code (all hardcoded)
- Multiple token files
- Dark mode / multiple Figma modes
- Token naming mismatches between Figma and code

---

## Example invocations

**Figma-first**: "Here's our Figma file: https://figma.com/design/ABC123/MyProject — sync the tokens, Figma has the latest colors."

**Code-first**: "We just merged a big PR that changed a lot of colors. Check if DESIGN.md still matches."

**DESIGN.md-first**: "I updated DESIGN.md with new spacing values. Generate the CSS variables for me."

**Just check**: "Are my tokens in sync? Check Figma, DESIGN.md, and the code."
