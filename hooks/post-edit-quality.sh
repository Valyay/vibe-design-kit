#!/usr/bin/env bash
# VDK Hook: Run lint, typecheck, and related tests after code edits
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
  QUALITY_LOG="/tmp/vdk-quality-$(printf '%s' "$PROJECT_DIR" | tr '/' '_').log"
  if ! grep -qF "no-pkg-warned" "$QUALITY_LOG" 2>/dev/null; then
    echo "no-pkg-warned" >> "$QUALITY_LOG"
    echo "VDK: No package.json found — quality checks skipped."
    echo "  Add a package.json with 'lint' and 'typecheck' scripts to enable automatic quality gates."
  fi
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

# Detect and run tests for the edited file
run_tests() {
  local pkg="$PROJECT_DIR/package.json"
  local dir; dir=$(dirname "$FILE_PATH")
  local name_no_ext; name_no_ext=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')

  # Find the matching test file (.test. and .spec. conventions)
  local test_file=""
  for candidate in \
    "${dir}/${name_no_ext}.test.ts" \
    "${dir}/${name_no_ext}.test.tsx" \
    "${dir}/${name_no_ext}.test.js" \
    "${dir}/${name_no_ext}.test.jsx" \
    "${dir}/${name_no_ext}.spec.ts" \
    "${dir}/${name_no_ext}.spec.tsx" \
    "${dir}/${name_no_ext}.spec.js" \
    "${dir}/${name_no_ext}.spec.jsx" \
    "${dir}/__tests__/${name_no_ext}.test.ts" \
    "${dir}/__tests__/${name_no_ext}.test.tsx" \
    "${dir}/__tests__/${name_no_ext}.test.js" \
    "${dir}/__tests__/${name_no_ext}.spec.ts" \
    "${dir}/__tests__/${name_no_ext}.spec.tsx" \
    "${dir}/__tests__/${name_no_ext}.spec.js"; do
    if [[ -f "$candidate" ]]; then
      test_file="$candidate"
      break
    fi
  done

  [[ -n "$test_file" ]] || return 0

  local output
  if grep -qE '"vitest"' "$pkg" 2>/dev/null; then
    if output=$(cd "$PROJECT_DIR" && npx vitest run "$test_file" 2>&1); then
      RESULTS="${RESULTS}Tests: passed\n"
    else
      RESULTS="${RESULTS}Tests: failed\n${output}\n"
    fi
  elif grep -qE '"jest"' "$pkg" 2>/dev/null; then
    if output=$(cd "$PROJECT_DIR" && npx jest --passWithNoTests "$test_file" 2>&1); then
      RESULTS="${RESULTS}Tests: passed\n"
    else
      RESULTS="${RESULTS}Tests: failed\n${output}\n"
    fi
  fi
}

run_lint
run_typecheck
run_tests

if [[ -n "$RESULTS" ]]; then
  echo -e "VDK quality check for $(basename "$FILE_PATH"):\n$RESULTS"
else
  QUALITY_LOG="/tmp/vdk-quality-$(printf '%s' "$PROJECT_DIR" | tr '/' '_').log"
  if ! grep -qF "no-tools-warned" "$QUALITY_LOG" 2>/dev/null; then
    echo "no-tools-warned" >> "$QUALITY_LOG"
    echo "VDK: No lint or typecheck tools detected — quality checks skipped."
    echo "  Add a 'lint' script or install ESLint, Biome, or tsc to enable quality gates."
  fi
fi

exit 0
