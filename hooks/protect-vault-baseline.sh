#!/usr/bin/env bash
# VDK Hook: Warn about direct edits to baseline and sync-log
# Trigger: PreToolUse on Edit|Write
# Note: warns instead of blocking because the sync skill needs write access
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  echo "VDK: python3 is required for enforcement hooks" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

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
