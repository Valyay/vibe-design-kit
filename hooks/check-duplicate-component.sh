#!/usr/bin/env bash
# VDK Hook: Warn about duplicate components
# Trigger: PreToolUse on Write
# Enforces: "Duplicate prevention" rule from CLAUDE.md
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  echo "VDK: python3 is required for enforcement hooks" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

# Only check actual component files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

# Skip test/story files
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*) exit 0 ;;
esac

# Don't warn for files that already exist (edits, not new files)
if [[ -f "$FILE_PATH" ]]; then
  exit 0
fi

# Extract component name from file path
FILENAME=$(basename "$FILE_PATH")
COMPONENT_NAME="${FILENAME%%.*}"

# Normalize: remove common suffixes to get the base name
BASE_NAME=$(echo "$COMPONENT_NAME" | sed -E 's/(Component|View|Widget|Container|Wrapper|Section|Card|List|Item|Button|Modal|Dialog|Form|Input|Panel|Header|Footer|Nav|Sidebar|Layout)$//i')

if [[ -z "$BASE_NAME" ]]; then
  BASE_NAME="$COMPONENT_NAME"
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Search for similarly-named component files
SIMILAR=$(find "$PROJECT_DIR" \
  -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" \) \
  ! -name "*.test.*" ! -name "*.spec.*" ! -name "*.stories.*" ! -name "*.story.*" \
  ! -path "*/node_modules/*" ! -path "*/.next/*" ! -path "*/dist/*" ! -path "*/.storybook/*" \
  2>/dev/null | \
  grep -iF "$BASE_NAME" | \
  grep -v "$FILE_PATH" | \
  head -5 || true)

if [[ -n "$SIMILAR" ]]; then
  # Output as informational message (stdout), not blocking (exit 0)
  echo "VDK: Similar component(s) already exist:"
  echo "$SIMILAR" | while read -r match; do
    echo "  - $match"
  done
  echo "Consider extending an existing component instead of creating a new one."
  echo "If this is intentional, proceed — this is a warning, not a block."
  exit 0
fi

exit 0
