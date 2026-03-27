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
#   6. Creates knowledge base from template
#   7. Creates briefs/ directory
#   8. Copies ready-made prompts
#   9. Captures baseline (screenshots, test results)
# ─────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
SKILLS_DIR="$SCRIPT_DIR/skills"
KB_TEMPLATE_DIR="$SCRIPT_DIR/knowledge-base"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
TOTAL_STEPS=9

# ── Argument parsing ─────────────────────────────────────

if [[ $# -lt 2 ]]; then
  echo "Usage: ./setup.sh /path/to/client-repo project-name"
  echo ""
  echo "Arguments:"
  echo "  /path/to/client-repo   Path to the existing client repository"
  echo "  project-name           Name for the project (used for knowledge base)"
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

echo ""
echo "  Vibe Design Kit — Brownfield Setup"
echo "  Target:  $TARGET_REPO"
echo "  Project: $PROJECT_NAME"
echo "  Package: $PKG_MANAGER"
echo ""

# ── Helpers ──────────────────────────────────────────────

has_dependency() {
  local dep="$1"
  grep -qE "\"$dep\"\\s*:" "$TARGET_REPO/package.json" 2>/dev/null
}

has_script() {
  local script="$1"
  grep -qE "\"$script\"\\s*:" "$TARGET_REPO/package.json" 2>/dev/null
}

# ── Strategy selection ───────────────────────────────────
# Detects what the project already has and asks the designer
# how to handle conflicts.

echo "  Scanning existing project configuration..."
echo ""

EXISTING=()
[[ -f "$TARGET_REPO/CLAUDE.md" ]]              && EXISTING+=("CLAUDE.md")
[[ -f "$TARGET_REPO/DESIGN.md" ]]              && EXISTING+=("DESIGN.md")
[[ -f "$TARGET_REPO/.claude/settings.json" ]]  && EXISTING+=(".claude/settings.json")
[[ -d "$TARGET_REPO/.claude/skills" ]]         && EXISTING+=(".claude/skills/")
[[ -d "$TARGET_REPO/.husky" ]] || [[ -f "$TARGET_REPO/lefthook.yml" ]] && EXISTING+=("pre-commit hooks")

if [[ ${#EXISTING[@]} -eq 0 ]]; then
  echo "  No existing configuration found. Installing everything fresh."
  STRATEGY="fresh"
else
  echo "  Found existing configuration:"
  for item in "${EXISTING[@]}"; do
    echo "    - $item"
  done
  echo ""
  echo "  How should I handle existing configs?"
  echo ""
  echo "  1) Keep existing — only add where nothing exists"
  echo "     (safest, won't change any of your current setup)"
  echo ""
  echo "  2) Merge — add vibe-design-kit rules alongside existing ones"
  echo "     (recommended, extends your setup without breaking it)"
  echo ""
  echo "  3) Overwrite — replace existing configs with vibe-design-kit"
  echo "     (clean start, but your current rules will be backed up)"
  echo ""
  read -rp "  Choose [1/2/3] (default: 2): " strategy_choice
  strategy_choice="${strategy_choice:-2}"

  case "$strategy_choice" in
    1) STRATEGY="keep" ;;
    3) STRATEGY="overwrite" ;;
    *) STRATEGY="merge" ;;
  esac
  echo ""
  echo "  Strategy: $STRATEGY"
fi

echo ""

# Apply strategy to a config file:
#   apply_config "source" "destination" "description"
#
# Behavior depends on $STRATEGY:
#   fresh    → copy source to destination
#   keep     → skip if destination exists, copy if not
#   merge    → append/merge source into destination (caller handles merge logic)
#   overwrite → backup destination, copy source
apply_config() {
  local src="$1"
  local dest="$2"
  local desc="$3"

  if [[ ! -f "$dest" ]]; then
    # No existing file → always install
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✓  Created: $desc"
    return 0  # installed
  fi

  case "$STRATEGY" in
    fresh)
      cp "$src" "$dest"
      echo "  ✓  Created: $desc"
      return 0
      ;;
    keep)
      echo "  ⏭  Kept existing: $desc"
      return 1  # skipped
      ;;
    merge)
      echo "  ⊕  Merging: $desc"
      return 0  # caller handles merge
      ;;
    overwrite)
      cp "$dest" "${dest}.backup.$(date +%s)"
      cp "$src" "$dest"
      echo "  ✓  Overwritten (backup saved): $desc"
      return 0
      ;;
  esac
}

# ── Step 1: Copy CLAUDE.md rules ────────────────────────

echo "▸ Step 1/$TOTAL_STEPS: Setting up CLAUDE.md rules..."

# Root CLAUDE.md — merge appends vdk section, keep skips, overwrite replaces
if apply_config "$TEMPLATES_DIR/CLAUDE.md" "$TARGET_REPO/CLAUDE.md" "CLAUDE.md (root)"; then
  if [[ "$STRATEGY" == "merge" ]] && [[ -f "$TARGET_REPO/CLAUDE.md" ]]; then
    # Append vdk rules to existing CLAUDE.md if not already present
    if ! grep -q "vibe-design-kit" "$TARGET_REPO/CLAUDE.md" 2>/dev/null; then
      echo "" >> "$TARGET_REPO/CLAUDE.md"
      echo "<!-- vibe-design-kit rules below -->" >> "$TARGET_REPO/CLAUDE.md"
      cat "$TEMPLATES_DIR/CLAUDE.md" >> "$TARGET_REPO/CLAUDE.md"
      echo "  ✓  Appended vibe-design-kit rules to existing CLAUDE.md"
    else
      echo "  ⏭  vibe-design-kit rules already present in CLAUDE.md"
    fi
  fi
fi

# Folder-level CLAUDE.md files
for template in "$TEMPLATES_DIR"/*--CLAUDE.md; do
  [[ -f "$template" ]] || continue
  basename="$(basename "$template")"
  folder_path="${basename%%--CLAUDE.md}"
  dest="$TARGET_REPO/$folder_path/CLAUDE.md"
  apply_config "$template" "$dest" "$folder_path/CLAUDE.md"
done

echo ""

# ── Step 2: Create DESIGN.md ────────────────────────────

echo "▸ Step 2/$TOTAL_STEPS: Setting up DESIGN.md..."
apply_config "$TEMPLATES_DIR/DESIGN.md" "$TARGET_REPO/DESIGN.md" "DESIGN.md"
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
      _saved_dir="$PWD"
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
# Skills are namespaced in separate directories — low conflict risk.
# prefix with vdk- to make them identifiable and removable.
echo ""
echo "  Custom skills (unique to vibe-design-kit):"
for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  dest_skill="$TARGET_REPO/.claude/skills/vdk-$skill_name"
  if [[ -d "$dest_skill" ]]; then
    if [[ "$STRATEGY" == "overwrite" ]]; then
      cp "$skill_dir"SKILL.md "$dest_skill/SKILL.md"
      echo "    ✓  vdk-$skill_name (overwritten)"
    else
      echo "    ⏭  vdk-$skill_name (already exists)"
    fi
  else
    mkdir -p "$dest_skill"
    cp "$skill_dir"SKILL.md "$dest_skill/SKILL.md"
    echo "    ✓  vdk-$skill_name"
  fi
done

# ── External skills and plugins ──────────────────────────
echo ""
echo "  External skills and plugins:"

# In "keep" strategy, skip installing external plugins if project already has .claude/
if [[ "$STRATEGY" == "keep" ]] && [[ -f "$TARGET_REPO/.claude/settings.json" ]]; then
  echo "    ⏭  Strategy is 'keep' — not installing external plugins."
  echo "    See recommended-tools.md for tools you can install manually."
elif command -v claude &> /dev/null; then
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

if [[ "$STRATEGY" == "keep" ]] && [[ -d "$TARGET_REPO/.claude/skills" ]]; then
  echo "    ⏭  Strategy is 'keep' — skipping skill installs."
else

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

# Vitest skill — only if the project uses vitest and Claude CLI is available
if has_dependency "vitest" && command -v claude &> /dev/null; then
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
if [[ -f "$TARGET_REPO/components.json" ]] || grep -q "shadcn" "$TARGET_REPO/package.json" 2>/dev/null; then
  echo "    Installing shadcn/ui skill..."
  (cd "$TARGET_REPO" && npx shadcn@latest add skill 2>/dev/null) \
    && echo "    ✓  shadcn/ui skill" \
    || echo "    ⚠  shadcn/ui: npx shadcn@latest add skill"
else
  echo "    ⏭  No shadcn/ui detected, skipping"
fi

fi  # end strategy=keep guard for skills

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

# ── Step 6: Create knowledge base ────────────────────────

echo "▸ Step 6/$TOTAL_STEPS: Creating knowledge base..."

KB_DIR="$TARGET_REPO/design-knowledge/$PROJECT_NAME"

if [[ -d "$KB_DIR" ]]; then
  echo "  ⏭  Knowledge base already exists: $KB_DIR"
else
  mkdir -p "$KB_DIR/screenshots" "$KB_DIR/screenshots/components"
  cp -r "$KB_TEMPLATE_DIR"/_project-template/* "$KB_DIR/"
  cp "$KB_TEMPLATE_DIR/CLAUDE.md" "$TARGET_REPO/design-knowledge/CLAUDE.md"
  echo "  ✓  Vault created: $KB_DIR"
fi

# MCPVault — connect knowledge base to Claude Code (reads .md files directly)
if command -v claude &> /dev/null; then
  echo "  Connecting vault to Claude Code via MCPVault..."
  (claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest "$KB_DIR" 2>/dev/null) \
    && echo "  ✓  MCPVault connected: AI can read/write/search the vault" \
    || echo "  ⚠  MCPVault: claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest \"$KB_DIR\""
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

BASELINE_DIR="$TARGET_REPO/design-knowledge/$PROJECT_NAME/baseline"
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
    (cd "$TARGET_REPO" && CI=true $PKG_RUN test 2>&1 | tail -20) || true
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

echo ""
echo "  Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Fill in DESIGN.md with your design tokens"
echo "  2. Open Claude Code: cd $TARGET_REPO && claude"
echo "  3. Run onboarding: paste contents of prompts/onboarding.md"
echo "  4. Knowledge base: $KB_DIR"
echo "     (open with Obsidian, VS Code, or any editor)"
echo ""
