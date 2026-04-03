# Recommended Tools

External skills, plugins, and MCP servers for designers working with Claude Code.
Setup script detects the project and suggests relevant tools from this list.

## Design Quality Skills

| Tool | What it does | Install |
|------|-------------|---------|
| [impeccable](https://github.com/pbakaus/impeccable) | 20 design commands + 7 reference guides: typography, color, spatial design, motion, interaction, responsive, UX writing. Has `/teach-impeccable` that learns your project's brand. | `npx skills add pbakaus/impeccable` |
| [web-design-guidelines](https://github.com/vercel-labs/agent-skills) | 100+ UI rules: accessibility, performance, UX patterns. Audits code against real standards. | `npx skills add vercel-labs/agent-skills --skill web-design-guidelines -a claude-code` |
| [frontend-design](https://github.com/anthropics/skills) | Anthropic official. Anti-AI-slop: distinctive typography, color palettes, animations. | `npx skills add anthropics/skills --skill frontend-design -a claude-code` |
| [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 57 UI styles, 161 color palettes, 57 font pairings, 99 UX guidelines. Largest design knowledge base. | `npx skills add nextlevelbuilder/ui-ux-pro-max-skill` |
| [design-with-claude](https://github.com/imsaif/design-with-claude) | 29 specialist design agents: accessibility, motion, color theory, typography, dashboards, design system architecture. Design Auditor scores out of 100. | `claude plugin add imsaif/design-with-claude` |

## Testing Skills

| Tool | What it does | Install |
|------|-------------|---------|
| [playwright-skill](https://github.com/testdino-hq/playwright-skill) | 70+ Playwright guides: locators, assertions, auth, mocking, debugging, CI, POM, migration from Cypress/Selenium. | `npx skills add testdino-hq/playwright-skill` |
| [vitest-skill](https://github.com/jezweb/claude-skills) | Vitest 4.x patterns: mocking, snapshots, in-source testing, workspace config, browser mode. | `claude plugin add jezweb/claude-skills` |
| [tdd-guard](https://github.com/nizos/tdd-guard) | Blocks implementation without failing tests. Enforces RED-GREEN-REFACTOR. Can be toggled off. | `claude plugin add nizos/tdd-guard` |

## Development Workflow Skills

| Tool | What it does | Install |
|------|-------------|---------|
| [superpowers](https://github.com/obra/superpowers) | Disciplined dev: TDD, planning, code review, debugging, verification. | `claude plugin add obra/superpowers` |
| [code-review-graph](https://github.com/tirth8205/code-review-graph) | Knowledge graph for duplicate detection and codebase understanding. | `claude plugin add tirth8205/code-review-graph` |

## Framework-specific Skills

### React / Next.js

| Tool | What it does | Install |
|------|-------------|---------|
| [react-best-practices](https://github.com/vercel-labs/agent-skills) | 57 React/Next.js rules: performance, patterns, SSR, hydration. | `npx skills add vercel-labs/agent-skills --skill react-best-practices -a claude-code` |
| [composition-patterns](https://github.com/vercel-labs/agent-skills) | React component architecture: eliminates boolean prop soup. | `npx skills add vercel-labs/agent-skills --skill composition-patterns -a claude-code` |

### shadcn/ui

| Tool | What it does | Install |
|------|-------------|---------|
| shadcn/ui skill | Component context: knows all shadcn components, variants, props. | `npx shadcn@latest add skill` |

## MCP Servers

### Must-have

| Server | What it does | Install |
|--------|-------------|---------|
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Browser automation, screenshots, visual testing. | `claude mcp add playwright -- npx @playwright/mcp@latest` |
| Figma MCP (official) | Read designs, extract components, Code Connect. | Built into Claude Code (Settings > MCP) |

### Strongly recommended

| Server | What it does | Install |
|--------|-------------|---------|
| [MCPVault](https://github.com/bitbonsai/mcpvault) | Knowledge base read/write/search. Reads .md files directly — no Obsidian needed. BM25 search. | `claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest /path/to/vault` |
| [Storybook MCP](https://github.com/storybookjs/mcp) | Component knowledge: stories, variants, props, docs. | `npx storybook@latest add @storybook/addon-mcp` |
| [A11y MCP](https://github.com/ronantakizawa/a11ymcp) | WCAG compliance: axe-core + Puppeteer. | `claude mcp add a11y-accessibility -- npx -y a11y-mcp-server` |

### For Figma (free accounts or advanced use)

| Server | What it does | Install |
|--------|-------------|---------|
| [Framelink](https://github.com/GLips/Figma-Context-MCP) | Simplified Figma API for AI. Works with free Figma accounts. | `claude mcp add figma -- npx -y figma-developer-mcp --figma-api-key=KEY --stdio` |

### Knowledge base MCP options (if not using MCPVault above)

| Server | When to use | Install |
|--------|------------|---------|
| [Nexus](https://github.com/ProfSynapse/claudesidian-mcp) | Want chat inside Obsidian + MCP. Requires Obsidian running. | Obsidian plugin install |
| [obsidian-claude-code-mcp](https://github.com/iansinnott/obsidian-claude-code-mcp) | Auto-discovery for Claude Code. Requires Obsidian running. | Obsidian plugin install |

## Skill management

| Tool | What it does | Install |
|------|-------------|---------|
| [skills CLI](https://github.com/vercel-labs/skills) | Discover and install skills. | `npx skills search "design"` |
| [skillgrade](https://github.com/mgechev/skillgrade) | Test and evaluate skill quality. | `npx skillgrade init && npx skillgrade --smoke` |

## What we keep custom

| Skill | Why custom |
|-------|-----------|
| **onboarding** | Designer-centric codebase analysis: product overview, entity map, screen inventory, component graph, user flows, visual language. No external tool does this. |
| **sync** | Vault synchronization with code changes, preserving designer annotations. Unique to our vault approach. |
| **sync-tokens** | Three-way token reconciliation: Figma Variables ↔ DESIGN.md ↔ Code. Auto-detects direction, shows diff, asks before writing. No external tool bridges all three sources with designer approval flow. |
