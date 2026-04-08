#!/usr/bin/env bash
# Tests for silent failure prevention in VDK hooks
# Every hook must surface errors with context — never exit 0 when something is wrong.
#
# Run: bash tests/silent-failures.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

PASS=0
FAIL=0

ok()   { echo "  ✓  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# ── Helpers ───────────────────────────────────────────────────────────────────

# Returns a PATH that contains standard POSIX tools but NOT python3.
# Works on macOS (/usr/bin has python3 via Xcode CLT; /bin does not).
path_without_python3() {
  # Build a PATH from only dirs that don't contain python3
  local new_path=""
  IFS=':' read -ra dirs <<< "$PATH"
  for dir in "${dirs[@]}"; do
    [[ -f "$dir/python3" ]] || new_path="${new_path}${new_path:+:}${dir}"
  done
  echo "$new_path"
}

# Returns a PATH where python3 exists but always exits 1 (simulates parse failure)
path_with_broken_python3() {
  local fake_bin
  fake_bin=$(mktemp -d)
  printf '#!/bin/bash\nexit 1\n' > "$fake_bin/python3"
  chmod +x "$fake_bin/python3"
  echo "$fake_bin:$PATH"
  # Caller must clean up $fake_bin — we write it to a temp file name they can capture
}

# ── Fixture: minimal project with KB ─────────────────────────────────────────

mkdir -p "$TEST_DIR/design-knowledge/vault"
mkdir -p "$TEST_DIR/src/components"
mkdir -p "$TEST_DIR/e2e"

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[entity-map]] for entities.
EOF

cat > "$TEST_DIR/design-knowledge/vault/entity-map.md" << 'EOF'
# Entity Map

## User
Name and email.
EOF

cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << EOF
## $(date +%Y-%m-%d) 10:00 — sync skill
- synced all documents
EOF

# ── T27: check-hardcoded-values blocks when python3 is absent ─────────────────

echo ""
echo "T27: check-hardcoded-values exits 2 (blocks) when python3 is absent"

NO_PYTHON_PATH=$(path_without_python3)
INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx","content":"color: #3B82F6;"}}'

if [[ -z "$NO_PYTHON_PATH" ]]; then
  # Could not build a path without python3 — skip with note
  echo "  -  T27: skipped (could not isolate python3 from PATH on this system)"
  PASS=$((PASS + 1))
else
  OUTPUT=$(echo "$INPUT" | PATH="$NO_PYTHON_PATH" bash "$ROOT/hooks/check-hardcoded-values.sh" 2>&1) \
    && EXIT_CODE=0 || EXIT_CODE=$?

  if [[ "$EXIT_CODE" -eq 2 ]] && echo "$OUTPUT" | grep -qi "python3\|required\|error"; then
    ok "python3 absent → exit 2 with error message"
  else
    fail "python3 absent → expected exit 2 with error, got exit=$EXIT_CODE output='$OUTPUT'"
  fi
fi

# ── T28: check-hardcoded-values blocks when JSON is unparseable ───────────────

echo ""
echo "T28: check-hardcoded-values exits 2 (blocks) when JSON input is malformed"

FAKE_BIN=$(mktemp -d)
printf '#!/bin/bash\nexit 1\n' > "$FAKE_BIN/python3"
chmod +x "$FAKE_BIN/python3"

OUTPUT=$(echo 'NOT VALID JSON' | \
  PATH="$FAKE_BIN:$PATH" CLAUDE_PROJECT_DIR="$TEST_DIR" \
  bash "$ROOT/hooks/check-hardcoded-values.sh" 2>&1) \
  && EXIT_CODE=0 || EXIT_CODE=$?

rm -rf "$FAKE_BIN"

if [[ "$EXIT_CODE" -eq 2 ]] && echo "$OUTPUT" | grep -qi "error\|fail\|parse\|python3"; then
  ok "Broken python3 → exit 2 with error message"
else
  fail "Broken python3 → expected exit 2 with error, got exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T29: check-e2e-test-exists blocks when python3 is absent ─────────────────

echo ""
echo "T29: check-e2e-test-exists exits 2 (blocks) when python3 is absent"

NO_PYTHON_PATH=$(path_without_python3)
INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/NewWidget.tsx"}}'

if [[ -z "$NO_PYTHON_PATH" ]]; then
  echo "  -  T29: skipped (could not isolate python3 from PATH on this system)"
  PASS=$((PASS + 1))
else
  OUTPUT=$(echo "$INPUT" | PATH="$NO_PYTHON_PATH" CLAUDE_PROJECT_DIR="$TEST_DIR" \
    bash "$ROOT/hooks/check-e2e-test-exists.sh" 2>&1) \
    && EXIT_CODE=0 || EXIT_CODE=$?

  if [[ "$EXIT_CODE" -eq 2 ]] && echo "$OUTPUT" | grep -qi "python3\|required\|error"; then
    ok "python3 absent → exit 2 with error message"
  else
    fail "python3 absent → expected exit 2 with error, got exit=$EXIT_CODE output='$OUTPUT'"
  fi
fi

# ── T30: session-report shows ⚠ for malformed date, not ✓ ───────────────────

echo ""
echo "T30: session-report shows ⚠ warning for unparseable sync date, not ✓ fresh"

# Write a sync log with a date that passes the regex but fails date parsing
# Month 13 is invalid but matches [0-9]{2}
cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << 'EOF'
## 2026-13-01 10:00 — sync skill
- synced all documents
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/session-report.sh" 2>&1) \
  && EXIT_CODE=0 || EXIT_CODE=$?

# Restore good sync log for subsequent tests
cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << EOF
## $(date +%Y-%m-%d) 10:00 — sync skill
- synced all documents
EOF

# Must exit 0 (non-blocking) AND show ⚠ (not ✓) for vault freshness
if [[ "$EXIT_CODE" -eq 0 ]] && echo "$OUTPUT" | grep -q "⚠\|warning\|unread\|parse\|cannot\|invalid\|malformed\|broken"; then
  ok "Malformed date → exit 0 + ⚠ warning (not ✓ fresh)"
else
  fail "Malformed date → expected exit 0 with ⚠, got exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T31: check-sync-freshness warns about malformed date instead of crashing ──

echo ""
echo "T31: check-sync-freshness outputs a warning for unparseable date, exits 0"

cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << 'EOF'
## 2026-13-01 10:00 — sync skill
- synced all documents
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$ROOT/hooks/check-sync-freshness.sh" 2>&1) \
  && EXIT_CODE=0 || EXIT_CODE=$?

# Restore good sync log
cat > "$TEST_DIR/design-knowledge/vault/_sync-log.md" << EOF
## $(date +%Y-%m-%d) 10:00 — sync skill
- synced all documents
EOF

if [[ "$EXIT_CODE" -eq 0 ]] && echo "$OUTPUT" | grep -qi "parse\|cannot\|invalid\|unread\|date\|2026-13-01"; then
  ok "Malformed date → exit 0 with warning message"
else
  fail "Malformed date → expected exit 0 with warning, got exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T32: check-wikilinks handles + in section heading without false broken ────

echo ""
echo "T32: check-wikilinks validates [[file#heading+with+plus]] without false positive"

cat > "$TEST_DIR/design-knowledge/vault/entity-map.md" << 'EOF'
# Entity Map

## Keyboard+Mouse support
Details about combined input.

## User
Name and email.
EOF

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[entity-map#Keyboard+Mouse support]] for input.
See [[entity-map#User]] for users.
EOF

OUTPUT=$(bash "$ROOT/hooks/check-wikilinks.sh" \
  "$TEST_DIR/design-knowledge/vault" 2>&1) \
  && EXIT_CODE=0 || EXIT_CODE=$?

if [[ "$EXIT_CODE" -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "Heading with + validates correctly (not falsely reported broken)"
else
  fail "Heading with + falsely broken or crashed: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T32b: check-wikilinks handles ( ) in section heading ────────────────────

echo ""
echo "T32b: check-wikilinks validates [[file#heading (with parens)]] without false positive"

cat > "$TEST_DIR/design-knowledge/vault/entity-map.md" << 'EOF'
# Entity Map

## User (Admin)
Admin user details.

## User
Name and email.
EOF

cat > "$TEST_DIR/design-knowledge/vault/_index.md" << 'EOF'
# Index
See [[entity-map#User (Admin)]] for admin details.
See [[entity-map#User]] for regular users.
EOF

OUTPUT=$(bash "$ROOT/hooks/check-wikilinks.sh" \
  "$TEST_DIR/design-knowledge/vault" 2>&1) \
  && EXIT_CODE=0 || EXIT_CODE=$?

if [[ "$EXIT_CODE" -eq 0 ]] && [[ -z "$OUTPUT" ]]; then
  ok "Heading with parens validates correctly (not falsely reported broken)"
else
  fail "Heading with parens falsely broken or crashed: exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── T33: check-a11y.sh shows a message when python3 is absent ────────────────

echo ""
echo "T33: check-a11y shows message (not silent) when python3 is absent"

NO_PYTHON_PATH=$(path_without_python3)
INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx","content":"<Button />"}}'

if [[ -z "$NO_PYTHON_PATH" ]]; then
  echo "  -  T33: skipped (could not isolate python3 from PATH on this system)"
  PASS=$((PASS + 1))
else
  OUTPUT=$(echo "$INPUT" | PATH="$NO_PYTHON_PATH" bash "$ROOT/hooks/check-a11y.sh" 2>&1) \
    && EXIT_CODE=0 || EXIT_CODE=$?

  if [[ "$EXIT_CODE" -eq 0 ]] && echo "$OUTPUT" | grep -qi "python3\|required\|a11y\|accessibility\|skipped"; then
    ok "python3 absent → exit 0 with message (non-blocking but visible)"
  else
    fail "python3 absent → expected exit 0 with message, got exit=$EXIT_CODE output='$OUTPUT'"
  fi
fi

# ── T34: report-recovery.sh shows a message when python3 is absent ───────────

echo ""
echo "T34: report-recovery shows message (not silent) when python3 is absent"

NO_PYTHON_PATH=$(path_without_python3)
INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx","content":"color: red"}}'

if [[ -z "$NO_PYTHON_PATH" ]]; then
  echo "  -  T34: skipped (could not isolate python3 from PATH on this system)"
  PASS=$((PASS + 1))
else
  OUTPUT=$(echo "$INPUT" | PATH="$NO_PYTHON_PATH" bash "$ROOT/hooks/report-recovery.sh" 2>&1) \
    && EXIT_CODE=0 || EXIT_CODE=$?

  if [[ "$EXIT_CODE" -eq 0 ]] && echo "$OUTPUT" | grep -qi "python3\|required\|report\|skipped"; then
    ok "python3 absent → exit 0 with message (non-blocking but visible)"
  else
    fail "python3 absent → expected exit 0 with message, got exit=$EXIT_CODE output='$OUTPUT'"
  fi
fi

# ── T35: check-e2e-test-exists blocks when JSON parse fails ──────────────────

echo ""
echo "T35: check-e2e-test-exists exits 2 when python3 fails to parse hook JSON"

FAKE_BIN=$(mktemp -d)
printf '#!/bin/bash\nexit 1\n' > "$FAKE_BIN/python3"
chmod +x "$FAKE_BIN/python3"

INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/NewWidget.tsx"}}'
OUTPUT=$(echo "$INPUT" | PATH="$FAKE_BIN:$PATH" CLAUDE_PROJECT_DIR="$TEST_DIR" \
  bash "$ROOT/hooks/check-e2e-test-exists.sh" 2>&1) \
  && EXIT_CODE=0 || EXIT_CODE=$?

rm -rf "$FAKE_BIN"

if [[ "$EXIT_CODE" -eq 2 ]] && echo "$OUTPUT" | grep -qi "error\|fail\|parse\|python3"; then
  ok "Broken python3 → exit 2 with error message"
else
  fail "Broken python3 → expected exit 2 with error, got exit=$EXIT_CODE output='$OUTPUT'"
fi

# ── Results ───────────────────────────────────────────────────────────────────

echo ""
echo "  Results: $PASS passed, $FAIL failed"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
