#!/usr/bin/env bash
# VDK Hook: Warn about duplicate components
# Trigger: PreToolUse on Write
# Enforces: "Duplicate prevention" rule from CLAUDE.md
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "VDK: jq is required for enforcement hooks. Install with: brew install jq" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check when creating new files in component-like directories
case "$FILE_PATH" in
  */components/*|*/ui/*|*/shared/*|*/common/*) ;;
  *) exit 0 ;;
esac

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
