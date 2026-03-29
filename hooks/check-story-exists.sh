#!/usr/bin/env bash
# VDK Hook: Remind to create Storybook story for new components
# Trigger: PostToolUse on Write
# Enforces: "Every new component MUST have a story" from CLAUDE.md
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "VDK: jq is required for enforcement hooks. Install with: brew install jq" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check component files in component-like directories
case "$FILE_PATH" in
  */components/*|*/ui/*|*/shared/*|*/common/*) ;;
  *) exit 0 ;;
esac

# Only check actual component files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

# Skip test/story/index files
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*|*/index.*) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Check if Storybook is present in the project
if [[ ! -d "$PROJECT_DIR/.storybook" ]]; then
  # No Storybook — skip this check
  exit 0
fi

# Derive expected story file paths
DIR=$(dirname "$FILE_PATH")
FILENAME=$(basename "$FILE_PATH")
NAME_NO_EXT="${FILENAME%%.*}"
EXT="${FILENAME##*.}"

# Check common story file naming patterns
STORY_EXISTS=false
for pattern in \
  "$DIR/$NAME_NO_EXT.stories.$EXT" \
  "$DIR/$NAME_NO_EXT.stories.ts" \
  "$DIR/$NAME_NO_EXT.stories.tsx" \
  "$DIR/$NAME_NO_EXT.stories.js" \
  "$DIR/$NAME_NO_EXT.stories.jsx" \
  "$DIR/__stories__/$NAME_NO_EXT.stories.$EXT" \
  "$DIR/../stories/$NAME_NO_EXT.stories.$EXT"; do
  if [[ -f "$pattern" ]]; then
    STORY_EXISTS=true
    break
  fi
done

if [[ "$STORY_EXISTS" == "false" ]]; then
  echo "VDK: New component '$NAME_NO_EXT' has no Storybook story yet."
  echo "Create a story with all 5 states: Loading, Error, Empty, Populated, Partial."
  echo "See components/CLAUDE.md for the Storybook + E2E pipeline."
fi

exit 0
