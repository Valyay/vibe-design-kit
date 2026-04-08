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
if ! FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null); then
  echo "VDK ERROR: check-e2e-test-exists failed to parse hook input — blocking as precaution" >&2
  exit 2
fi

# Only check component files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

# Skip test/story/index/type files
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*|*.d.ts|*/index.*) exit 0 ;;
esac


# Only block NEW files — editing an existing component is fine
if [[ -f "$FILE_PATH" ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# For index files, use the parent directory name as the component name
NAME_NO_EXT=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')
if [[ "$NAME_NO_EXT" == "index" ]]; then
  NAME_NO_EXT=$(basename "$(dirname "$FILE_PATH")")
fi

# Normalize: lowercase + CamelCase → kebab-case + strip hyphens for loose match
NAME_LOWER=$(echo "$NAME_NO_EXT" | tr '[:upper:]' '[:lower:]')
NAME_KEBAB=$(echo "$NAME_NO_EXT" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1-\2/g' | tr '[:upper:]' '[:lower:]')
NAME_NOHYPHEN=$(echo "$NAME_KEBAB" | tr -d '-')

# Search for a matching e2e spec and capture its path
MATCHED_SPEC=""

while IFS= read -r -d '' spec; do
  spec_base=$(basename "$spec" | sed 's/\.[^.]*$//' | sed 's/\.spec$//' | sed 's/\.e2e$//' | tr '[:upper:]' '[:lower:]')
  spec_nohyphen=$(echo "$spec_base" | tr -d '-')
  if [[ "$spec_base" == "$NAME_LOWER" || "$spec_base" == "$NAME_KEBAB" || "$spec_nohyphen" == "$NAME_NOHYPHEN" ]]; then
    MATCHED_SPEC="$spec"
    break
  fi
done < <(find "$PROJECT_DIR" \
  \( -path "*/node_modules" -o -path "*/.git" -o -path "*/dist" -o -path "*/build" \) -prune \
  -o \( -name "*.spec.ts" -o -name "*.spec.tsx" -o -name "*.spec.js" -o -name "*.e2e.ts" -o -name "*.e2e.spec.ts" \) -print0 \
  2>/dev/null)

if [[ -z "$MATCHED_SPEC" ]]; then
  echo "VDK [TDD BLOCK]: Cannot write '$NAME_NO_EXT' — no e2e test exists yet."
  echo ""
  echo "DO THIS NOW (automatically, without asking the designer):"
  echo "  1. Create e2e/${NAME_KEBAB}.spec.ts with ONE failing Playwright test"
  echo "     describing the expected user-facing behavior of '$NAME_NO_EXT'."
  echo "  2. The spec must contain at least one test() or it() call."
  echo "  3. Then retry writing the component/page."
  echo ""
  echo "  Do not ask the designer to disable TDD guard or run any commands."
  exit 2
fi

# Spec found — verify it contains at least one actual test, not just an empty shell
if ! grep -qE "^\s*(test|it)\s*\(" "$MATCHED_SPEC" 2>/dev/null; then
  echo "VDK [TDD BLOCK]: '$NAME_NO_EXT' has a spec file but it contains no tests."
  echo ""
  echo "  Add at least one failing test() to $(basename "$MATCHED_SPEC") before implementing."
  echo "  Example: test('renders page title', async ({ page }) => { ... })"
  exit 2
fi

exit 0
