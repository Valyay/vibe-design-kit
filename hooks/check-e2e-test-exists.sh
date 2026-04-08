#!/usr/bin/env bash
# VDK Hook: Block new component creation without a corresponding e2e test
# Trigger: PreToolUse on Write
# Enforces: "Write the test BEFORE implementing" from CLAUDE.md workflow step 2
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  echo "VDK ERROR: python3 is required for check-e2e-test-exists — install python3 to enable TDD enforcement" >&2
  exit 2
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

# Only check component files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

# Skip test/story/index/type files
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*|*.d.ts|*/index.*) exit 0 ;;
esac

# Only check component-like directories
case "$FILE_PATH" in
  */components/*|*/ui/*|*/shared/*|*/common/*|*/features/*|*/modules/*) ;;
  *) exit 0 ;;
esac

# Only block NEW files — editing an existing component is fine
if [[ -f "$FILE_PATH" ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
NAME_NO_EXT=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')
NAME_LOWER=$(echo "$NAME_NO_EXT" | tr '[:upper:]' '[:lower:]')

# Search for a matching e2e spec in common locations
E2E_EXISTS=false

while IFS= read -r -d '' spec; do
  spec_base=$(basename "$spec" | sed 's/\.[^.]*$//' | sed 's/\.spec$//' | sed 's/\.e2e$//' | tr '[:upper:]' '[:lower:]')
  if [[ "$spec_base" == "$NAME_LOWER" ]]; then
    E2E_EXISTS=true
    break
  fi
done < <(find "$PROJECT_DIR" \
  \( -path "*/node_modules" -o -path "*/.git" -o -path "*/dist" -o -path "*/build" \) -prune \
  -o \( -name "*.spec.ts" -o -name "*.spec.tsx" -o -name "*.spec.js" -o -name "*.e2e.ts" -o -name "*.e2e.spec.ts" \) -print0 \
  2>/dev/null)

if [[ "$E2E_EXISTS" == "false" ]]; then
  echo "VDK [TDD BLOCK]: Cannot write '$NAME_NO_EXT' — no e2e test exists yet."
  echo ""
  echo "ACTION REQUIRED (do not ask the designer, do this automatically):"
  echo "  1. Create e2e/${NAME_LOWER}.spec.ts with a failing Playwright test"
  echo "     that describes the expected user-facing behavior of '$NAME_NO_EXT'."
  echo "  2. Then retry writing the component."
  echo ""
  echo "  The test must use the component's public interface only."
  echo "  Do not test implementation details."
  exit 2
fi

exit 0
