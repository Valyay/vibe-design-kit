#!/usr/bin/env bash
# VDK Hook: Detect knowledge base drift after code edits
# Trigger: PostToolUse on Edit|Write (async, informational)
# When a code file is edited, checks if KB documents reference it.
# If yes, reminds AI to update the relevant KB docs after the task.
# Non-blocking: always exits 0.
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

[[ -n "$FILE_PATH" ]] || exit 0

# Only check code files that would affect KB content
case "$FILE_PATH" in
  *.tsx|*.jsx|*.ts|*.js|*.vue|*.svelte|*.css|*.scss) ;;
  *) exit 0 ;;
esac

# Skip test, story, and config files — they don't appear in KB docs
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*|*.config.*) exit 0 ;;
esac

# Skip KB files themselves — editing KB is the goal, not the trigger
case "$FILE_PATH" in
  */design-knowledge/*|*/knowledge-base/*) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Find KB directory (same pattern as other hooks, exclude heavy dirs)
KB_DIR=$(find "$PROJECT_DIR" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -path "*/dist" -prune -o -path "*/build" -prune -o \
  -path "*/design-knowledge/*/_index.md" -not -path "*/_project-template/*" -print 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)

[[ -n "$KB_DIR" ]] || exit 0

# Extract the filename and component-like name for searching
FILENAME=$(basename "$FILE_PATH")
NAME_NO_EXT="${FILENAME%%.*}"

# Avoid false positives on generic names (index, utils, helpers, types, etc.)
case "$NAME_NO_EXT" in
  index|utils|helpers|types|constants|config|styles|theme|layout|page|loading|error|not-found) exit 0 ;;
esac

# Search KB primary docs for references to this file or component name
KB_DOCS="component-graph.md entity-map.md screen-inventory.md user-flows.md visual-language.md"
MATCHED_DOCS=""

for doc in $KB_DOCS; do
  DOC_PATH="$KB_DIR/$doc"
  [[ -f "$DOC_PATH" ]] || continue
  # Search for filename or component name (fixed string, case-insensitive)
  if grep -qiF "$NAME_NO_EXT" "$DOC_PATH" 2>/dev/null; then
    MATCHED_DOCS="${MATCHED_DOCS} ${doc}"
  fi
done

if [[ -n "$MATCHED_DOCS" ]]; then
  # Deduplicate reminder: track per-session to avoid spamming on every edit
  DRIFT_LOG="/tmp/vdk-kb-drift-$(printf '%s' "$PROJECT_DIR" | tr '/' '_').log"

  # Clear stale drift log (older than 4 hours = likely a new session)
  if [[ -f "$DRIFT_LOG" ]]; then
    LOG_MTIME=$(stat -f%m "$DRIFT_LOG" 2>/dev/null || stat -c%Y "$DRIFT_LOG" 2>/dev/null || echo "")
    if [[ -z "$LOG_MTIME" ]]; then
      LOG_AGE_S=0
    else
      LOG_AGE_S=$(( $(date +%s) - LOG_MTIME ))
    fi
    if [[ "$LOG_AGE_S" -gt 14400 ]]; then
      rm -f "$DRIFT_LOG"
    fi
  fi

  # Check if we already reminded about this file in this session
  if [[ -f "$DRIFT_LOG" ]] && grep -qF "$FILENAME" "$DRIFT_LOG" 2>/dev/null; then
    exit 0
  fi

  # Record that we reminded about this file
  echo "$FILENAME" >> "$DRIFT_LOG"

  echo "VDK: You edited ${NAME_NO_EXT} which is referenced in:${MATCHED_DOCS}."
  echo "Remember to update the knowledge base after completing this task."
fi

exit 0
