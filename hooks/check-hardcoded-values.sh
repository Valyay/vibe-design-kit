#!/usr/bin/env bash
# VDK Hook: Block hardcoded visual values in UI files
# Trigger: PreToolUse on Edit|Write
# Enforces: "No hardcoded values" rule from CLAUDE.md
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "VDK: jq is required for enforcement hooks. Install with: brew install jq" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check UI-related files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.ts|*.js|*.css|*.scss|*.less|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

# Skip test files, stories, config files, and design token definitions
case "$FILE_PATH" in
  *.test.*|*.spec.*|*.stories.*|*.story.*) exit 0 ;;
  *tailwind.config*|*/theme.ts|*/theme.js|*/theme/index.*|*/tokens*|*DESIGN.md) exit 0 ;;
  *.config.*|*postcss*|*vite*|*next.config*|*nuxt.config*) exit 0 ;;
esac

# Get the content being written/edited
CONTENT=""
if echo "$INPUT" | jq -e '.tool_input.content' > /dev/null 2>&1; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content')
elif echo "$INPUT" | jq -e '.tool_input.new_string' > /dev/null 2>&1; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string')
fi

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

VIOLATIONS=""

# Check for hardcoded hex colors (but allow common CSS like #000, #fff, transparent, inherit)
# Match: #rgb, #rgba, #rrggbb, #rrggbbaa — exclude #000, #fff, #000000, #ffffff
HEX_MATCHES=$(echo "$CONTENT" | grep -oE '#[0-9a-fA-F]{3,8}\b' | grep -viE '^#(000|fff|000000|ffffff)$' || true)
if [[ -n "$HEX_MATCHES" ]]; then
  UNIQUE_HEX=$(echo "$HEX_MATCHES" | sort -u | head -5)
  VIOLATIONS="${VIOLATIONS}Hardcoded colors found: ${UNIQUE_HEX//$'\n'/, }. "
fi

# Check for hardcoded pixel values in style contexts (skip 0px, 1px which are common resets)
# Exclude @media queries and viewport declarations — breakpoints are legitimately hardcoded
PX_MATCHES=$(echo "$CONTENT" | grep -v '@media\|min-width\|max-width\|viewport\|border.*px\|outline.*px' | grep -oE '[^a-zA-Z_-][2-9][0-9]*px|[^a-zA-Z_-][1-9][0-9]+px' | head -5 || true)
if [[ -n "$PX_MATCHES" ]]; then
  UNIQUE_PX=$(echo "$PX_MATCHES" | sed 's/^[^0-9]*//' | sort -u | head -5)
  VIOLATIONS="${VIOLATIONS}Hardcoded pixel values found: ${UNIQUE_PX//$'\n'/, }. "
fi

# Check for hardcoded font-family declarations (outside of token/config files)
# Covers both CSS (font-family:) and CSS-in-JS (fontFamily:/"fontFamily"=)
# Allow: var(), inherit, unset, revert, initial — these are correct CSS usage
FONT_MATCHES=$(echo "$CONTENT" | grep -iE "font-family:|fontFamily\s*[:=]" | grep -viE "(font-family|fontFamily)\s*[:=]\s*['\"]?(var\(|inherit|unset|revert|initial)" | head -3 || true)
if [[ -n "$FONT_MATCHES" ]]; then
  VIOLATIONS="${VIOLATIONS}Hardcoded font-family found. "
fi

if [[ -n "$VIOLATIONS" ]]; then
  echo "VDK: ${VIOLATIONS}Use design tokens from DESIGN.md or the project's token system instead. If this is intentional (e.g. a one-off reset), add a comment explaining why." >&2
  exit 2
fi

exit 0
