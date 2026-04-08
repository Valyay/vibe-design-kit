#!/usr/bin/env bash
# VDK Hook: Check that component e2e specs include axe accessibility assertions
# Trigger: PostToolUse on Write
# Enforces: "Run accessibility check via @axe-core/playwright" from CLAUDE.md workflow
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

# Only check component files with JSX
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

# Skip test, story, and config files
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*|*.config.*|*.d.ts) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
NAME_NO_EXT=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')
NAME_LOWER=$(echo "$NAME_NO_EXT" | tr '[:upper:]' '[:lower:]')

# Find the matching e2e spec file
SPEC_FILE=""
while IFS= read -r -d '' spec; do
  spec_base=$(basename "$spec" | sed 's/\.[^.]*$//' | sed 's/\.spec$//' | sed 's/\.e2e$//' | tr '[:upper:]' '[:lower:]')
  if [[ "$spec_base" == "$NAME_LOWER" ]]; then
    SPEC_FILE="$spec"
    break
  fi
done < <(find "$PROJECT_DIR" \
  \( -path "*/node_modules" -o -path "*/.git" -o -path "*/dist" -o -path "*/build" \) -prune \
  -o -name "*.spec.ts" -print0 \
  -o -name "*.spec.tsx" -print0 \
  -o -name "*.spec.js" -print0 \
  -o -name "*.e2e.ts" -print0 \
  -o -name "*.e2e.spec.ts" -print0 \
  2>/dev/null)

# No spec found — the e2e hook handles that; nothing to check here
[[ -n "$SPEC_FILE" ]] || exit 0

# Check for axe / accessibility assertion in the spec
# Patterns: function calls and imports only — not comments mentioning "axe"
if grep -qiE "checkA11y|injectAxe|checkAccessibility|toHaveNoViolations|scanForAccessibilityIssues" "$SPEC_FILE" 2>/dev/null; then
  exit 0
fi

# Deduplicate: warn once per component per session
A11Y_LOG="/tmp/vdk-a11y-$(printf '%s' "$PROJECT_DIR" | tr '/' '_').log"
if [[ -f "$A11Y_LOG" ]] && grep -qF "$NAME_NO_EXT" "$A11Y_LOG" 2>/dev/null; then
  exit 0
fi
echo "$NAME_NO_EXT" >> "$A11Y_LOG"

echo "VDK a11y: '$NAME_NO_EXT' has an e2e spec but no accessibility assertion."
echo "  Add an axe check to $(basename "$SPEC_FILE"):"
echo "    import { checkA11y, injectAxe } from 'axe-playwright';"
echo "    await injectAxe(page); await checkA11y(page);"

exit 0
