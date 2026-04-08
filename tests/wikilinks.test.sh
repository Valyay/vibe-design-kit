#!/usr/bin/env bash
# Tests for check-wikilinks.sh — wiki-link validation in KB vault
# Run: bash tests/wikilinks.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
HOOK="$ROOT/hooks/check-wikilinks.sh"

PASS=0
FAIL=0

ok() { echo "  ✓  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

# ── Setup temp vault ───────────────────────────────────────────────────────

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/design-knowledge/vault"

# ── T1: Valid wiki-link to existing file → no output, exit 0 ──────────────

echo ""
echo "T1: Valid wiki-link produces no output and exits 0"

cat > "$TEST_DIR/design-knowledge/vault/entity-map.md" << 'EOF'
# Entity Map
Some content here.
EOF

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[entity-map]] for entities.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "Valid wiki-link: silent exit 0"
else
  fail "Valid wiki-link: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T2: Broken wiki-link → reports error, exit 1 ──────────────────────────

echo ""
echo "T2: Broken wiki-link reports error and exits 1"

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[nonexistent-doc]] for details.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 1 ]] && echo "$OUTPUT" | grep -q "nonexistent-doc"; then
  ok "Broken wiki-link: exit 1 with error message"
else
  fail "Broken wiki-link: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T3: Anchor link resolves file and heading ──────────────────────────────

echo ""
echo "T3: Anchor link [[entity-map#organization]] resolves entity-map.md"

# Recreate entity-map.md with the required heading (self-contained, no T1 dependency)
cat > "$TEST_DIR/design-knowledge/vault/entity-map.md" << 'EOF'
# Entity Map

## organization
Details here.
EOF

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[entity-map#organization]] for the Organization entity.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "Anchor link to existing file: silent exit 0"
else
  fail "Anchor link: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T4: Nested path resolves from vault root ───────────────────────────────

echo ""
echo "T4: Nested path [[baseline/quality-snapshot]] resolves correctly"

mkdir -p "$TEST_DIR/design-knowledge/vault/baseline"
echo "# Quality" > "$TEST_DIR/design-knowledge/vault/baseline/quality-snapshot.md"

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[baseline/quality-snapshot]] for quality metrics.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "Nested path: silent exit 0"
else
  fail "Nested path: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T5: No wiki-links → silent exit 0 ─────────────────────────────────────

echo ""
echo "T5: File without wiki-links passes silently"

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
Just plain text, no wiki-links here.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "No wiki-links: silent exit 0"
else
  fail "No wiki-links: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T6: Multiple broken links → reports all ────────────────────────────────

echo ""
echo "T6: Multiple broken links are all reported"

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[ghost-doc]] and [[phantom-page]] and [[entity-map]] for info.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 1 ]] \
  && echo "$OUTPUT" | grep -q "ghost-doc" \
  && echo "$OUTPUT" | grep -q "phantom-page" \
  && ! echo "$OUTPUT" | grep -q "entity-map"; then
  ok "Reports both broken links, not the valid one"
else
  fail "Multiple broken: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T7: Wiki-links inside HTML comments are skipped ────────────────────────

echo ""
echo "T7: Wiki-links inside HTML comments are skipped"

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[entity-map]] for entities.
<!-- [[nonexistent-placeholder]] is just a template example -->
| <!-- [[another/placeholder]] --> | <!-- example --> |
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" "$TEST_DIR/design-knowledge/vault" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "Commented wiki-links are skipped"
else
  fail "Commented wiki-links: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T8: hook file is executable ──────────────────────────────────��─────────

echo ""
echo "T8: hook file is executable"

if [[ -x "$HOOK" ]]; then
  ok "check-wikilinks.sh is executable"
else
  fail "check-wikilinks.sh is not executable"
fi

# ── T9: settings.json includes session-report (unified SessionStart hook) ──
# check-wikilinks.sh is a CLI utility (used by vdk-kb-lint); wiki-link
# validation in hook mode now runs inside session-report.sh.

echo ""
echo "T9: settings.json includes session-report.sh (wiki-links covered inside)"

if grep -q "session-report.sh" "$ROOT/templates/settings.json"; then
  ok "session-report.sh registered in settings.json (covers wiki-link validation)"
else
  fail "session-report.sh missing from settings.json"
fi

# ── T10: CLAUDE.md documents wiki-link validation ──────────────────────────

echo ""
echo "T10: templates/CLAUDE.md documents wiki-link validation"

if grep -qiE "wiki.link|KB link validation" "$ROOT/templates/CLAUDE.md"; then
  ok "Wiki-link validation documented in CLAUDE.md"
else
  fail "Wiki-link validation missing from CLAUDE.md"
fi

# ── T11: templates use wiki-links, not markdown file links ─────────────────

echo ""
echo "T11: _index.md uses wiki-links instead of markdown file links"

if grep -q '\[\[product-overview\]\]' "$ROOT/knowledge-base/_project-template/_index.md" \
  && ! grep -q '\[product-overview.md\](product-overview.md)' "$ROOT/knowledge-base/_project-template/_index.md"; then
  ok "_index.md uses wiki-link syntax"
else
  fail "_index.md still has markdown file links"
fi

# ── T12: templates pass wiki-link validation ───────────────────────────────

echo ""
echo "T12: All KB templates pass wiki-link validation"

OUTPUT=$(bash "$HOOK" "$ROOT/knowledge-base/_project-template" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
  ok "Templates pass wiki-link validation"
else
  fail "Templates have broken wiki-links: $OUTPUT"
fi

# ── Results ────────────────────────���───────────────────────────────────────

echo ""
echo "  Results: $PASS passed, $FAIL failed"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
