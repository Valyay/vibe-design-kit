#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# Vibe Design Kit — Brownfield Setup
#
# Usage: ./setup.sh /path/to/client-repo project-name
#
# What it does:
#   1. Copies CLAUDE.md rules (root + folder-level)
#   2. Creates DESIGN.md template
#   3. Detects and bootstraps quality infrastructure
#   4. Detects or installs Storybook
#   5. Installs Claude Code skills and plugins
#   6. Creates Obsidian vault from template
#   7. Creates briefs/ directory
#   8. Copies ready-made prompts
#   9. Captures baseline (screenshots, test results)
# ─────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
SKILLS_DIR="$SCRIPT_DIR/skills"
VAULT_TEMPLATE_DIR="$SCRIPT_DIR/obsidian-vault-template"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
TOTAL_STEPS=9

# ── Argument parsing ─────────────────────────────────────

if [[ $# -lt 2 ]]; then
  echo "Usage: ./setup.sh /path/to/client-repo project-name"
  echo ""
  echo "Arguments:"
  echo "  /path/to/client-repo   Path to the existing client repository"
  echo "  project-name           Name for the project (used for Obsidian vault)"
  exit 1
fi

if [[ ! -d "$1" ]]; then
  echo "Error: Target directory does not exist: $1"
  exit 1
fi

TARGET_REPO="$(cd "$1" && pwd)"
PROJECT_NAME="$2"

# Validate project name (safe for directory names)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  echo "Error: Project name must be alphanumeric (hyphens, underscores, dots allowed): $PROJECT_NAME"
  exit 1
fi

if [[ ! -d "$TARGET_REPO/.git" ]]; then
  echo "Warning: Target directory is not a git repository: $TARGET_REPO"
  read -rp "Continue anyway? (y/N) " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
fi

# ── Detect package manager ───────────────────────────────

detect_pkg_manager() {
  if [[ -f "$TARGET_REPO/pnpm-lock.yaml" ]]; then
    echo "pnpm"
  elif [[ -f "$TARGET_REPO/yarn.lock" ]]; then
    echo "yarn"
  elif [[ -f "$TARGET_REPO/bun.lockb" ]] || [[ -f "$TARGET_REPO/bun.lock" ]]; then
    echo "bun"
  elif [[ -f "$TARGET_REPO/package-lock.json" ]]; then
    echo "npm"
  else
    echo "npm"
  fi
}

PKG_MANAGER="$(detect_pkg_manager)"
PKG_RUN="$PKG_MANAGER run"

# Helper to run package install
pkg_add() {
  local flags="$1"
  shift
  case "$PKG_MANAGER" in
    pnpm) pnpm add $flags "$@" ;;
    yarn) yarn add $flags "$@" ;;
    bun)  bun add $flags "$@" ;;
    npm)  npm install $flags "$@" ;;
  esac
}

echo "╔══════════════════════════════════════════════════╗"
echo "║         Vibe Design Kit — Brownfield Setup       ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Target:  $TARGET_REPO"
echo "║  Project: $PROJECT_NAME"
echo "║  Package: $PKG_MANAGER"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Helpers ──────────────────────────────────────────────

copy_if_not_exists() {
  local src="$1"
  local dest="$2"
  if [[ -f "$dest" ]]; then
    echo "  ⏭  Already exists: $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✓  Created: $dest"
  fi
}

has_dependency() {
  local dep="$1"
  grep -qE "\"$dep\"\\s*:" "$TARGET_REPO/package.json" 2>/dev/null
}

has_script() {
  local script="$1"
  grep -qE "\"$script\"\\s*:" "$TARGET_REPO/package.json" 2>/dev/null
}

# ── Step 1: Copy CLAUDE.md rules ────────────────────────

echo "▸ Step 1/$TOTAL_STEPS: Copying CLAUDE.md rules..."

copy_if_not_exists "$TEMPLATES_DIR/CLAUDE.md" "$TARGET_REPO/CLAUDE.md"

for template in "$TEMPLATES_DIR"/*--CLAUDE.md; do
  [[ -f "$template" ]] || continue
  basename="$(basename "$template")"
  folder_path="${basename%%--CLAUDE.md}"
  dest="$TARGET_REPO/$folder_path/CLAUDE.md"
  copy_if_not_exists "$template" "$dest"
done

echo ""

# ── Step 2: Create DESIGN.md ────────────────────────────

echo "▸ Step 2/$TOTAL_STEPS: Creating DESIGN.md..."
copy_if_not_exists "$TEMPLATES_DIR/DESIGN.md" "$TARGET_REPO/DESIGN.md"
echo ""

# ── Step 3: Quality infrastructure ──────────────────────

echo "▸ Step 3/$TOTAL_STEPS: Checking quality infrastructure..."

if [[ ! -f "$TARGET_REPO/package.json" ]]; then
  echo "  ⚠  No package.json found. Skipping quality checks."
else
  # ── Linter detection ──────────────────────────────────

  LINTER_FOUND=""

  detect_linter() {
    local name="$1"
    shift
    # Check dependencies and config files
    for check in "$@"; do
      if [[ "$check" == dep:* ]]; then
        has_dependency "${check#dep:}" && { LINTER_FOUND="$name"; return 0; }
      elif [[ -f "$TARGET_REPO/$check" ]] || [[ -d "$TARGET_REPO/$check" ]]; then
        LINTER_FOUND="$name"; return 0
      fi
    done
    return 1
  }

  echo "  Linter:"
  if   detect_linter "Biome"       "dep:@biomejs/biome" "biome.json" "biome.jsonc"; then true
  elif detect_linter "oxlint"      "dep:oxlint" ".oxlintrc.json"; then true
  elif detect_linter "ESLint"      "dep:eslint" ".eslintrc.js" ".eslintrc.json" ".eslintrc.cjs" ".eslintrc.yml" "eslint.config.js" "eslint.config.mjs" "eslint.config.ts"; then true
  elif detect_linter "standard"    "dep:standard"; then true
  elif detect_linter "xo"          "dep:xo"; then true
  elif detect_linter "quick-lint-js" "dep:quick-lint-js"; then true
  elif detect_linter "deno"        "deno.json" "deno.jsonc"; then true
  fi

  if [[ -n "$LINTER_FOUND" ]]; then
    echo "    ✓  $LINTER_FOUND"
  else
    echo "    ✗  None found"
  fi

  # ── Formatter detection ───────────────────────────────

  FORMATTER_FOUND=""

  detect_formatter() {
    local name="$1"
    shift
    for check in "$@"; do
      if [[ "$check" == dep:* ]]; then
        has_dependency "${check#dep:}" && { FORMATTER_FOUND="$name"; return 0; }
      elif [[ -f "$TARGET_REPO/$check" ]]; then
        FORMATTER_FOUND="$name"; return 0
      fi
    done
    return 1
  }

  echo "  Formatter:"
  # Biome is also a formatter — if already detected as linter, count it
  if [[ "$LINTER_FOUND" == "Biome" ]]; then
    FORMATTER_FOUND="Biome"
  elif detect_formatter "Prettier"  "dep:prettier" ".prettierrc" ".prettierrc.json" ".prettierrc.js" ".prettierrc.cjs" ".prettierrc.yml" "prettier.config.js" "prettier.config.mjs" "prettier.config.ts"; then true
  elif detect_formatter "dprint"    "dep:dprint" "dprint.json" ".dprint.json"; then true
  elif detect_formatter "deno"      "deno.json" "deno.jsonc"; then true
  fi

  if [[ -n "$FORMATTER_FOUND" ]]; then
    echo "    ✓  $FORMATTER_FOUND"
  else
    echo "    ✗  None found"
  fi

  # ── CSS linter detection ──────────────────────────────

  CSS_LINTER_FOUND=""

  echo "  CSS linter:"
  if has_dependency "stylelint" || [[ -f "$TARGET_REPO/.stylelintrc" ]] || [[ -f "$TARGET_REPO/.stylelintrc.json" ]] || [[ -f "$TARGET_REPO/stylelint.config.js" ]] || [[ -f "$TARGET_REPO/stylelint.config.mjs" ]]; then
    CSS_LINTER_FOUND="stylelint"
    echo "    ✓  stylelint"
  elif [[ "$LINTER_FOUND" == "Biome" ]]; then
    CSS_LINTER_FOUND="Biome"
    echo "    ✓  Biome (covers CSS)"
  else
    echo "    ⏭  None (optional)"
  fi

  # ── Type checker detection ────────────────────────────

  TYPECHECKER_FOUND=""

  echo "  Type checker:"
  if has_dependency "typescript" || [[ -f "$TARGET_REPO/tsconfig.json" ]]; then
    TYPECHECKER_FOUND="typescript"
    echo "    ✓  TypeScript"
  else
    echo "    ✗  None found"
  fi

  # ── Test runner detection ─────────────────────────────

  TEST_RUNNER_FOUND=""

  echo "  Test runner:"
  if   has_dependency "vitest";   then TEST_RUNNER_FOUND="vitest";   echo "    ✓  Vitest"
  elif has_dependency "jest";     then TEST_RUNNER_FOUND="jest";     echo "    ✓  Jest"
  elif has_dependency "mocha";    then TEST_RUNNER_FOUND="mocha";    echo "    ✓  Mocha"
  elif has_dependency "ava";      then TEST_RUNNER_FOUND="ava";      echo "    ✓  AVA"
  elif [[ "$PKG_MANAGER" == "bun" ]] && has_script "test"; then TEST_RUNNER_FOUND="bun"; echo "    ✓  Bun (built-in test runner)"
  elif [[ -f "$TARGET_REPO/deno.json" ]]; then TEST_RUNNER_FOUND="deno"; echo "    ✓  Deno (built-in test runner)"
  else echo "    ✗  None found"
  fi

  # ── E2E detection ─────────────────────────────────────

  E2E_FOUND=""

  echo "  E2E framework:"
  if   has_dependency "@playwright/test" || [[ -f "$TARGET_REPO/playwright.config.ts" ]] || [[ -f "$TARGET_REPO/playwright.config.js" ]]; then
    E2E_FOUND="playwright"; echo "    ✓  Playwright"
  elif has_dependency "cypress" || [[ -f "$TARGET_REPO/cypress.config.ts" ]] || [[ -f "$TARGET_REPO/cypress.config.js" ]]; then
    E2E_FOUND="cypress"; echo "    ✓  Cypress"
  else
    echo "    ✗  None found"
  fi

  # ── Pre-commit hooks detection ────────────────────────

  HOOKS_FOUND=""

  echo "  Pre-commit hooks:"
  if   has_dependency "husky" || [[ -d "$TARGET_REPO/.husky" ]];        then HOOKS_FOUND="husky";    echo "    ✓  Husky"
  elif has_dependency "lefthook" || [[ -f "$TARGET_REPO/lefthook.yml" ]]; then HOOKS_FOUND="lefthook"; echo "    ✓  Lefthook"
  elif has_dependency "lint-staged";                                       then HOOKS_FOUND="lint-staged"; echo "    ✓  lint-staged"
  elif [[ -f "$TARGET_REPO/.pre-commit-config.yaml" ]];                   then HOOKS_FOUND="pre-commit"; echo "    ✓  pre-commit"
  else echo "    ✗  None found"
  fi

  # ── Summary and offer to install missing ──────────────

  MISSING_QUALITY=()

  [[ -z "$LINTER_FOUND" ]]      && MISSING_QUALITY+=("linter")
  [[ -z "$FORMATTER_FOUND" ]]   && MISSING_QUALITY+=("formatter")
  [[ -z "$TYPECHECKER_FOUND" ]] && MISSING_QUALITY+=("typescript")
  [[ -z "$TEST_RUNNER_FOUND" ]] && MISSING_QUALITY+=("test-runner")
  [[ -z "$E2E_FOUND" ]]         && MISSING_QUALITY+=("e2e")
  [[ -z "$HOOKS_FOUND" ]]       && MISSING_QUALITY+=("hooks")

  if [[ ${#MISSING_QUALITY[@]} -gt 0 ]]; then
    echo ""
    echo "  Missing: ${MISSING_QUALITY[*]}"
    read -rp "  Install missing tools? (y/N) " install_quality

    if [[ "$install_quality" =~ ^[Yy]$ ]]; then
      local _saved_dir="$PWD"
      cd "$TARGET_REPO"

      for tool in "${MISSING_QUALITY[@]}"; do
        case "$tool" in
          linter)
            echo "  Installing Biome (fast linter + formatter)..."
            pkg_add "--save-dev" "@biomejs/biome" \
              && { LINTER_FOUND="Biome"; FORMATTER_FOUND="Biome"; echo "  ✓  Biome installed"; } \
              || echo "  ⚠  Biome install failed"
            ;;
          formatter)
            # Skip if Biome was just installed (it covers formatting)
            if [[ "$LINTER_FOUND" == "Biome" ]]; then
              echo "  ⏭  Biome covers formatting"
            else
              echo "  Installing Prettier..."
              pkg_add "--save-dev" "prettier" && echo "  ✓  Prettier installed" || echo "  ⚠  Prettier install failed"
            fi
            ;;
          typescript)
            echo "  Installing TypeScript..."
            pkg_add "--save-dev" "typescript" && echo "  ✓  TypeScript installed" || echo "  ⚠  TypeScript install failed"
            ;;
          test-runner)
            echo "  Installing Vitest..."
            pkg_add "--save-dev" "vitest" && echo "  ✓  Vitest installed" || echo "  ⚠  Vitest install failed"
            ;;
          e2e)
            echo "  Installing Playwright..."
            pkg_add "--save-dev" "@playwright/test" && npx playwright install --with-deps chromium 2>/dev/null \
              && echo "  ✓  Playwright installed" || echo "  ⚠  Playwright install failed"
            ;;
          hooks)
            echo "  Installing Husky + lint-staged..."
            pkg_add "--save-dev" "husky" "lint-staged" && npx husky init 2>/dev/null \
              && echo "  ✓  Husky installed" || echo "  ⚠  Husky install failed"
            ;;
        esac
      done

      cd "$_saved_dir"
    else
      echo "  Skipped. You can install them later."
    fi
  fi
fi

echo ""

# ── Step 4: Storybook ──────────────────────────────────

echo "▸ Step 4/$TOTAL_STEPS: Checking Storybook..."

if has_dependency "storybook" || has_dependency "@storybook/react" || [[ -d "$TARGET_REPO/.storybook" ]]; then
  echo "  ✓  Storybook detected"
  echo "  Onboarding will use Storybook for component screenshots"
else
  echo "  ✗  Storybook not found"
  echo ""
  echo "  Storybook gives designers a visual component catalog —"
  echo "  every component with its variants, states, and props."
  echo "  Without it, the onboarding can only screenshot full pages."
  echo ""
  read -rp "  Install Storybook? (y/N) " install_sb

  if [[ "$install_sb" =~ ^[Yy]$ ]]; then
    echo "  Installing Storybook (this may take a minute)..."
    (cd "$TARGET_REPO" && npx storybook@latest init --yes 2>/dev/null) \
      && echo "  ✓  Storybook installed" \
      || echo "  ⚠  Storybook auto-install failed. Run manually: cd $TARGET_REPO && npx storybook@latest init"
  else
    echo "  Skipped. You can install it later with: npx storybook@latest init"
  fi
fi

echo ""

# ── Step 5: Claude Code skills and plugins ──────────────

echo "▸ Step 5/$TOTAL_STEPS: Installing skills, plugins, and MCP servers..."

# ── Copy custom skills (onboarding, sync) ────────────────
echo ""
echo "  Custom skills (unique to vibe-design-kit):"
for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  dest_skill="$TARGET_REPO/.claude/skills/$skill_name"
  if [[ -d "$dest_skill" ]]; then
    echo "    ⏭  $skill_name (already exists)"
  else
    mkdir -p "$dest_skill"
    cp "$skill_dir"SKILL.md "$dest_skill/SKILL.md"
    echo "    ✓  $skill_name"
  fi
done

# ── External skills and plugins ──────────────────────────
echo ""
echo "  External skills and plugins:"

if command -v claude &> /dev/null; then
  # superpowers — TDD, planning, code review, debugging
  echo "    Installing superpowers (TDD, planning, code review)..."
  (cd "$TARGET_REPO" && claude plugin add obra/superpowers 2>/dev/null) \
    && echo "    ✓  superpowers" \
    || echo "    ⚠  superpowers: claude plugin add obra/superpowers"

  # code-review-graph — knowledge graph for duplicate detection
  echo "    Installing code-review-graph..."
  (cd "$TARGET_REPO" && claude plugin add tirth8205/code-review-graph 2>/dev/null) \
    && echo "    ✓  code-review-graph" \
    || echo "    ⚠  code-review-graph: claude plugin add tirth8205/code-review-graph"

  # tdd-guard — enforce test-first
  echo "    Installing tdd-guard..."
  (cd "$TARGET_REPO" && claude plugin add nizos/tdd-guard 2>/dev/null) \
    && echo "    ✓  tdd-guard" \
    || echo "    ⚠  tdd-guard: claude plugin add nizos/tdd-guard"

else
  echo "    ⚠  Claude CLI not found. Install manually after installing Claude Code."
  echo "    See recommended-tools.md for the full list."
fi

# ── Design quality skills ─────────────────────────────────
echo ""
echo "  Design quality skills:"

echo "    Installing impeccable (typography, color, spatial design, motion)..."
(cd "$TARGET_REPO" && npx skills add pbakaus/impeccable 2>/dev/null) \
  && echo "    ✓  impeccable" \
  || echo "    ⚠  impeccable: npx skills add pbakaus/impeccable"

echo "    Installing web-design-guidelines (100+ UI quality rules)..."
(cd "$TARGET_REPO" && npx skills add vercel-labs/agent-skills --skill web-design-guidelines -a claude-code 2>/dev/null) \
  && echo "    ✓  web-design-guidelines" \
  || echo "    ⚠  web-design-guidelines: npx skills add vercel-labs/agent-skills --skill web-design-guidelines -a claude-code"

echo "    Installing frontend-design (anti-AI-slop, distinctive visuals)..."
(cd "$TARGET_REPO" && npx skills add anthropics/skills --skill frontend-design -a claude-code 2>/dev/null) \
  && echo "    ✓  frontend-design" \
  || echo "    ⚠  frontend-design: npx skills add anthropics/skills --skill frontend-design -a claude-code"

# ── Testing skills ───────────────────────────────────────
echo ""
echo "  Testing skills:"

echo "    Installing playwright-skill (70+ E2E testing guides)..."
(cd "$TARGET_REPO" && npx skills add testdino-hq/playwright-skill 2>/dev/null) \
  && echo "    ✓  playwright-skill" \
  || echo "    ⚠  playwright-skill: npx skills add testdino-hq/playwright-skill"

# Vitest skill — only if the project uses vitest
if has_dependency "vitest"; then
  echo "    Installing vitest-skill..."
  (cd "$TARGET_REPO" && claude plugin add jezweb/claude-skills 2>/dev/null) \
    && echo "    ✓  vitest-skill" \
    || echo "    ⚠  vitest-skill: claude plugin add jezweb/claude-skills"
fi

# ── Framework-specific skills ────────────────────────────
echo ""
echo "  Framework-specific skills:"

# React-specific
if has_dependency "react" || has_dependency "next"; then
  echo "    Installing react-best-practices..."
  (cd "$TARGET_REPO" && npx skills add vercel-labs/agent-skills --skill react-best-practices -a claude-code 2>/dev/null) \
    && echo "    ✓  react-best-practices" \
    || echo "    ⚠  react-best-practices: npx skills add vercel-labs/agent-skills --skill react-best-practices -a claude-code"
else
  echo "    ⏭  No React/Next.js detected, skipping react-best-practices"
fi

# shadcn/ui
if [[ -f "$TARGET_REPO/components.json" ]] || grep -rq "shadcn" "$TARGET_REPO/package.json" 2>/dev/null; then
  echo "    Installing shadcn/ui skill..."
  (cd "$TARGET_REPO" && npx shadcn@latest add skill 2>/dev/null) \
    && echo "    ✓  shadcn/ui skill" \
    || echo "    ⚠  shadcn/ui: npx shadcn@latest add skill"
else
  echo "    ⏭  No shadcn/ui detected, skipping"
fi

# ── MCP servers ──────────────────────────────────────────
echo ""
echo "  MCP servers:"

if command -v claude &> /dev/null; then
  # Playwright MCP — browser automation, visual testing
  echo "    Installing Playwright MCP..."
  (cd "$TARGET_REPO" && claude mcp add playwright -- npx @playwright/mcp@latest 2>/dev/null) \
    && echo "    ✓  Playwright MCP" \
    || echo "    ⚠  Playwright MCP: claude mcp add playwright -- npx @playwright/mcp@latest"

  # Storybook MCP — only if Storybook is present
  if has_dependency "storybook" || has_dependency "@storybook/react" || [[ -d "$TARGET_REPO/.storybook" ]]; then
    echo "    Installing Storybook MCP..."
    (cd "$TARGET_REPO" && npx storybook@latest add @storybook/addon-mcp 2>/dev/null) \
      && echo "    ✓  Storybook MCP" \
      || echo "    ⚠  Storybook MCP: npx storybook@latest add @storybook/addon-mcp"
  fi

  # A11y MCP — accessibility testing
  echo "    Installing A11y MCP..."
  (cd "$TARGET_REPO" && claude mcp add a11y-accessibility -- npx -y a11y-mcp-server 2>/dev/null) \
    && echo "    ✓  A11y MCP" \
    || echo "    ⚠  A11y MCP: claude mcp add a11y-accessibility -- npx -y a11y-mcp-server"

  # Figma MCP note
  echo "    ℹ  Figma MCP: built into Claude Code (connect via Settings > MCP)"
else
  echo "    ⚠  Claude CLI not found. Install MCP servers manually."
  echo "    See recommended-tools.md for the full list."
fi

echo ""

# ── Step 6: Create Obsidian vault ────────────────────────

echo "▸ Step 6/$TOTAL_STEPS: Creating Obsidian vault..."

VAULT_DIR="$TARGET_REPO/obsidian-vault/$PROJECT_NAME"

# MCPVault — connect Obsidian vault to Claude Code
if command -v claude &> /dev/null; then
  echo "  Connecting vault to Claude Code via MCPVault..."
  (claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest "$VAULT_DIR" 2>/dev/null) \
    && echo "  ✓  MCPVault connected: AI can read/write/search the vault" \
    || echo "  ⚠  MCPVault: claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest $VAULT_DIR"
fi

if [[ -d "$VAULT_DIR" ]]; then
  echo "  ⏭  Vault already exists: $VAULT_DIR"
else
  mkdir -p "$VAULT_DIR/screenshots"
  cp -r "$VAULT_TEMPLATE_DIR"/_project-template/* "$VAULT_DIR/"
  cp "$VAULT_TEMPLATE_DIR/CLAUDE.md" "$TARGET_REPO/obsidian-vault/CLAUDE.md"
  echo "  ✓  Vault created: $VAULT_DIR"
fi

echo ""

# ── Step 7: Create briefs directory ──────────────────────

echo "▸ Step 7/$TOTAL_STEPS: Creating briefs directory..."

BRIEFS_DEST="$TARGET_REPO/briefs"

if [[ -d "$BRIEFS_DEST" ]]; then
  echo "  ⏭  Briefs directory already exists: $BRIEFS_DEST"
else
  mkdir -p "$BRIEFS_DEST/assets" "$BRIEFS_DEST/done" "$BRIEFS_DEST/examples"
  cp "$TEMPLATES_DIR/briefs/_template.md" "$BRIEFS_DEST/_template.md"
  cp "$TEMPLATES_DIR/briefs--CLAUDE.md" "$BRIEFS_DEST/CLAUDE.md"
  cp "$TEMPLATES_DIR/briefs/examples/"*.md "$BRIEFS_DEST/examples/" 2>/dev/null || true
  echo "  ✓  Briefs directory created: $BRIEFS_DEST"
  echo "     See examples/ for how to write briefs"
fi

echo ""

# ── Step 8: Copy prompts ────────────────────────────────

echo "▸ Step 8/$TOTAL_STEPS: Copying prompts..."

PROMPTS_DEST="$TARGET_REPO/prompts"

if [[ -d "$PROMPTS_DEST" ]]; then
  echo "  ⏭  Prompts directory already exists: $PROMPTS_DEST"
else
  mkdir -p "$PROMPTS_DEST"
  cp "$PROMPTS_DIR"/*.md "$PROMPTS_DEST/"
  echo "  ✓  Prompts copied to: $PROMPTS_DEST"
fi

echo ""

# ── Step 9: Capture baseline ────────────────────────────

echo "▸ Step 9/$TOTAL_STEPS: Capturing baseline..."

BASELINE_DIR="$TARGET_REPO/obsidian-vault/$PROJECT_NAME/baseline"
mkdir -p "$BASELINE_DIR"

# Record what quality tools exist and their current output
echo "  Recording quality baseline..."

{
  echo "# Quality Baseline"
  echo ""
  echo "Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""

  if has_script "lint"; then
    echo "## Lint"
    echo '```'
    (cd "$TARGET_REPO" && $PKG_RUN lint 2>&1 | head -50) || true
    echo '```'
    echo ""
  else
    echo "## Lint"
    echo "No lint script found."
    echo ""
  fi

  if has_script "typecheck" || has_script "type-check"; then
    echo "## Type check"
    echo '```'
    (cd "$TARGET_REPO" && ($PKG_RUN typecheck 2>&1 || $PKG_RUN type-check 2>&1) | head -50) || true
    echo '```'
    echo ""
  elif [[ -f "$TARGET_REPO/tsconfig.json" ]]; then
    echo "## Type check"
    echo '```'
    (cd "$TARGET_REPO" && npx tsc --noEmit 2>&1 | head -50) || true
    echo '```'
    echo ""
  fi

  if has_script "test"; then
    echo "## Tests"
    echo '```'
    (cd "$TARGET_REPO" && $PKG_RUN test -- --run 2>&1 | tail -20) || true
    echo '```'
    echo ""
  fi

  echo "## Git status"
  echo '```'
  (cd "$TARGET_REPO" && git log --oneline -5 2>&1) || true
  echo '```'
} > "$BASELINE_DIR/quality-snapshot.md"

echo "  ✓  Baseline saved: $BASELINE_DIR/quality-snapshot.md"
echo ""

# ── Done ─────────────────────────────────────────────────

echo "╔══════════════════════════════════════════════════╗"
echo "║                    Setup complete                ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║                                                  ║"
echo "║  Next steps:                                     ║"
echo "║                                                  ║"
echo "║  1. Fill in DESIGN.md with your design tokens    ║"
echo "║  2. Open Claude Code in the project:             ║"
echo "║     cd $TARGET_REPO && claude"
echo "║  3. Run the onboarding prompt:                   ║"
echo "║     Paste contents of prompts/onboarding.md      ║"
echo "║  4. Open the Obsidian vault in Obsidian:         ║"
echo "║     $VAULT_DIR"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
