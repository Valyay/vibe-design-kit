#!/usr/bin/env bash
# Tests for check-a11y.sh — a11y assertion coverage in e2e specs
# Run: bash tests/check-a11y.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
HOOK="$ROOT/hooks/check-a11y.sh"

PASS=0
FAIL=0

ok()   { echo "  ✓  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/src/components" "$TEST_DIR/e2e"

# ── T1: skips non-JSX .ts file ────────────────────────────────────────────

echo ""
echo "T1: skips utility .ts file (no JSX)"

INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/utils.ts"}}'
OUTPUT=$(echo "$INPUT" | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "Silent exit for .ts file"
else
  fail "Expected silence, got: $OUTPUT"
fi

# ── T2: skips test/story/config files ────────────────────────────────────

echo ""
echo "T2: skips .test.tsx and .stories.tsx files"

for skip_file in \
  "$TEST_DIR/src/components/Button.test.tsx" \
  "$TEST_DIR/src/components/Button.stories.tsx" \
  "$TEST_DIR/src/components/Button.spec.tsx"; do
  INPUT='{"tool_input":{"file_path":"'"$skip_file"'"}}'
  OUTPUT=$(echo "$INPUT" | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" 2>&1 || true)
  if [[ -z "$OUTPUT" ]]; then
    ok "Silent exit for $(basename "$skip_file")"
  else
    fail "Expected silence for $(basename "$skip_file"), got: $OUTPUT"
  fi
done

# ── T3: e2e spec with axe assertion → silent ─────────────────────────────

echo ""
echo "T3: e2e spec with axe assertion — no warning"

cat > "$TEST_DIR/e2e/button.spec.ts" << 'EOF'
import { checkA11y } from 'axe-playwright';
test('button is accessible', async ({ page }) => {
  await checkA11y(page);
});
EOF

INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx"}}'
OUTPUT=$(echo "$INPUT" | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "Silent when axe assertion present"
else
  fail "Expected silence, got: $OUTPUT"
fi

# ── T4: e2e spec exists but no axe assertion → warns ─────────────────────

echo ""
echo "T4: e2e spec without axe assertion — warns"

cat > "$TEST_DIR/e2e/button.spec.ts" << 'EOF'
test('button renders', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('button')).toBeVisible();
});
EOF

INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx"}}'
OUTPUT=$(echo "$INPUT" | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" 2>&1 || true)

if echo "$OUTPUT" | grep -qi "a11y\|axe\|accessibility"; then
  ok "Warns when axe assertion missing"
else
  fail "Expected a11y warning, got: $OUTPUT"
fi

# ── T5: no e2e spec → silent (check-e2e-test-exists.sh handles that) ──────

echo ""
echo "T5: no e2e spec exists — silent exit"

rm -f "$TEST_DIR/e2e/button.spec.ts"

INPUT='{"tool_input":{"file_path":"'"$TEST_DIR"'/src/components/Button.tsx"}}'
OUTPUT=$(echo "$INPUT" | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
  ok "Silent when no e2e spec exists"
else
  fail "Expected silence, got: $OUTPUT"
fi

# ── T6: hook is executable ────────────────────────────────────────────────

echo ""
echo "T6: check-a11y.sh is executable"

if [[ -x "$HOOK" ]]; then
  ok "check-a11y.sh is executable"
else
  fail "check-a11y.sh is not executable"
fi

echo ""
echo "  Results: $PASS passed, $FAIL failed"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
