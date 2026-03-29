#!/usr/bin/env bash
# VDK Hook: Warn about direct edits to baseline and sync-log
# Trigger: PreToolUse on Edit|Write
# Note: warns instead of blocking because the sync skill needs write access
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "VDK: jq is required for enforcement hooks. Install with: brew install jq" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Check if the file is in a protected path
case "$FILE_PATH" in
  */design-knowledge/*/baseline/*)
    echo "VDK: You are editing a baseline file. Baselines are normally captured automatically during setup and sync. If you are running the sync skill, proceed. Otherwise, use the sync skill: paste the contents of prompts/sync-vault.md"
    ;;
  */design-knowledge/*/_sync-log.md)
    echo "VDK: You are editing _sync-log.md. The sync log is normally updated by the sync skill. If you are running the sync skill, proceed. Otherwise, use the sync skill: paste the contents of prompts/sync-vault.md"
    ;;
esac

exit 0
