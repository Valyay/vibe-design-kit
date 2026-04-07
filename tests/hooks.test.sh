#!/usr/bin/env bash
# Tests for VDK hooks: check-kb-drift.sh and check-sync-freshness.sh
# Run: bash tests/hooks.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

PASS=0
FAIL=0

ok() { echo "  ✓  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

# ── Setup temp project ──────────────────────────────────────────────────────

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Create a minimal project structure
mkdir -p "$TEST_DIR/design-knowledge/vault"
mkdir -p "$TEST_DIR/src/components"

# Create KB files
cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[component-graph]] for components.
See [[entity-map]] for entities.
See [[nonexistent-doc]] for nothing.
EOF

cat > "$TEST_DIR/design-knowledge/vault/component-graph.md" << 'EOF'
# Component Graph
- Button (src/components/Button.tsx)
- Card (src/components/Card.tsx)
See also [[entity-map#User]] for entity details.
See also [[entity-map#Deleted]] for removed stuff.
EOF

cat > "$TEST_DIR/design-knowledge/vault/entity-map.md" << 'EOF'
# Entity Map

## User
- name: string
- email: string

## Project
- title: string
EOF

# Create component files
echo "export function Button() {}" > "$TEST_DIR/src/components/Button.tsx"
echo "export function Card() {}" > "$TEST_DIR/src/components/Card.tsx"

# Create sync log
cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << EOF
## $(date +%Y-%m-%d) 10:00 — sync skill
- Synced all documents
EOF

# ── T1: check-kb-drift.sh — detects referenced file ────────────────────────

echo ""
echo "T1: check-kb-drift detects when edited file is referenced in KB"

# Clean drift log
DRIFT_LOG="/tmp/vdk-kb-drift-$(printf '%s' "$TEST_DIR" | tr '/' '_').log"
rm -f "$DRIFT_LOG"

OUTPUT=$(echo '{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx","new_string":"updated"}}' \
  | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-kb-drift.sh" 2>&1 || true)

if echo "$OUTPUT" | grep -q "Button.*referenced"; then
  ok "Detected Button.tsx reference in KB"
else
  fail "Did not detect Button.tsx reference. Output: $OUTPUT"
fi

# ── T2: check-kb-drift.sh — ignores unreferenced file ──────────────────────

echo ""
echo "T2: check-kb-drift ignores files not referenced in KB"

OUTPUT=$(echo '{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/NewThing.tsx","new_string":"new"}}' \
  | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-kb-drift.sh" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "No output for unreferenced file"
else
  fail "Unexpected output for unreferenced file: $OUTPUT"
fi

# ── T3: check-kb-drift.sh — deduplicates reminders ─────────────────────────

echo ""
echo "T3: check-kb-drift deduplicates reminders for same file"

# Button.tsx was already reminded in T1, should be silent now
OUTPUT=$(echo '{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx","new_string":"again"}}' \
  | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-kb-drift.sh" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "Second edit to Button.tsx is silent (deduplicated)"
else
  fail "Second edit produced output: $OUTPUT"
fi

# ── T4: check-kb-drift.sh — skips test files ───────────────────────────────

echo ""
echo "T4: check-kb-drift skips test files"

OUTPUT=$(echo '{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.test.tsx","new_string":"test"}}' \
  | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-kb-drift.sh" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "Test file is skipped"
else
  fail "Test file produced output: $OUTPUT"
fi

# ── T5: check-kb-drift.sh — skips generic names ────────────────────────────

echo ""
echo "T5: check-kb-drift skips generic filenames (index, utils, etc.)"

OUTPUT=$(echo '{"tool_input":{"file_path":"'"$TEST_DIR"'/src/index.ts","new_string":"export"}}' \
  | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-kb-drift.sh" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "Generic filename index.ts is skipped"
else
  fail "Generic filename produced output: $OUTPUT"
fi

# ── T6: check-kb-drift.sh — skips KB files ─────────────────────────────────

echo ""
echo "T6: check-kb-drift skips edits to KB files themselves"

OUTPUT=$(echo '{"tool_input":{"file_path":"'"$TEST_DIR"'/design-knowledge/vault/component-graph.md","new_string":"updated"}}' \
  | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-kb-drift.sh" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "KB file edit is skipped"
else
  fail "KB file edit produced output: $OUTPUT"
fi

# ── T7: check-sync-freshness.sh — detects stale + changed files ────────────

echo ""
echo "T7: check-sync-freshness reports changed file count when stale"

# Make sync log old (15 days ago)
if date -j -v-15d "+%Y-%m-%d" &>/dev/null; then
  OLD_DATE=$(date -j -v-15d "+%Y-%m-%d")
else
  OLD_DATE=$(date -d "15 days ago" "+%Y-%m-%d")
fi

cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << EOF
## ${OLD_DATE} 10:00 — sync skill
- Synced all documents
EOF

# Init a git repo so the git log part works
(cd "$TEST_DIR" && git init -q && git add -A && git commit -q -m "init" \
  && echo "change" > src/components/Button.tsx \
  && echo "change" > src/components/Card.tsx \
  && git add -A && git commit -q -m "update components") 2>/dev/null

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-sync-freshness.sh" 2>&1 || true)

if echo "$OUTPUT" | grep -qE "[0-9]+ code file"; then
  ok "Reports changed file count alongside date staleness"
else
  fail "No file count in output: $OUTPUT"
fi

# ── T8: check-sync-freshness.sh — quiet when fresh ─────────────────────────

echo ""
echo "T8: check-sync-freshness is quiet when recently synced and few changes"

cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << EOF
## $(date +%Y-%m-%d) 10:00 — sync skill
- Synced all documents
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-sync-freshness.sh" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "No output when freshly synced"
else
  fail "Unexpected output when fresh: $OUTPUT"
fi

# ── T9: hook files are executable ───────────────────────────────────────────

echo ""
echo "T9: hook files are executable"

if [[ -x "$ROOT/hooks/check-kb-drift.sh" ]]; then
  ok "check-kb-drift.sh is executable"
else
  fail "check-kb-drift.sh is not executable"
fi

# ── T10: settings.json includes check-kb-drift hook ─────────────────────────

echo ""
echo "T10: settings.json includes check-kb-drift hook"

if grep -q "check-kb-drift.sh" "$ROOT/templates/settings.json"; then
  ok "check-kb-drift.sh registered in settings.json"
else
  fail "check-kb-drift.sh missing from settings.json"
fi

# ── T11: CLAUDE.md documents KB drift hook ──────────────────────────────────

echo ""
echo "T11: templates/CLAUDE.md documents KB drift hook"

if grep -q "KB drift" "$ROOT/templates/CLAUDE.md"; then
  ok "KB drift hook documented in CLAUDE.md"
else
  fail "KB drift hook missing from CLAUDE.md"
fi

# ── T12: CLAUDE.md has vdk-kb-lint skill trigger ────────────────────────────

echo ""
echo "T12: templates/CLAUDE.md has auto-trigger for vdk-kb-lint"

if grep -q "vdk-kb-lint" "$ROOT/templates/CLAUDE.md"; then
  ok "vdk-kb-lint trigger present in templates/CLAUDE.md"
else
  fail "vdk-kb-lint trigger missing from templates/CLAUDE.md"
fi

# ── T13: kb-lint skill file exists ──────────────────────────────────────────

echo ""
echo "T13: kb-lint skill file exists"

if [[ -f "$ROOT/skills/kb-lint/SKILL.md" ]]; then
  ok "skills/kb-lint/SKILL.md exists"
else
  fail "skills/kb-lint/SKILL.md is missing"
fi

# ── T14: check-wikilinks.sh — detects broken [[...]] link ─────────────────

echo ""
echo "T14: check-wikilinks detects broken [[nonexistent-doc]] link"

# Add a broken wiki-link to a vault file
cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[nonexistent-doc]] for details.
EOF

OUTPUT=$(bash "$ROOT/hooks/check-wikilinks.sh" "$TEST_DIR/design-knowledge/vault" 2>&1 || true)

if echo "$OUTPUT" | grep -q "nonexistent-doc"; then
  ok "Detected broken wiki-link [[nonexistent-doc]]"
else
  fail "Did not detect broken wiki-link. Output: $OUTPUT"
fi

# ── T15: check-wikilinks.sh — valid file link is silent ────────────────────

echo ""
echo "T15: check-wikilinks does NOT report valid [[component-graph]] link"

# Restore full _index.md with both valid and broken links
cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[component-graph]] for components.
See [[entity-map]] for entities.
See [[nonexistent-doc]] for nothing.
EOF

OUTPUT=$(bash "$ROOT/hooks/check-wikilinks.sh" "$TEST_DIR/design-knowledge/vault" 2>&1 || true)

if echo "$OUTPUT" | grep -q "\[\[component-graph\]\]"; then
  fail "Valid link [[component-graph]] was reported as broken: $OUTPUT"
else
  ok "Valid link [[component-graph]] not reported as broken"
fi

# ── T16: check-wikilinks.sh — detects broken section link ─────────────────

echo ""
echo "T16: check-wikilinks detects broken [[entity-map#Deleted]] heading"

OUTPUT=$(bash "$ROOT/hooks/check-wikilinks.sh" "$TEST_DIR/design-knowledge/vault" 2>&1 || true)

if echo "$OUTPUT" | grep -q "entity-map#Deleted"; then
  ok "Detected broken heading link [[entity-map#Deleted]]"
else
  fail "Did not detect broken heading link. Output: $OUTPUT"
fi

# ── T17: check-wikilinks.sh — valid section link is silent ────────────────

echo ""
echo "T17: check-wikilinks does NOT report valid [[entity-map#User]] heading"

OUTPUT=$(bash "$ROOT/hooks/check-wikilinks.sh" "$TEST_DIR/design-knowledge/vault" 2>&1 || true)

if echo "$OUTPUT" | grep -q "entity-map#User"; then
  fail "Valid heading link [[entity-map#User]] was reported as broken: $OUTPUT"
else
  ok "Valid heading link [[entity-map#User]] not reported"
fi

# ── T18: check-wikilinks.sh — hook mode with CLAUDE_PROJECT_DIR ───────────

echo ""
echo "T18: check-wikilinks works in hook mode (no args, uses CLAUDE_PROJECT_DIR)"

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-wikilinks.sh" 2>&1 || true)

if echo "$OUTPUT" | grep -q "nonexistent-doc"; then
  ok "Hook mode detected broken link via CLAUDE_PROJECT_DIR"
else
  fail "Hook mode did not work. Output: $OUTPUT"
fi

# ── T19: check-wikilinks.sh — no KB dir = silent exit ─────────────────────

echo ""
echo "T19: check-wikilinks silent when no KB directory found"

EMPTY_DIR=$(mktemp -d)
OUTPUT=$(CLAUDE_PROJECT_DIR="$EMPTY_DIR" bash "$ROOT/hooks/check-wikilinks.sh" 2>&1 || true)
EXIT_CODE=$?
rm -rf "$EMPTY_DIR"

if [[ -z "$OUTPUT" ]] && [[ "$EXIT_CODE" -eq 0 ]]; then
  ok "Silent exit when no KB directory"
else
  fail "Expected silent exit 0, got exit=$EXIT_CODE output=$OUTPUT"
fi

# ── T20: check-wikilinks.sh is executable ──────────────────────────────────

echo ""
echo "T20: check-wikilinks.sh is executable"

if [[ -x "$ROOT/hooks/check-wikilinks.sh" ]]; then
  ok "check-wikilinks.sh is executable"
else
  fail "check-wikilinks.sh is not executable"
fi

# ── T21: settings.json includes check-wikilinks hook ──────────────────────

echo ""
echo "T21: settings.json includes check-wikilinks SessionStart hook"

if grep -q "check-wikilinks.sh" "$ROOT/templates/settings.json"; then
  ok "check-wikilinks.sh registered in settings.json"
else
  fail "check-wikilinks.sh missing from settings.json"
fi

# ── T22: CLAUDE.md documents KB link validation ───────────────────────────

echo ""
echo "T22: templates/CLAUDE.md documents KB link validation hook"

if grep -q "KB link" "$ROOT/templates/CLAUDE.md" || grep -q "wikilink" "$ROOT/templates/CLAUDE.md"; then
  ok "KB link validation documented in CLAUDE.md"
else
  fail "KB link validation missing from CLAUDE.md"
fi

# ── Cleanup ─────────────────────────────────────────────────────────────────

rm -f "$DRIFT_LOG"

# ── Results ──────────────────────────────────────────────────────────────────

echo ""
echo "  Results: $PASS passed, $FAIL failed"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
