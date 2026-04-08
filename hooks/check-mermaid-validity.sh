#!/usr/bin/env bash
# VDK Hook: Validate Mermaid diagrams in markdown files
# Trigger: PostToolUse on Edit|Write
# Strategy: mmdc (mermaid CLI) if available, Python heuristics as fallback
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  echo "VDK WARNING: python3 is required for check-mermaid-validity — mermaid diagrams will not be validated" >&2
  exit 0
fi

INPUT=$(cat)
if ! FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null); then
  echo "VDK ERROR: check-mermaid-validity failed to parse hook input" >&2
  exit 0
fi

# Only check markdown files
case "$FILE_PATH" in
  *.md|*.mdx) ;;
  *) exit 0 ;;
esac

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# ── Extract mermaid blocks to temp files ──────────────────────────────────────
TMPDIR_BLOCKS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BLOCKS"' EXIT

python3 - "$FILE_PATH" "$TMPDIR_BLOCKS" <<'PYEOF'
import re, sys, os

path, outdir = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()

blocks = re.findall(r'```mermaid\n(.*?)```', content, re.DOTALL)
for i, block in enumerate(blocks):
    with open(os.path.join(outdir, f"block_{i}.mmd"), "w") as f:
        f.write(block)
PYEOF

BLOCK_FILES=("$TMPDIR_BLOCKS"/block_*.mmd)
if [[ ! -e "${BLOCK_FILES[0]}" ]]; then
  exit 0  # no mermaid blocks found
fi

ERRORS=""

# ── Strategy 1: mmdc (official Mermaid CLI) ───────────────────────────────────
MMDC=""
if command -v mmdc &>/dev/null; then
  MMDC="mmdc"
elif command -v npx &>/dev/null && npx --yes @mermaid-js/mermaid-cli --version &>/dev/null 2>&1; then
  MMDC="npx @mermaid-js/mermaid-cli"
fi

if [[ -n "$MMDC" ]]; then
  for block_file in "${BLOCK_FILES[@]}"; do
    block_num=$(basename "$block_file" .mmd | sed 's/block_//')
    out_svg="$TMPDIR_BLOCKS/out_${block_num}.svg"
    if ! mmdc_output=$($MMDC -i "$block_file" -o "$out_svg" 2>&1); then
      # Strip ANSI codes and puppet/chrome noise, keep only parse errors
      clean=$(echo "$mmdc_output" \
        | sed 's/\x1b\[[0-9;]*m//g' \
        | grep -v '^$\|Puppeteer\|Chrome\|chromium\|--no-sandbox\|Running\|Generating' \
        | head -10 || true)
      ERRORS="${ERRORS}Block $((block_num+1)) (mmdc): ${clean}"$'\n'
    fi
  done

# ── Strategy 2: Python heuristics (fallback) ─────────────────────────────────
else
  for block_file in "${BLOCK_FILES[@]}"; do
    block_num=$(basename "$block_file" .mmd | sed 's/block_//')
    block_errors=$(python3 - "$block_file" "$((block_num+1))" <<'PYEOF'
import re, sys

block_file, label = sys.argv[1], sys.argv[2]
with open(block_file) as f:
    block = f.read()

errors = []
RESERVED = {
    'end', 'graph', 'subgraph', 'flowchart', 'direction',
    'LR', 'RL', 'TB', 'BT', 'TD', 'click', 'style',
    'classDef', 'class', 'linkStyle',
}

# Subgraph IDs
subgraph_ids = {m.group(1) for m in re.finditer(r'^\s*subgraph\s+(\w+)', block, re.MULTILINE)}

# Node IDs (indented, non-keyword lines)
node_ids = set()
for m in re.finditer(r'^[ \t]{2,}(\w+)(?:[ \t]*[\[\(\{>].*)?$', block, re.MULTILINE):
    nid = m.group(1)
    if nid not in RESERVED:
        node_ids.add(nid)

# ID conflicts
for c in sorted(subgraph_ids & node_ids):
    errors.append(
        f"Block {label}: ID conflict — '{c}' is both a subgraph ID and a node ID. "
        f"Rename the subgraph (e.g. '{c}Group') or the node (e.g. '{c}Component')."
    )

# Reserved keywords as node IDs
for r in sorted(nid for nid in node_ids if nid.lower() in {x.lower() for x in RESERVED}):
    errors.append(f"Block {label}: Reserved keyword '{r}' used as node ID — rename it.")

# Unclosed subgraphs
opens = len(re.findall(r'^\s*subgraph\b', block, re.MULTILINE))
closes = len(re.findall(r'^\s*end\b', block, re.MULTILINE))
if opens != closes:
    errors.append(
        f"Block {label}: {opens} subgraph(s) but {closes} end(s) — "
        f"every subgraph must be closed with 'end'."
    )

for e in errors:
    print(e)
PYEOF
    ) || true
    ERRORS="${ERRORS}${block_errors}"
  done
fi

# ── Report ────────────────────────────────────────────────────────────────────
ERRORS=$(echo "$ERRORS" | sed '/^[[:space:]]*$/d' || true)

if [[ -n "$ERRORS" ]]; then
  {
    echo "VDK: Invalid Mermaid diagram in $(basename "$FILE_PATH") — diagram will not render:"
    while IFS= read -r line; do
      echo "  $line"
    done <<< "$ERRORS"
    echo "  Fix the errors above so the diagram renders on mermaid.live and in editors."
  } >&2
  exit 2
fi

exit 0
