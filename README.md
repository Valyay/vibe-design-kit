# Vibe Design Kit

Toolkit for UI/UX designers working with AI code generation.

A set of markdown files and one bash script that help designers produce higher-quality results
with Claude Code. The kit does not reinvent existing tools — it wires them together with
context, guardrails, and prompts tuned for a designer's workflow.

## Who is this for?

Designers who:

- Work on **existing products** (brownfield) and need AI to respect the current codebase
- Want AI to follow design tokens, component graph, and visual identity — not hallucinate
- Don't read code line-by-line but verify results visually and by interaction

## Quick start (brownfield)

```bash
# 1. Clone this repo
git clone https://github.com/nicecode-dev/vibe-design-kit.git

# 2. Run setup on your client project
./setup.sh /path/to/client-repo my-project
```

The script will:

- Copy `CLAUDE.md` rules (root + folder-level) into the client repo
- Create a `DESIGN.md` template for visual identity
- Install Claude Code skills, plugins, and MCP servers
- Install enforcement hooks that block rule violations automatically
- Detect and bootstrap missing quality tools (linter, tests, Storybook)
- Create a knowledge base from template for persistent project memory
- Copy ready-made prompts and brief examples
- Capture baseline (screenshots, test results)

## What's inside

```
vibe-design-kit/
├── README.md                        # You are here
├── setup.sh                         # One script — installs everything
├── recommended-tools.md             # External skills, plugins, MCP servers
│
├── templates/
│   ├── CLAUDE.md                    # Root AI rules (auto-triggers, quality gates)
│   ├── DESIGN.md                    # Visual identity template
│   ├── settings.json                # .claude/settings.json with hooks + permissions
│   ├── components--CLAUDE.md        # → components/CLAUDE.md
│   ├── e2e--CLAUDE.md               # → e2e/CLAUDE.md
│   ├── app--CLAUDE.md               # → app/CLAUDE.md
│   ├── briefs--CLAUDE.md            # → briefs/CLAUDE.md
│   └── briefs/
│       ├── _template.md             # Design brief template
│       └── examples/                # 5 example briefs
│
├── hooks/                           # Enforcement hooks (→ .claude/hooks/)
│   ├── check-hardcoded-values.sh    # Block hardcoded colors, px, font-family
│   ├── check-duplicate-component.sh # Warn about similar existing components
│   ├── check-e2e-test-exists.sh     # Block new component without e2e test
│   ├── check-story-exists.sh        # Remind to create Storybook stories
│   ├── check-a11y.sh                # Ensure e2e specs include axe assertions
│   ├── check-mermaid-validity.sh    # Validate Mermaid diagrams in markdown
│   ├── check-wikilinks.sh           # CLI tool: validate [[wiki-links]] in KB vault
│   ├── check-kb-drift.sh            # Remind to update KB after code edits
│   ├── check-sync-freshness.sh      # Warn if knowledge base is stale (SessionStart)
│   ├── session-report.sh            # Unified session start health report
│   ├── report-recovery.sh           # Report blocked/fixed issues to designer
│   ├── protect-vault-baseline.sh    # Block direct edits to baseline/sync-log
│   └── post-edit-quality.sh         # Run lint + typecheck after edits
│
├── skills/
│   ├── onboarding/SKILL.md          # Full project analysis for designer
│   ├── sync/SKILL.md                # Keep vault in sync with code changes
│   ├── sync-tokens/SKILL.md         # Figma ↔ DESIGN.md ↔ Code token reconciliation
│   ├── figma-audit/SKILL.md         # Compare live implementation vs Figma design
│   ├── visual-diff/SKILL.md         # Before/after screenshot diff report
│   └── kb-lint/SKILL.md             # Cross-reference KB docs against codebase
│
├── knowledge-base/                  # Project knowledge (code is source of truth)
│   ├── CLAUDE.md
│   └── _project-template/
│       ├── product-overview.md      # What is this product?
│       ├── entity-map.md            # Business objects and relationships
│       ├── screen-inventory.md      # Every screen with screenshots
│       ├── component-graph.md       # Component hierarchy and data flow
│       ├── user-flows.md            # User journeys through screens
│       ├── visual-language.md       # Real design system state
│       ├── token-audit.md           # Token coverage data
│       ├── architecture.md          # Tech stack reference
│       ├── baseline/                # Quality snapshot (lint, tests, a11y)
│       ├── _sync-log.md             # Vault update history
│       └── entities/, decisions/, issues/, flows/, patterns/
│
├── prompts/                         # Copy-paste prompts (optional)
│   ├── onboarding.md
│   ├── new-component.md
│   ├── new-page.md
│   ├── generate-e2e.md
│   ├── design-review.md
│   ├── sync-vault.md
│   └── sync-tokens.md
│
└── .claude/settings.json            # Pre-configured permissions and plugins
```

## Enforcement hooks

Rules in `CLAUDE.md` are instructions — the AI *should* follow them. Hooks are enforcement —
the AI *cannot bypass* them. The kit installs shell scripts into `.claude/hooks/` that run
automatically on every file edit:

**Blocking hooks** (PreToolUse — stop the AI before the action):

| Hook | Event | Action |
|------|-------|--------|
| `check-hardcoded-values.sh` | Before Edit/Write | **Blocks** hardcoded hex colors, pixel values, and font-family in UI files |
| `check-duplicate-component.sh` | Before Write | **Warns** if a similarly-named component already exists |
| `check-e2e-test-exists.sh` | Before Write | **Blocks** new component creation without a corresponding e2e test |
| `protect-vault-baseline.sh` | Before Edit/Write | **Warns** when editing baseline and sync-log files directly |

**Advisory hooks** (PostToolUse/SessionStart — inform without blocking):

| Hook | Event | Action |
|------|-------|--------|
| `post-edit-quality.sh` | After Edit/Write | Runs lint + typecheck automatically after code changes |
| `check-story-exists.sh` | After Write | **Reminds** to create a Storybook story for new components |
| `check-a11y.sh` | After Write | **Reminds** to add axe accessibility assertions to e2e specs |
| `check-mermaid-validity.sh` | After Edit/Write | Validates Mermaid diagrams in markdown files |
| `check-kb-drift.sh` | After Edit/Write | **Reminds** to update KB docs when referenced code files change |
| `check-sync-freshness.sh` | Session start | Warns if knowledge base hasn't been synced in over 7 days |
| `session-report.sh` | Session start | Unified health report: vault freshness, drift, broken links |
| `report-recovery.sh` | After Edit/Write | Reports what the AI had to fix so the designer can write better briefs |

Some hooks require `python3` for heuristic analysis — install it to enable full enforcement.

## Key principles

1. **Code is source of truth** — vault and docs describe the code, not the other way around
2. **Designer-first** — AI validates its own output because the designer won't read code
3. **Test first** — capture baseline, write test, implement, verify
4. **No hardcode** — all values come from design tokens or DESIGN.md
5. **No duplicates** — check existing components before creating new ones
6. **All states** — every data component must handle: loading, error, empty, populated, partial
7. **Responsive** — always generate for mobile, tablet, desktop
8. **Small PRs** — one logical task per PR, no mixing features with refactoring

## External tools (installed by setup.sh)

### Built-in skills (included in this kit)

| Skill | What it does |
|-------|-------------|
| `onboarding` | Full project analysis — component graph, tokens, flows |
| `sync` | Keep knowledge base in sync with code changes |
| `sync-tokens` | Figma ↔ DESIGN.md ↔ Code token reconciliation |
| `figma-audit` | Compare live implementation vs Figma design, report discrepancies |
| `visual-diff` | Before/after screenshot diff — shows what changed visually |
| `kb-lint` | Cross-reference KB docs against codebase, find stale content |

### External skills and plugins

| Tool | What it does |
|------|-------------|
| [superpowers](https://github.com/obra/superpowers) | TDD, planning, code review, debugging |
| [impeccable](https://github.com/pbakaus/impeccable) | Typography, color, spatial design, motion, UX writing |
| [web-design-guidelines](https://github.com/vercel-labs/agent-skills) | 100+ UI quality rules |
| [frontend-design](https://github.com/anthropics/skills) | Anti-AI-slop, distinctive visuals |
| [playwright-skill](https://github.com/testdino-hq/playwright-skill) | 70+ E2E testing guides |
| [tdd-guard](https://github.com/nizos/tdd-guard) | Enforces test-first workflow |
| [code-review-graph](https://github.com/tirth8205/code-review-graph) | Knowledge graph for duplicate detection |

### MCP servers

| Server | What it does |
|--------|-------------|
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Browser automation, visual testing |
| Figma MCP (official) | Read designs, extract components |
| [Storybook MCP](https://github.com/storybookjs/mcp) | Component knowledge for AI |
| [A11y MCP](https://github.com/ronantakizawa/a11ymcp) | WCAG accessibility testing |

See [recommended-tools.md](recommended-tools.md) for the full list with install commands.

## License

MIT
