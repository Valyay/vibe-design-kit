#!/usr/bin/env bash
# VDK Hook: Remind to create Storybook story for new components
# Trigger: PostToolUse on Write
# Enforces: "Every new component MUST have a story" from CLAUDE.md
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

# Skip test/story/index files
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*|*/index.*) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Check if Storybook is present in the project
if [[ ! -d "$PROJECT_DIR/.storybook" ]]; then
  echo "VDK: Storybook not detected — story coverage check skipped."
  echo "  Add Storybook to enforce the 5-state component contract (Loading, Error, Empty, Populated, Partial)."
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
  echo "VDK: '$NAME_NO_EXT' has no Storybook story."
  echo "  Create a story covering all 5 states: Loading, Error, Empty, Populated, Partial."
  echo "  See components/CLAUDE.md for the Storybook + E2E pipeline."
else
  echo "VDK: '$NAME_NO_EXT' story exists — 5-state coverage assumed."
fi

exit 0
