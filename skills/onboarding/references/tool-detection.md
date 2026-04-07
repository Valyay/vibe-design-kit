# Tool Detection

Run these checks to report what is installed, then recommend what is missing.

## Detect installed MCP servers

```bash
# From project settings
jq -r '.mcpServers // {} | keys[]' "${CLAUDE_PROJECT_DIR}/.claude/settings.json" 2>/dev/null

# From global settings
jq -r '.mcpServers // {} | keys[]' ~/.claude/settings.json 2>/dev/null
```

Key servers to look for: `figma`, `playwright`, `storybook`, `github`.

## Detect installed plugins / skills

```bash
jq -r '.plugins // [] | .[]' "${CLAUDE_PROJECT_DIR}/.claude/settings.json" 2>/dev/null
```

## Detect stack from package.json

```bash
jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' \
  "${CLAUDE_PROJECT_DIR}/package.json" 2>/dev/null
```

Key packages to look for:

| Package present | Implies |
|---|---|
| `react`, `next` | React / Next.js project |
| `@shadcn/ui`, `shadcn` | shadcn/ui component library |
| `@storybook/react` | Storybook installed |
| `@playwright/test` | Playwright installed |
| `vitest`, `jest` | Test runner present |
| `biome`, `eslint` | Linter present |
| `typescript` | TypeScript project |
| `tailwindcss` | Tailwind CSS |

## Detect config files

```bash
ls "${CLAUDE_PROJECT_DIR}"/{tailwind.config.*,playwright.config.*,.storybook,vitest.config.*,biome.json,.eslintrc*} 2>/dev/null
```

## Report format

```
Installed:
  ✓ Figma MCP (design inspection, token sync)
  ✓ Playwright MCP (screenshot, E2E)
  ✓ Storybook (component stories)

Missing (recommended for this project):
  ✗ tdd-guard plugin — no test-first enforcement detected
    Install: add "nizos/tdd-guard" to plugins in .claude/settings.json
```

Ask: "Want me to install any of the missing tools?"
If install fails or designer declines, note it and continue.
