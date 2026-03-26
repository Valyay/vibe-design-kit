# Design Review Prompt

> Copy and paste this into Claude Code, or just say "review my changes" in chat.

---

Review the quality of my latest changes. Compare against the baseline.

Run all automated checks first:
- Lint, typecheck, tests — are there new errors?
- Accessibility (axe-core or A11y MCP) — new violations?
- Visual regression — screenshot before vs after

Then check manually:
- Token compliance — any hardcoded colors, spacing, fonts?
- Component states — are all five states handled? (loading, error, empty, populated, partial)
- Responsive — does it work at mobile, tablet, desktop?
- Duplicates — did I create something that already exists?

Give me a table: what was the baseline, what is it now, is it better or worse.
Then the top 3 things to fix, by severity.
