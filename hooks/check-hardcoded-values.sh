#!/usr/bin/env bash
# VDK Hook: Block hardcoded visual values in UI files
# Trigger: PreToolUse on Edit|Write
# Enforces: "No hardcoded values" rule from CLAUDE.md
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  echo "VDK ERROR: python3 is required for check-hardcoded-values — install python3 to enable token enforcement" >&2
  exit 2
fi

INPUT=$(cat)
if ! FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null); then
  echo "VDK ERROR: check-hardcoded-values failed to parse hook input — blocking as precaution" >&2
  exit 2
fi

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
if ! CONTENT=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('content') or ti.get('new_string') or '')
" 2>/dev/null); then
  echo "VDK ERROR: check-hardcoded-values failed to read file content from hook input — blocking as precaution" >&2
  exit 2
fi

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

VIOLATIONS=""
COLOR_HINTS=""
PX_MATCHES=""
FONT_MATCHES=""

# ── Hardcoded hex colors ──────────────────────────────────
# Match: #rgb, #rgba, #rrggbb, #rrggbbaa — exclude #000, #fff, #000000, #ffffff
HEX_MATCHES=$(echo "$CONTENT" | grep -oE '#[0-9a-fA-F]{3,8}\b' | grep -viE '^#(000|fff|000000|ffffff)$' || true)
if [[ -n "$HEX_MATCHES" ]]; then
  UNIQUE_HEX=$(echo "$HEX_MATCHES" | sort -u | head -5)
  VIOLATIONS="${VIOLATIONS}Hardcoded colors: ${UNIQUE_HEX//$'\n'/, }. "

  # Look up each color in DESIGN.md — suggest the token name or flag as missing
  DESIGN_MD="${CLAUDE_PROJECT_DIR:-.}/DESIGN.md"
  if [[ -f "$DESIGN_MD" ]]; then
    COLOR_HINTS=$(python3 - "$DESIGN_MD" "$(echo "$UNIQUE_HEX" | tr '\n' ',')" <<'PYEOF'
import sys, re
design_path = sys.argv[1]
hex_values = [v.strip() for v in sys.argv[2].split(',') if v.strip()]
try:
    with open(design_path) as f:
        lines = f.readlines()
except Exception:
    sys.exit(0)
for val in hex_values:
    found = False
    for line in lines:
        if val.lower() in line.lower():
            m = re.search(r'`(--[\w-]+)`', line)
            if m:
                print(f'  {val} → var({m.group(1)})')
                found = True
                break
    if not found:
        print(f'  {val} → unknown — add to DESIGN.md? Reply: "yes, add {val} as a token"')
PYEOF
    2>/dev/null || true)
  fi
fi

# ── Hardcoded pixel values ────────────────────────────────
# Skip 0px/1px (common resets), @media breakpoints, and border/outline widths
PX_MATCHES=$(echo "$CONTENT" \
  | grep -v '@media\|min-width\|max-width\|viewport' \
  | grep -v 'border-width\|border-top-width\|border-bottom-width\|border-left-width\|border-right-width\|outline-width' \
  | grep -v 'border:[^;]*[0-9]px\|outline:[^;]*[0-9]px' \
  | grep -oE '[^a-zA-Z_-][2-9][0-9]*px|[^a-zA-Z_-][1-9][0-9]+px' | head -5 || true)
if [[ -n "$PX_MATCHES" ]]; then
  UNIQUE_PX=$(echo "$PX_MATCHES" | sed 's/^[^0-9]*//' | sort -u | head -5)
  VIOLATIONS="${VIOLATIONS}Hardcoded pixel values: ${UNIQUE_PX//$'\n'/, }. "
fi

# ── Hardcoded font-family ─────────────────────────────────
# Covers CSS (font-family:) and CSS-in-JS (fontFamily:)
# Allow: var(), inherit, unset, revert, initial
FONT_MATCHES=$(echo "$CONTENT" \
  | grep -iE "font-family:|fontFamily\s*[:=]" \
  | grep -viE "(font-family|fontFamily)\s*[:=]\s*['\"]?(var\(|inherit|unset|revert|initial)" \
  | head -3 || true)
if [[ -n "$FONT_MATCHES" ]]; then
  VIOLATIONS="${VIOLATIONS}Hardcoded font-family. "
fi

if [[ -n "$VIOLATIONS" ]]; then
  {
    echo "VDK: Hardcoded values in $(basename "$FILE_PATH") — use design tokens instead."
    if [[ -n "$COLOR_HINTS" ]]; then
      echo "  Colors:"
      echo "$COLOR_HINTS"
    fi
    if [[ -n "$PX_MATCHES" ]]; then
      echo "  Pixel values: use spacing/size tokens from DESIGN.md (e.g. var(--space-4))."
    fi
    if [[ -n "$FONT_MATCHES" ]]; then
      echo "  Font-family: use the font token from DESIGN.md (e.g. var(--font-sans))."
    fi
    echo "  If intentional (e.g. a one-off reset), add an inline comment explaining why."
  } >&2

  # Log for recovery report
  RECOVERY_LOG="/tmp/vdk-blocked-$(printf '%s' "${CLAUDE_PROJECT_DIR:-.}" | tr '/' '_').log"
  echo "hardcoded-values|$(date +%s)|${FILE_PATH}|${VIOLATIONS}" >> "$RECOVERY_LOG"

  exit 2
fi

exit 0
