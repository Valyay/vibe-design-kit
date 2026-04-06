---
name: figma-audit
description: Compares spacing, colors, typography, layout, and component structure between a live browser page or component and a Figma design, then reports visual discrepancies in a structured table. Use when the designer says "does this match Figma?", "check the implementation against the design", "how far are we from the mockup?", or pastes a Figma URL alongside a page URL or component name.
---

# Figma Audit Skill

Compare an existing implementation against a Figma design and report visual discrepancies.

## Prerequisites

- Figma MCP server connected
- Playwright MCP connected (for browser screenshots)
- Designer provides: a Figma URL **and** a page URL or component name

## Step 1: Parse the Figma URL

Extract `fileKey` and `nodeId` from the Figma URL.

**Format:** `https://figma.com/design/:fileKey/:fileName?node-id=1-2`

- `fileKey` → segment after `/design/`
- `nodeId` → value of `node-id` query param, replace `-` with `:`

If the designer only named a component ("the Button"), search the vault's `component-graph.md` or ask for a Figma URL.

## Step 2: Capture the Figma reference

```
get_screenshot(fileKey=":fileKey", nodeId=":nodeId")
```

Also fetch structured data for exact values:

```
get_design_context(fileKey=":fileKey", nodeId=":nodeId")
```

Extract from the context: spacing values, font sizes, colors, border radii.

## Step 3: Capture the browser screenshot

Navigate to the live page or component and take a screenshot at the same viewport size as the Figma frame.

Use Playwright MCP:

```
browser_navigate(url="http://localhost:3000/page-url")
browser_resize(width=:figmaFrameWidth, height=:figmaFrameHeight)
browser_take_screenshot()
```

If comparing a component in isolation, use Storybook:

```
browser_navigate(url="http://localhost:6006/?path=/story/:component-id")
browser_take_screenshot()
```

**Match the viewport to the Figma frame dimensions.** If the frame is 1440px wide, screenshot at 1440px.

## Step 4: Visual comparison

Compare both screenshots against the `get_design_context` values across these categories:

| Category | What to check |
|---|---|
| **Layout & Spacing** | Padding, margins, gaps, width, height, alignment |
| **Typography** | Family, size, weight, line height, letter spacing, color |
| **Color** | Background, text, border, and icon colors |
| **Borders & Radius** | Border width, radius, shadow (offset, blur, spread, color) |
| **Content & States** | All elements present; interactive states accounted for |

## Step 5: Report to the designer

```
## Figma Audit: [Component/Page Name]

Figma: [node URL]
Reviewed at: [viewport size]

### Summary
✅ Matches: N items
⚠️  Drift: N items
❌ Missing: N items

### Findings

| Category   | Issue                             | Figma value | Current value | Severity |
|------------|-----------------------------------|-------------|---------------|----------|
| Spacing    | Card padding too small            | 24px        | 16px          | Medium   |
| Color      | Button background wrong shade     | #2563EB     | #3B82F6       | High     |
| Typography | Heading weight off                | 700         | 600           | Low      |
| Border     | Input corner radius doesn't match | 8px         | 4px           | Medium   |

### What the user sees
[2-3 sentences describing the visible difference in plain terms]

### Recommended fixes
1. [Most impactful fix first]
2. ...
```

**Severity guide:** **High** — immediately visible, breaks design intent · **Medium** — noticeable on close inspection · **Low** — minor, pixel-level difference

## Step 6: Offer to fix

After the report, ask:

> "Want me to fix the high and medium issues? I'll start with the most visible ones."

If yes, switch to the implementation workflow: read the component, apply the correct values from `get_design_context`, verify against the Figma screenshot.

## Rules

- Never change code without the designer's explicit approval
- When in doubt about a value, trust `get_design_context` numbers over visual estimation
- If the Figma design itself has an error (e.g., inconsistent spacing), flag it: "The Figma shows 16px here but 24px in a similar component — which is intentional?"
- Preserve all existing functionality — this is a visual audit, not a refactor
- If Playwright can't reach the page (auth required, not running), tell the designer and ask for a screenshot

## Example

Designer says: "Can you check if the login page matches Figma? https://figma.com/design/ABC123/App?node-id=5-10"

1. Parse URL → fileKey=`ABC123`, nodeId=`5:10`
2. `get_screenshot(fileKey="ABC123", nodeId="5:10")` → Figma reference
3. `get_design_context(fileKey="ABC123", nodeId="5:10")` → exact values
4. `browser_navigate("http://localhost:3000/login")` + `browser_take_screenshot()` → current state
5. Compare: layout, typography, colors, borders
6. Report table with findings
7. Ask if designer wants fixes applied
