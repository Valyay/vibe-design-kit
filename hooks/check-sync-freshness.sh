#!/usr/bin/env bash
# VDK Hook: Check knowledge base freshness on session start
# Trigger: SessionStart
# If _sync-log.md has no entries or last sync > N days ago, suggest running sync
set -euo pipefail

# Configurable threshold (default: 7 days)
SYNC_STALE_DAYS="${SYNC_STALE_DAYS:-7}"

# Find _sync-log.md in the knowledge base
SYNC_LOG=$(find "${CLAUDE_PROJECT_DIR:-.}" -path "*/design-knowledge/*/_sync-log.md" -not -path "*/_project-template/*" 2>/dev/null | head -1)

if [[ -z "$SYNC_LOG" ]]; then
  # No knowledge base found — nothing to check
  exit 0
fi

# Extract the most recent date from sync log (format: ## YYYY-MM-DD ...)
LAST_DATE=$(grep -oE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$SYNC_LOG" 2>/dev/null | head -1 | sed 's/^## //' || true)

if [[ -z "$LAST_DATE" ]]; then
  echo "VDK: Knowledge base has never been synced (_sync-log.md has no entries). Run the sync skill to populate it: paste the contents of prompts/sync-vault.md"
  exit 0
fi

# Calculate days since last sync (macOS and GNU date compatible)
if date -j -f "%Y-%m-%d" "$LAST_DATE" "+%s" &>/dev/null; then
  # macOS
  LAST_TS=$(date -j -f "%Y-%m-%d" "$LAST_DATE" "+%s")
  NOW_TS=$(date "+%s")
else
  # GNU/Linux
  LAST_TS=$(date -d "$LAST_DATE" "+%s")
  NOW_TS=$(date "+%s")
fi

DAYS_AGO=$(( (NOW_TS - LAST_TS) / 86400 ))

# Count UI-relevant files changed since last sync (git-based drift detection)
CHANGED_FILES=0
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
if command -v git &>/dev/null && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  CHANGED_FILES=$(git -C "$PROJECT_DIR" log --since="$LAST_DATE" --diff-filter=ACDMR --name-only --pretty=format: -- \
    '*.tsx' '*.jsx' '*.ts' '*.js' '*.vue' '*.svelte' '*.css' '*.scss' \
    2>/dev/null | grep -v '^$' | sort -u | wc -l | tr -d ' ')
fi

if [[ "$DAYS_AGO" -gt "$SYNC_STALE_DAYS" ]]; then
  MSG="VDK: Knowledge base last synced ${DAYS_AGO} days ago (${LAST_DATE})."
  if [[ "$CHANGED_FILES" -gt 0 ]]; then
    MSG="${MSG} ${CHANGED_FILES} code file(s) changed since then."
  fi
  MSG="${MSG} Suggest running the sync skill to update the knowledge base."
  echo "$MSG"
elif [[ "$CHANGED_FILES" -gt 10 ]]; then
  # Not stale by date, but many files changed — still worth a heads-up
  echo "VDK: Knowledge base was synced ${DAYS_AGO} days ago, but ${CHANGED_FILES} code files changed since then. Consider running the sync skill."
fi

exit 0
