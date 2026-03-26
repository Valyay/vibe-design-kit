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
- Install Claude Code skills and plugins
- Build a knowledge graph of the codebase (via code-review-graph)
- Create an Obsidian vault from template for persistent project memory
- Copy ready-made prompts

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
│   ├── components--CLAUDE.md        # → components/CLAUDE.md
│   ├── e2e--CLAUDE.md               # → e2e/CLAUDE.md
│   ├── app--CLAUDE.md               # → app/CLAUDE.md
│   ├── briefs--CLAUDE.md            # → briefs/CLAUDE.md
│   └── briefs/
│       ├── _template.md             # Design brief template
│       └── examples/                # 5 example briefs
│
├── skills/
│   ├── onboarding/SKILL.md          # Full project analysis for designer
│   └── sync/SKILL.md                # Keep vault in sync with code changes
│
├── obsidian-vault-template/         # Persistent memory (code is source of truth)
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
│   └── sync-vault.md
│
└── .claude/settings.json            # Pre-configured permissions and plugins
```

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

### Skills and plugins

| Tool | What it does |
|------|-------------|
| [superpowers](https://github.com/obra/superpowers) | TDD, planning, code review, debugging |
| [web-design-guidelines](https://github.com/vercel-labs/agent-skills) | 100+ UI quality rules |
| [frontend-design](https://github.com/anthropics/skills) | Anti-AI-slop, distinctive visuals |
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
