#!/usr/bin/env bash
# check-wikilinks.sh — Validate [[wiki-links]] in KB vault files
# Usage:
#   CLI mode:  bash check-wikilinks.sh <vault-dir>
#   Hook mode: CLAUDE_PROJECT_DIR=<project> bash check-wikilinks.sh
# Checks that [[file]] targets exist and [[file#heading]] headings exist.
# CLI mode: exit 1 if broken links found. Hook mode: always exit 0 (non-blocking).
set -euo pipefail

VAULT_DIR="${1:-}"
HOOK_MODE=false

# If no positional arg, try hook mode via CLAUDE_PROJECT_DIR
if [[ -z "$VAULT_DIR" ]]; then
  HOOK_MODE=true
  PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

  # Find KB directory (same pattern as other hooks)
  VAULT_DIR=$(find "$PROJECT_DIR" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -path "*/dist" -prune -o -path "*/build" -prune -o \
    -path "*/design-knowledge/*/_index.md" -not -path "*/_project-template/*" -print 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)

  [[ -n "$VAULT_DIR" ]] || exit 0
fi

if [[ ! -d "$VAULT_DIR" ]]; then
  echo "Usage: check-wikilinks.sh <vault-dir>" >&2
  exit 2
fi

BROKEN_COUNT=0
BROKEN_DETAILS=""

# Scan all .md files for [[...]] wiki-links
while IFS= read -r md_file; do
  # Strip HTML comments, then extract [[target]] patterns
  content=$(sed 's/<!--[^>]*-->//g' "$md_file" 2>/dev/null || true)
  links=$(echo "$content" | grep -oE '\[\[[^]]+\]\]' 2>/dev/null || true)
  [[ -z "$links" ]] && continue

  while IFS= read -r match; do
    # Strip [[ and ]]
    target="${match:2:${#match}-4}"
    [[ -z "$target" ]] && continue

    # Split on # → file_part and optional section_part
    file_part="${target%%#*}"
    section_part=""
    if [[ "$target" == *"#"* ]]; then
      section_part="${target#*#}"
    fi

    # Skip empty file part
    [[ -z "$file_part" ]] && continue

    # Resolve: try file_part.md, then file_part as-is
    target_file=""
    if [[ -f "$VAULT_DIR/$file_part.md" ]]; then
      target_file="$VAULT_DIR/$file_part.md"
    elif [[ -f "$VAULT_DIR/$file_part" ]]; then
      target_file="$VAULT_DIR/$file_part"
    fi

    if [[ -z "$target_file" ]]; then
      BROKEN_COUNT=$((BROKEN_COUNT + 1))
      BROKEN_DETAILS="${BROKEN_DETAILS}\n  - $(basename "$md_file"): [[${target}]] → file not found"
    elif [[ -n "$section_part" ]]; then
      # Check if heading exists — two-step to avoid regex metacharacter issues:
      # 1. Extract heading lines with a safe pattern (no user input in regex)
      # 2. Fixed-string match against section_part (treats + ( ) [ ] etc. as literals)
      if ! grep -iE "^#{1,6} " "$target_file" 2>/dev/null | grep -qiF "$section_part"; then
        BROKEN_COUNT=$((BROKEN_COUNT + 1))
        BROKEN_DETAILS="${BROKEN_DETAILS}\n  - $(basename "$md_file"): [[${target}]] → heading not found"
      fi
    fi
  done <<< "$links"
done < <(find "$VAULT_DIR" -name '*.md' -type f)

if [[ "$BROKEN_COUNT" -gt 0 ]]; then
  if [[ "$HOOK_MODE" == true ]]; then
    echo "VDK: ${BROKEN_COUNT} broken wiki-link(s) in knowledge base:"
    echo -e "$BROKEN_DETAILS"
    echo "Consider running vdk-kb-lint to fix these."
    exit 0
  else
    echo "Broken wiki-link(s): ${BROKEN_COUNT}" >&2
    echo -e "$BROKEN_DETAILS" >&2
    exit 1
  fi
fi

exit 0
