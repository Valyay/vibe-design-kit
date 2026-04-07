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

# ── Results ──────────────────────────────────────────────────────────────────

echo ""
echo "  Results: $PASS passed, $FAIL failed"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
