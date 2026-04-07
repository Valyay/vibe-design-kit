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
- Token drift — do Figma, DESIGN.md, and code agree? (run sync-tokens if unsure)
- Component states — are all five states handled? (loading, error, empty, populated, partial)
- Responsive — does it work at mobile, tablet, desktop?
- Duplicates — did I create something that already exists?

Give me a table: what was the baseline, what is it now, is it better or worse.
Then report issues using this format:

## Output format

For each issue found, use this structure:

```
## Issue: [short description]
- **Severity**: High | Medium | Low
- **Category**: Color | Typography | Spacing | Layout | A11y | State | Responsive
- **Expected**: [what should be — value, behavior, or screenshot]
- **Actual**: [what is now]
- **File**: [path/to/file:line]
- **Fix**: [specific change to make]
```

Sort issues by severity (High first). Include all issues found, not just top 3.
