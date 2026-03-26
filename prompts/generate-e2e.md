# Generate E2E Test Prompt

> Copy and paste this into Claude Code, or describe the flow directly in chat.
> Best used BEFORE implementing a feature (test-first).

---

Generate a Playwright E2E test for this flow:

**Flow name**: [NAME]

**Steps**:
1. [User action or expected outcome]
2. [User action or expected outcome]
3. [User action or expected outcome]

**Error cases** (if any):
- [What happens when something goes wrong]

---

Write the test first (it should fail). Then I'll implement. Then we'll verify.

Use accessible selectors (getByRole, getByLabel) over CSS selectors.
Add visual regression checkpoints (toHaveScreenshot) for key states.
Add an accessibility check (axe-core) on the main page.
Run the test and tell me the result.
