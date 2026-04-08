#!/usr/bin/env bash
# VDK Hook: Unified session start report
# Trigger: SessionStart
# Combines: vault freshness, code drift, broken wiki-links, pending annotations
# All checks are non-blocking — always exits 0.
set -euo pipefail

SYNC_STALE_DAYS="${SYNC_STALE_DAYS:-7}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# ── Locate knowledge base ─────────────────────────────────────────────────────
KB_DIR=$(find "$PROJECT_DIR" \
  -path "*/node_modules" -prune -o -path "*/.git" -prune \
  -o -path "*/dist" -prune -o -path "*/build" -prune \
  -o -path "*/design-knowledge/*/_index.md" \
     -not -path "*/_project-template/*" -print \
  2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)

if [[ -z "$KB_DIR" ]]; then
  echo "VDK ─────────────────────────────────────────"
  echo "  knowledge base    not found"
  echo "─────────────────────────────────────────────"
  echo "  → run the onboarding skill before starting work"
  echo "    until then the AI has no knowledge of your design"
  echo "    system, components, or user flows"
  exit 0
fi

SYNC_LOG="$KB_DIR/_sync-log.md"
NOW_TS=$(date "+%s")

# ── Helpers ───────────────────────────────────────────────────────────────────
LINES=""
SUGGESTIONS=""

add_ok()   { LINES="${LINES}  $(printf '%-14s' "$1") ✓  $2\n"; }
add_warn() { LINES="${LINES}  $(printf '%-14s' "$1") ⚠  $2\n"; }
add_info() { LINES="${LINES}  $(printf '%-14s' "$1") ·  $2\n"; }
suggest()  { SUGGESTIONS="${SUGGESTIONS}  → $1\n"; }

ts_from_date() {
  local d="$1"
  local ts
  if ts=$(date -j -f "%Y-%m-%d" "$d" "+%s" 2>/dev/null); then
    echo "$ts"
  elif ts=$(date -d "$d" "+%s" 2>/dev/null); then
    echo "$ts"
  else
    return 1  # signal parse failure — caller must handle
  fi
}

# ── 1. Vault freshness ────────────────────────────────────────────────────────
LAST_DATE=""
if [[ -f "$SYNC_LOG" ]]; then
  LAST_DATE=$(grep -oE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$SYNC_LOG" 2>/dev/null \
    | head -1 | sed 's/^## //' || true)
fi

if [[ -z "$LAST_DATE" ]]; then
  add_warn "vault" "never synced"
  suggest "run the sync skill to populate the knowledge base"
elif ! LAST_TS=$(ts_from_date "$LAST_DATE"); then
  add_warn "vault" "unreadable sync date '${LAST_DATE}' — run sync to reset"
  suggest "sync date in _sync-log.md cannot be parsed — run sync skill to reset it"
else
  DAYS_AGO=$(( (NOW_TS - LAST_TS) / 86400 ))
  if [[ "$DAYS_AGO" -gt "$SYNC_STALE_DAYS" ]]; then
    add_warn "vault" "last sync ${DAYS_AGO}d ago (${LAST_DATE})"
    suggest "run the sync skill — knowledge base is stale (${DAYS_AGO}d)"
  else
    add_ok "vault" "last sync ${DAYS_AGO}d ago (${LAST_DATE})"
  fi
fi

# ── 2. Code drift since last sync ─────────────────────────────────────────────
CHANGED_FILES=0
CHANGED_SAMPLE=""
if [[ -n "$LAST_DATE" ]] \
   && command -v git &>/dev/null \
   && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then

  CHANGED_FILES=$(git -C "$PROJECT_DIR" log --since="$LAST_DATE" \
    --diff-filter=ACDMR --name-only --pretty=format: -- \
    '*.tsx' '*.jsx' '*.ts' '*.js' '*.vue' '*.svelte' '*.css' '*.scss' \
    2>/dev/null | grep -v '^$' | sort -u | wc -l | tr -d ' ')

  if [[ "$CHANGED_FILES" -gt 0 ]]; then
    CHANGED_SAMPLE=$(git -C "$PROJECT_DIR" log --since="$LAST_DATE" \
      --diff-filter=ACDMR --name-only --pretty=format: -- \
      '*.tsx' '*.jsx' '*.ts' '*.js' '*.vue' '*.svelte' '*.css' '*.scss' \
      2>/dev/null | grep -v '^$' | sort -u | head -3 \
      | while IFS= read -r f; do basename "$f" | sed 's/\.[^.]*$//'; done \
      | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
  fi
fi

if [[ "$CHANGED_FILES" -gt 10 ]]; then
  add_warn "code drift" "${CHANGED_FILES} UI files changed since sync${CHANGED_SAMPLE:+ (e.g. ${CHANGED_SAMPLE}, …)}"
  suggest "KB may be outdated — ${CHANGED_FILES} UI files changed; consider running sync"
elif [[ "$CHANGED_FILES" -gt 0 ]]; then
  add_info "code drift" "${CHANGED_FILES} files changed${CHANGED_SAMPLE:+ (${CHANGED_SAMPLE})}"
else
  add_ok "code drift" "no UI changes since last sync"
fi

# ── 3. Broken wiki-links ──────────────────────────────────────────────────────
BROKEN_LINKS=0
BROKEN_IN=""
while IFS= read -r md_file; do
  content=$(sed 's/<!--[^>]*-->//g' "$md_file" 2>/dev/null || true)
  links=$(echo "$content" | grep -oE '\[\[[^]]+\]\]' 2>/dev/null || true)
  [[ -z "$links" ]] && continue
  file_broken=0
  while IFS= read -r match; do
    target="${match:2:${#match}-4}"
    [[ -z "$target" ]] && continue
    file_part="${target%%#*}"
    [[ -z "$file_part" ]] && continue
    if [[ ! -f "$KB_DIR/$file_part.md" ]] && [[ ! -f "$KB_DIR/$file_part" ]]; then
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
      file_broken=1
    fi
  done <<< "$links"
  [[ "$file_broken" -eq 1 ]] && BROKEN_IN="${BROKEN_IN} $(basename "$md_file")"
done < <(find "$KB_DIR" -name '*.md' -type f 2>/dev/null)

if [[ "$BROKEN_LINKS" -gt 0 ]]; then
  add_warn "wiki-links" "${BROKEN_LINKS} broken in${BROKEN_IN} — run vdk-kb-lint"
  suggest "fix ${BROKEN_LINKS} broken wiki-link(s): run vdk-kb-lint"
else
  add_ok "wiki-links" "all links valid"
fi

# ── 4. Pending annotations ────────────────────────────────────────────────────
# @audit / @todo / @review / <!-- TODO --> markers left in KB docs
PENDING_COUNT=0
PENDING_IN=""
while IFS= read -r md_file; do
  count=$(grep -cE '@audit|@todo|@review|<!-- ?TODO|<!-- ?FIXME' "$md_file" 2>/dev/null || true)
  [[ "$count" -gt 0 ]] || continue
  PENDING_COUNT=$((PENDING_COUNT + count))
  PENDING_IN="${PENDING_IN} $(basename "$md_file")"
done < <(find "$KB_DIR" -name '*.md' -type f 2>/dev/null)

if [[ "$PENDING_COUNT" -gt 0 ]]; then
  add_info "annotations" "${PENDING_COUNT} pending in${PENDING_IN}"
else
  add_ok "annotations" "none pending"
fi

# ── Output ────────────────────────────────────────────────────────────────────
echo "VDK ─────────────────────────────────────────"
printf "%b" "$LINES"
echo "─────────────────────────────────────────────"
[[ -n "$SUGGESTIONS" ]] && printf "%b" "$SUGGESTIONS"

exit 0
