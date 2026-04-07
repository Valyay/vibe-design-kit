#!/usr/bin/env bash
# VDK Hook: Report what was blocked and fixed to the designer
# Trigger: PostToolUse on Edit|Write (async)
# Purpose: Close the feedback loop — designer learns what the AI had to fix
#          so they can write better, more token-aware briefs next time.
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

# Only care about UI files (same scope as check-hardcoded-values)
case "$FILE_PATH" in
  *.tsx|*.jsx|*.ts|*.js|*.css|*.scss|*.less|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

RECOVERY_LOG="/tmp/vdk-blocked-$(printf '%s' "${CLAUDE_PROJECT_DIR:-.}" | tr '/' '_').log"

[[ -f "$RECOVERY_LOG" ]] || exit 0

# Find entries for this file, skip stale ones (older than 1 hour)
NOW_TS=$(date +%s)
MAX_AGE=3600

MATCHES=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  ENTRY_TS=$(echo "$line" | cut -d'|' -f2)
  if [[ -n "$ENTRY_TS" ]] && (( NOW_TS - ENTRY_TS < MAX_AGE )); then
    MATCHES="${MATCHES}${line}"$'\n'
  fi
done < <(grep -F "|${FILE_PATH}|" "$RECOVERY_LOG" 2>/dev/null || true)

# Trim trailing newline
MATCHES="${MATCHES%$'\n'}"

[[ -n "$MATCHES" ]] || exit 0

# Remove matched entries from the log (they've been reported)
# Use PID-suffixed tmp to avoid concurrent async instances clobbering each other
grep -v -F "|${FILE_PATH}|" "$RECOVERY_LOG" > "${RECOVERY_LOG}.tmp.$$" 2>/dev/null || true
mv "${RECOVERY_LOG}.tmp.$$" "$RECOVERY_LOG"

# Collect unique violation descriptions for this file
VIOLATION_DESCRIPTIONS=$(echo "$MATCHES" | cut -d'|' -f4 | sort -u)

format_recovery_message() {
  local file_name="$1"
  local descriptions="$2"

  local bullets="" hints="" matched_count=0

  while IFS= read -r desc; do
    [[ -z "$desc" ]] && continue

    if [[ "$desc" == *"Hardcoded colors"* ]]; then
      local values; values=$(echo "$desc" | grep -oE '#[0-9a-fA-F]{3,8}' | tr '\n' ' ')
      bullets="${bullets}  • The AI replaced hardcoded color(s) ${values}— raw hex values break theming and dark mode.\n"
      hints="${hints}colors: name the role, not the value (e.g. \"brand-primary\", \"text-muted\", \"surface-error\") so the AI picks the right token from DESIGN.md\n"
      (( matched_count++ )) || true
    fi

    if [[ "$desc" == *"Hardcoded pixel"* ]]; then
      local values; values=$(echo "$desc" | grep -oE '[0-9]+px' | tr '\n' ' ')
      bullets="${bullets}  • The AI replaced hardcoded size(s) ${values}— magic numbers drift from the spacing scale.\n"
      hints="${hints}spacing: describe intent instead (e.g. \"comfortable padding\", \"tight gap\", \"section spacing\") so the AI maps to the nearest spacing token\n"
      (( matched_count++ )) || true
    fi

    if [[ "$desc" == *"font-family"* ]]; then
      bullets="${bullets}  • The AI removed a hardcoded font-family declaration — font stacks belong in the token layer.\n"
      hints="${hints}typography: say \"use the heading font\" or \"body text\" and the AI will reference the typeface token in DESIGN.md\n"
      (( matched_count++ )) || true
    fi
  done <<< "$descriptions"

  [[ "$matched_count" -eq 0 ]] && return

  local issue_word="issue"; [[ "$matched_count" -gt 1 ]] && issue_word="issues"
  echo "VDK fixed $matched_count $issue_word in $file_name before writing:"
  printf "%b" "$bullets"

  if [[ -n "$hints" ]]; then
    echo "  Next time, in your brief:"
    printf "%b" "$hints" | grep -v '^$' | while IFS= read -r hint; do
      echo "    → $hint"
    done
  fi
}

format_recovery_message "$(basename "$FILE_PATH")" "$VIOLATION_DESCRIPTIONS"

exit 0
