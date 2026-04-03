# Recommended Tools

Check installed skills, plugins, and MCP servers. Recommend based on project stack.

## Detection

- Check `.claude/` directory and settings for installed plugins/skills
- List MCP servers via `claude mcp list` or check config

## Recommendations by stack

| If project uses... | Recommend |
|--------------------|-----------|
| React / Next.js | react-best-practices, composition-patterns skills |
| shadcn/ui | shadcn/ui skill |
| Storybook | Storybook MCP server |
| Playwright | Playwright MCP server |
| Figma (designer has access) | Verify Figma MCP is connected |
| No test runner | Suggest Vitest + tdd-guard |
| No linter | Suggest Biome |

## Report format

```
Installed:
  ✓ Tool name (purpose)

Missing (recommended for this project):
  ✗ Tool name — reason
    Install: <command>
```

Ask: "Want me to install the missing tools?"
If install fails or designer declines, note it and continue.
