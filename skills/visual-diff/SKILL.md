---
name: visual-diff
description: Captures before/after screenshots of a page or component and produces a designer-readable report of what changed visually. Use when a designer says "show me what changed", "did the layout shift?", "check before/after", "does it look right?", or after modifying a component. Has two modes — snapshot (record baseline before changes) and compare (report changes after implementation).
---

# Visual Diff Skill

Capture a before/after visual comparison of a page or component and report what changed.

## Prerequisites

- Playwright MCP connected
- App or Storybook running locally
- A page URL or component name

## Two modes

| Mode | When to use | Command |
|---|---|---|
| **snapshot** | Before making changes — record the current state as baseline | "snapshot baseline for /dashboard" |
| **compare** | After making changes — compare current state to baseline | "compare /dashboard against baseline" |

---

## Standard capture sequence

Use this sequence in both modes. Wait for `networkidle` (or a visible key element) before taking each screenshot to ensure JS-rendered content and lazy-loaded images are fully present.

**App page:**

```
browser_navigate(url="http://localhost:3000/[page]")
browser_resize(width=1440, height=900)
browser_wait_for_load_state(state="networkidle")
browser_take_screenshot()

browser_resize(width=375, height=812)
browser_wait_for_load_state(state="networkidle")
browser_take_screenshot()
```

**Storybook component:**

```
browser_navigate(url="http://localhost:6006/?path=/story/[component-id]")
browser_resize(width=1440, height=900)
browser_wait_for_load_state(state="networkidle")
browser_take_screenshot()

browser_resize(width=375, height=812)
browser_wait_for_load_state(state="networkidle")
browser_take_screenshot()
```

---

## Mode A: Snapshot (before changes)

### Step 1: Capture at standard viewports

Follow the **Standard capture sequence** above for the target page or component.

### Step 2: Save baseline files

Save screenshots as:
- `baseline--[page-slug]--desktop--[YYYY-MM-DD].png`
- `baseline--[page-slug]--mobile--[YYYY-MM-DD].png`

Place in the project's `baseline/` directory (create if absent).

> **Note:** Always capture both desktop (1440px) and mobile (375px) unless the designer specifies otherwise. If the page requires auth or the app isn't running, tell the designer and ask for screenshots instead.

### Step 3: Confirm

Inform the designer that the baseline has been captured at both viewports and that they can proceed with changes and run compare when done.

---

## Mode B: Compare (after changes)

### Step 1: Load the baseline

Find the most recent `baseline--[page-slug]--desktop--*.png` and `baseline--[page-slug]--mobile--*.png`.

If no baseline exists, switch to snapshot mode first and tell the designer.

### Step 2: Capture current state

Follow the **Standard capture sequence** above for the same page or component.

> **Note:** Always capture both desktop (1440px) and mobile (375px) unless the designer specifies otherwise. If the page requires auth or the app isn't running, tell the designer and ask for screenshots. If multiple baselines exist for the same page, use the most recent one.

### Step 3: Visual comparison

Compare baseline vs current across these categories:

| Category | What to check |
|---|---|
| **Layout & Spacing** | Element positions, padding, margins, gaps, alignment |
| **Typography** | Font size, weight, line height, truncation |
| **Color** | Background, text, border, icon colors |
| **Components** | Added, removed, or shifted elements |
| **Responsive** | Layout reflow, stacking order, hidden/shown elements at mobile |

### Step 4: Report to the designer

```markdown
## Visual Diff: [Page / Component Name]

Baseline: [date of baseline]
Compared at: desktop 1440px · mobile 375px

### Summary
✅ Unchanged: N items
⚠️  Shifted: N items
🔴 Broken: N items

### Findings

| Viewport | Category   | What changed                      | Before              | After               | Severity |
|----------|------------|-----------------------------------|---------------------|---------------------|----------|
| Desktop  | Spacing    | Card padding reduced              | 24px                | 16px                | Medium   |
| Mobile   | Layout     | Nav stack order changed           | Logo left           | Logo centered       | High     |
| Both     | Color      | CTA button shade different        | #2563EB             | #3B82F6             | Low      |

### What the designer sees
[2–3 plain-language sentences describing the most visible differences]

### Recommended action
1. [Most impactful issue first]
2. ...
```

**Severity guide:** **High** — immediately visible, layout broken or element missing · **Medium** — noticeable on inspection, affects polish · **Low** — subtle pixel-level difference

---

## Updating the baseline

After the designer approves the changes:

1. Delete the old baseline files for the affected page — never delete baseline files without the designer's explicit approval
2. Re-run snapshot mode to capture the new approved state
3. Commit the new baseline files with the code changes

Confirm to the designer that the baseline has been updated with the new approved state and the date it was saved.

---

## Example

For a request like "I changed the card component — does it look right?", follow Mode B (Compare) starting from Step 1.

---

## Related skills

| Skill | When to use instead |
|---|---|
| **figma-audit** | Designer has a Figma URL and wants to know if the *current implementation* matches the design — use this before or after making changes to check against the source of truth. |

**Typical workflow:** run `figma-audit` to find gaps → fix them → run `visual-diff` compare to confirm the changes look correct and nothing else regressed.
