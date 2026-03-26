# E2E Tests Rules

## Auto-triggers

When working in this directory, the following happens automatically:

### Before implementing a feature (test-first)
1. Write the E2E test FIRST — describe what the feature should do
2. Use `playwright-skill` for proper test patterns (locators, assertions, waits)
3. Run the test — it should FAIL (feature doesn't exist yet)
4. Tell the designer: "Test written, it fails as expected. Now implementing."

### After implementing a feature
1. Run the E2E test — it should PASS now
2. Run ALL existing E2E tests — nothing must break
3. Add visual regression checkpoints (`toHaveScreenshot()`)
4. Add accessibility check (`@axe-core/playwright` or A11y MCP)
5. Show results to the designer: passed/failed, screenshot diffs

### When the designer describes a user flow
1. Parse the flow into test steps automatically
2. Search the codebase for existing `data-testid`, labels, button text
3. Generate the Playwright test using accessible selectors
4. If selectors are missing, offer to add `data-testid` to the code

## Test patterns

Follow existing test patterns in this directory. Before writing a new test,
read 2-3 existing test files to match the style.

### Selector priority
1. `data-testid` attributes (most stable)
2. Accessible roles and labels (`getByRole`, `getByLabel`)
3. Text content (`getByText`) — only for static text
4. Never CSS classes or DOM structure

### Test structure
- Use `test.describe` for grouping related tests
- Use `test.beforeEach` for common setup
- Name tests as "should [expected behavior] when [condition]"
- One assertion focus per test

### Visual regression
- Capture at desktop (1280px) and mobile (375px)
- Name screenshots: `feature--state--breakpoint.png`
- Review baseline changes with the designer before committing
