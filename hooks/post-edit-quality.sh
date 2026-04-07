#!/usr/bin/env bash
# VDK Hook: Run lint + typecheck after code edits
# Trigger: PostToolUse on Edit|Write (async)
# Enforces: "Quality gates" rule from CLAUDE.md
set -euo pipefail

if ! command -v python3 &>/dev/null; then
  echo "VDK: python3 is required for enforcement hooks" >&2
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" || true)

# Only check code files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Need package.json to detect tools
if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
  exit 0
fi

RESULTS=""

# Detect package manager once
detect_runner() {
  local runner="npm run"
  [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]] && runner="pnpm run"
  [[ -f "$PROJECT_DIR/yarn.lock" ]] && runner="yarn run"
  [[ -f "$PROJECT_DIR/bun.lockb" || -f "$PROJECT_DIR/bun.lock" ]] && runner="bun run"
  echo "$runner"
}

RUNNER=$(detect_runner)

# Detect and run linter
run_lint() {
  local pkg="$PROJECT_DIR/package.json"

  # Check for lint script in package.json
  if grep -qE '"lint"\s*:' "$pkg" 2>/dev/null; then
    local output
    if output=$(cd "$PROJECT_DIR" && $RUNNER lint 2>&1); then
      RESULTS="${RESULTS}Lint: passed\n"
    else
      RESULTS="${RESULTS}Lint: issues found\n${output}\n"
    fi
    return
  fi

  # Direct tool detection (no script, but tool exists)
  if grep -qE '"@biomejs/biome"' "$pkg" 2>/dev/null; then
    local output
    if output=$(cd "$PROJECT_DIR" && npx biome check "$FILE_PATH" 2>&1); then
      RESULTS="${RESULTS}Biome: passed\n"
    else
      RESULTS="${RESULTS}Biome: issues found\n${output}\n"
    fi
  elif grep -qE '"eslint"' "$pkg" 2>/dev/null; then
    local output
    if output=$(cd "$PROJECT_DIR" && npx eslint "$FILE_PATH" 2>&1); then
      RESULTS="${RESULTS}ESLint: passed\n"
    else
      RESULTS="${RESULTS}ESLint: issues found\n${output}\n"
    fi
  fi
}

# Detect and run typecheck
run_typecheck() {
  if [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
    local pkg="$PROJECT_DIR/package.json"

    # Check for typecheck script
    if grep -qE '"typecheck"\s*:|"type-check"\s*:' "$pkg" 2>/dev/null; then
      local script="typecheck"
      grep -qE '"type-check"\s*:' "$pkg" 2>/dev/null && script="type-check"

      local output
      if output=$(cd "$PROJECT_DIR" && $RUNNER "$script" 2>&1); then
        RESULTS="${RESULTS}Typecheck: passed\n"
      else
        RESULTS="${RESULTS}Typecheck: issues found\n$(echo "$output" | tail -20)\n"
      fi
      return
    fi

    # Direct tsc
    local output
    if output=$(cd "$PROJECT_DIR" && npx tsc --noEmit 2>&1); then
      RESULTS="${RESULTS}Typecheck: passed\n"
    else
      RESULTS="${RESULTS}Typecheck: issues found\n$(echo "$output" | tail -20)\n"
    fi
  fi
}

run_lint
run_typecheck

if [[ -n "$RESULTS" ]]; then
  echo -e "VDK quality check for $(basename "$FILE_PATH"):\n$RESULTS"
fi

exit 0
