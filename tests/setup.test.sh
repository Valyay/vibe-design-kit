#!/usr/bin/env bash
# Tests for setup.sh and documentation completeness.
# Run: bash tests/setup.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

PASS=0
FAIL=0

ok() { echo "  ✓  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

# ── T1: skill source files exist for setup.sh to copy ───────────────────────
# setup.sh copies everything under skills/*/ via a glob.
# This test guards against accidental deletion of those source files.

echo ""
echo "T1: skill source files present (setup.sh copies via glob)"

for skill in figma-audit visual-diff; do
  if [[ -f "$ROOT/skills/$skill/SKILL.md" ]]; then
    ok "skills/$skill/SKILL.md exists"
  else
    fail "skills/$skill/SKILL.md is MISSING — setup.sh glob will skip it"
  fi
done

# ── T2: recommended-tools.md mentions figma-audit in custom-skills section ──

echo ""
echo "T2: recommended-tools.md — figma-audit in 'What we keep custom' section"

RECDOC="$ROOT/recommended-tools.md"
CUSTOM_SECTION="$(awk '/^## What we keep custom/,0' "$RECDOC")"

if echo "$CUSTOM_SECTION" | grep -q "figma-audit"; then
  ok "figma-audit in '## What we keep custom'"
else
  fail "figma-audit MISSING from '## What we keep custom'"
fi

# ── T3: recommended-tools.md mentions visual-diff in custom-skills section ──

echo ""
echo "T3: recommended-tools.md — visual-diff in 'What we keep custom' section"

if echo "$CUSTOM_SECTION" | grep -q "visual-diff"; then
  ok "visual-diff in '## What we keep custom'"
else
  fail "visual-diff MISSING from '## What we keep custom'"
fi

# ── T4: templates/CLAUDE.md triggers vdk-figma-audit ────────────────────────

echo ""
echo "T4: templates/CLAUDE.md has auto-trigger for vdk-figma-audit"

CLAUDE_TPL="$ROOT/templates/CLAUDE.md"

if grep -q "vdk-figma-audit" "$CLAUDE_TPL"; then
  ok "vdk-figma-audit trigger present in templates/CLAUDE.md"
else
  fail "vdk-figma-audit trigger MISSING from templates/CLAUDE.md — designer won't be auto-prompted"
fi

# ── T5: templates/CLAUDE.md triggers vdk-visual-diff ────────────────────────

echo ""
echo "T5: templates/CLAUDE.md has auto-trigger for vdk-visual-diff"

if grep -q "vdk-visual-diff" "$CLAUDE_TPL"; then
  ok "vdk-visual-diff trigger present in templates/CLAUDE.md"
else
  fail "vdk-visual-diff trigger MISSING from templates/CLAUDE.md — designer won't be auto-prompted"
fi

# ── T6: onboarding SKILL.md references root recommended-tools.md ─────────────
# The local references/ copy was renamed to tool-detection.md.
# SKILL.md must point to ../../recommended-tools.md (single source of truth)
# so the tool catalog can never silently diverge.

echo ""
echo "T6: onboarding SKILL.md references root recommended-tools.md"

ONBOARD_SKILL="$ROOT/skills/onboarding/SKILL.md"

if grep -q "\.\./\.\./recommended-tools\.md" "$ONBOARD_SKILL"; then
  ok "SKILL.md references ../../recommended-tools.md (root catalog)"
else
  fail "SKILL.md does NOT reference ../../recommended-tools.md — update Step 10"
fi

if [[ ! -f "$ROOT/skills/onboarding/references/recommended-tools.md" ]]; then
  ok "references/recommended-tools.md removed (no stale copy)"
else
  fail "references/recommended-tools.md still exists — rename to tool-detection.md"
fi

# ── T7: templates/CLAUDE.md has AI visual anti-patterns section ────────────

echo ""
echo "T7: templates/CLAUDE.md has AI visual anti-patterns section"

if grep -q "AI visual anti-patterns" "$CLAUDE_TPL"; then
  ok "AI visual anti-patterns section exists"
else
  fail "AI visual anti-patterns section MISSING — AI slop rules not enforced"
fi

# ── T8: anti-patterns section lists specific banned patterns ───────────────

echo ""
echo "T8: anti-patterns section names concrete banned patterns"

SLOP_SECTION="$(awk '/^## AI visual anti-patterns/{found=1; next} found && /^## /{exit} found' "$CLAUDE_TPL")"

for pattern in "gradient" "glassmorphism" "shadow" "glow" "animation" "hero"; do
  if echo "$SLOP_SECTION" | grep -qi "$pattern"; then
    ok "Mentions banned pattern: $pattern"
  else
    fail "Missing banned pattern: $pattern"
  fi
done

# ── T9: anti-patterns section provides alternatives ────────────────────────

echo ""
echo "T9: anti-patterns section provides actionable alternatives"

if echo "$SLOP_SECTION" | grep -qi "instead"; then
  ok "Section includes 'instead' guidance (actionable alternatives)"
else
  fail "Section has no 'instead' guidance — rules are not actionable"
fi

# ── T10: self-review step references anti-patterns ─────────────────────────

echo ""
echo "T10: self-review checklist references AI anti-patterns"

REVIEW_SECTION="$(awk '/^### 5\. Self-review/{found=1} found && /^### 6/{exit} found' "$CLAUDE_TPL")"
if echo "$REVIEW_SECTION" | grep -qi "anti-pattern\|AI visual\|slop"; then
  ok "Self-review references AI visual anti-patterns"
else
  fail "Self-review does NOT reference AI anti-patterns — rules won't be enforced"
fi

# ── T11: design-review.md has structured output format ────────────────────

echo ""
echo "T11: design-review.md has structured output format section"

REVIEW_PROMPT="$ROOT/prompts/design-review.md"

if grep -q "^## Output format" "$REVIEW_PROMPT"; then
  ok "design-review.md has '## Output format' section"
else
  fail "design-review.md MISSING '## Output format' — feedback structure is undefined"
fi

# ── T12: output format includes all required fields ──────────────────────

echo ""
echo "T12: design-review.md output format includes all required fields"

OUTPUT_SECTION="$(awk '/^## Output format/,0' "$REVIEW_PROMPT")"

for field in Severity Category Expected Actual File Fix; do
  if echo "$OUTPUT_SECTION" | grep -q "\*\*$field\*\*"; then
    ok "Output format includes field: $field"
  else
    fail "Output format MISSING field: $field"
  fi
done

# ── T13: categories cover design domains ─────────────────────────────────

echo ""
echo "T13: design-review.md categories cover design domains"

for category in Color Typography Spacing Layout A11y State Responsive; do
  if echo "$OUTPUT_SECTION" | grep -q "$category"; then
    ok "Category listed: $category"
  else
    fail "Category MISSING: $category"
  fi
done

# ── T14: KB primary document templates have YAML frontmatter ─────────────────
# LLM Wiki pattern: every wiki page carries machine-readable metadata so AI
# can determine freshness, type, and source files without parsing the body.

echo ""
echo "T14: KB primary document templates have YAML frontmatter"

KB_PRIMARY_DOCS="entity-map component-graph screen-inventory user-flows visual-language product-overview"

for doc in $KB_PRIMARY_DOCS; do
  TEMPLATE="$ROOT/knowledge-base/_project-template/$doc.md"
  if [[ ! -f "$TEMPLATE" ]]; then
    fail "$doc.md not found"
    continue
  fi
  if head -1 "$TEMPLATE" | grep -q "^---$"; then
    ok "$doc.md has YAML frontmatter"
  else
    fail "$doc.md missing YAML frontmatter (must start with ---)"
  fi
done

# ── T15: frontmatter includes all required fields ─────────────────────────────

echo ""
echo "T15: KB document frontmatter includes required LLM Wiki fields"

REQUIRED_FIELDS="title type last_synced source_files generated_by designer_annotations"

for doc in $KB_PRIMARY_DOCS; do
  TEMPLATE="$ROOT/knowledge-base/_project-template/$doc.md"
  [[ -f "$TEMPLATE" ]] || continue
  # Extract frontmatter block (between first and second ---)
  FRONTMATTER=$(awk '/^---$/{n++; if(n==2) exit; next} n==1' "$TEMPLATE")
  for field in $REQUIRED_FIELDS; do
    if echo "$FRONTMATTER" | grep -q "^${field}:"; then
      ok "$doc.md frontmatter has field: $field"
    else
      fail "$doc.md frontmatter MISSING field: $field"
    fi
  done
done

# ── T16: type field uses allowed values ───────────────────────────────────────

echo ""
echo "T16: KB document frontmatter type field matches the document filename"

for doc in $KB_PRIMARY_DOCS; do
  TEMPLATE="$ROOT/knowledge-base/_project-template/$doc.md"
  [[ -f "$TEMPLATE" ]] || continue
  FRONTMATTER=$(awk '/^---$/{n++; if(n==2) exit; next} n==1' "$TEMPLATE")
  TYPE_VAL=$(echo "$FRONTMATTER" | grep "^type:" | sed 's/type: *//')
  if [[ "$TYPE_VAL" == "$doc" ]]; then
    ok "$doc.md type: $TYPE_VAL (matches filename)"
  else
    fail "$doc.md type: '$TYPE_VAL' does not match expected '$doc'"
  fi
done

# ── T17-T20: onboarding skill writes real frontmatter values ──────────────────
# Cycle 2: templates have frontmatter schema, now onboarding must populate it.
# AI writes last_synced, source_files, generated_by after generating each doc.

ONBOARD="$ROOT/skills/onboarding/SKILL.md"

echo ""
echo "T17: onboarding skill instructs AI to write last_synced"

if grep -q "last_synced" "$ONBOARD"; then
  ok "onboarding mentions last_synced"
else
  fail "onboarding does NOT mention last_synced — frontmatter date will stay null"
fi

echo ""
echo "T18: onboarding skill instructs AI to write source_files per document"

if grep -q "source_files" "$ONBOARD"; then
  ok "onboarding mentions source_files"
else
  fail "onboarding does NOT mention source_files — AI won't know which code files each doc describes"
fi

echo ""
echo "T19: onboarding skill sets generated_by: onboarding"

if grep -q "generated_by" "$ONBOARD"; then
  ok "onboarding mentions generated_by"
else
  fail "onboarding does NOT set generated_by — sync skill can't tell who last wrote the doc"
fi

echo ""
echo "T20: onboarding skill maps each document type to its source files"

# Check that the source_files table covers each primary document type
# and names concrete file patterns nearby — bash 3.2 compatible (no declare -A)
check_doc_mapping() {
  local doc="$1" pattern="$2"
  # Find the table row for this doc, then check it mentions expected source file patterns
  if grep -E "${doc}\.md" "$ONBOARD" | grep -qE "$pattern"; then
    ok "onboarding maps $doc to its source file patterns"
  else
    fail "onboarding does NOT map $doc to source file patterns — source_files will be generic"
  fi
}

check_doc_mapping "entity-map"       "schema|types|models"
check_doc_mapping "component-graph"  "components"
check_doc_mapping "screen-inventory" "page|route"
check_doc_mapping "visual-language"  "css|tailwind|theme"

# ── T21-T24: sync reads and writes frontmatter ────────────────────────────────
# Cycle 3: sync skill uses last_synced from frontmatter (per-document staleness)
# and check-sync-freshness.sh reads frontmatter directly for precise reporting.

SYNC_SKILL="$ROOT/skills/sync/SKILL.md"
FRESHNESS_HOOK="$ROOT/hooks/check-sync-freshness.sh"

echo ""
echo "T21: sync skill reads last_synced from frontmatter to detect per-document staleness"

if grep -q "last_synced" "$SYNC_SKILL"; then
  ok "sync skill mentions last_synced"
else
  fail "sync skill does NOT mention last_synced — staleness detection is coarse (one date for all docs)"
fi

echo ""
echo "T22: sync skill writes updated last_synced after syncing each document"

if grep -q "last_synced" "$SYNC_SKILL" && grep -qE "updat|writ" "$SYNC_SKILL"; then
  ok "sync skill mentions updating last_synced"
else
  fail "sync skill does NOT instruct updating last_synced — frontmatter will go stale"
fi

echo ""
echo "T23: sync skill updates designer_annotations count after each sync"

if grep -q "designer_annotations" "$SYNC_SKILL"; then
  ok "sync skill mentions designer_annotations"
else
  fail "sync skill does NOT update designer_annotations — count will be wrong after designer edits"
fi

echo ""
echo "T24: check-sync-freshness.sh reads last_synced from document frontmatter"

if grep -q "last_synced" "$FRESHNESS_HOOK"; then
  ok "check-sync-freshness.sh reads last_synced from frontmatter"
else
  fail "check-sync-freshness.sh does NOT read last_synced from frontmatter — can't report per-document staleness"
fi

# ── T25-T28: obsidian-skills replaces custom Obsidian formatting ──────────────
# kepano/obsidian-skills teaches AI all Obsidian formats (callouts, embeds,
# wikilinks, properties). VDK used to hand-roll these; now we delegate.

echo ""
echo "T25: setup.sh installs obsidian-flavored-markdown skill"

if grep -q "obsidian-flavored-markdown" "$ROOT/setup.sh"; then
  ok "setup.sh installs obsidian-flavored-markdown"
else
  fail "setup.sh does NOT install obsidian-flavored-markdown — Obsidian format skill missing"
fi

if grep -q "obsidian-flavored-markdown" "$ROOT/recommended-tools.md"; then
  ok "recommended-tools.md documents obsidian-flavored-markdown"
else
  fail "recommended-tools.md does not mention obsidian-flavored-markdown — not discoverable by designer"
fi

echo ""
echo "T26: knowledge-base/CLAUDE.md references obsidian-flavored-markdown skill"
# AI needs explicit instruction to use the skill when writing vault docs —
# otherwise it falls back to its own (incorrect) formatting conventions.

KB_CLAUDE="$ROOT/knowledge-base/CLAUDE.md"

if grep -q "obsidian-flavored-markdown" "$KB_CLAUDE"; then
  ok "knowledge-base/CLAUDE.md references obsidian-flavored-markdown skill"
else
  fail "knowledge-base/CLAUDE.md does NOT reference obsidian-flavored-markdown — AI won't use correct Obsidian format"
fi

echo ""
echo "T27: knowledge-base/CLAUDE.md uses Obsidian callout format for designer annotations"
# obsidian-flavored-markdown uses > [!type] callouts, not > [Designer] blockquotes.
# The annotation format in KB CLAUDE.md must match what the skill teaches.

if grep -q '> \[!designer\]' "$KB_CLAUDE"; then
  ok "KB CLAUDE.md uses > [!designer] callout format"
else
  fail "KB CLAUDE.md uses old > [Designer] format — not Obsidian-native callout syntax"
fi

echo ""
echo "T28: screen-inventory template uses Obsidian embed syntax for screenshots"
# Obsidian embeds (![[file]]) appear in the vault's link graph and backlinks panel.
# Standard markdown images (![alt](path)) are opaque to Obsidian — the screenshot
# is not connected to anything in the vault.

SCREEN_INV="$ROOT/knowledge-base/_project-template/screen-inventory.md"

if grep -q '!\[\[' "$SCREEN_INV"; then
  ok "screen-inventory.md uses Obsidian embed syntax ![[...]]"
else
  fail "screen-inventory.md uses plain markdown images — screenshots not visible in Obsidian link graph"
fi

# ── Results ──────────────────────────────────────────────────────────────────

echo ""
echo "  Results: $PASS passed, $FAIL failed"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
