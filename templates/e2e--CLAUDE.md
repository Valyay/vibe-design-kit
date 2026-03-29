# E2E Tests Rules

## Two types of E2E tests

### 1. Component tests (via Storybook)

Test each component in isolation against its Storybook stories.
No app, no auth, no database — just the component with props.

```
Storybook story URL → Playwright opens it → asserts behavior → screenshots → a11y
```

See `components/CLAUDE.md` for the full Storybook + E2E pipeline.

When to use: every new or modified component that has Storybook stories.

### 2. Flow tests (via live app)

Test user journeys end-to-end through the running application.
Requires the app running (local dev, staging, or preview deployment).

```
Navigate to page → perform actions → assert outcomes → screenshots → a11y
```

When to use: testing flows across multiple pages, form submissions, navigation.

## Auto-triggers

When working in this directory, the following happens automatically:

### Before implementing a feature (test-first)
1. Write the E2E test FIRST — describe what the feature should do
2. Use `playwright-skill` for proper test patterns (locators, assertions, waits)
3. For component work: write tests against Storybook story URLs
4. For flow work: write tests against the running app
5. Run the test — it should FAIL (feature doesn't exist yet)
6. Tell the designer: "Test written, it fails as expected. Now implementing."

### After implementing a feature
1. Run the E2E test — it should PASS now
2. Run ALL existing E2E tests — nothing must break
3. Add visual regression checkpoints (`toHaveScreenshot()`)
4. Add accessibility check (`@axe-core/playwright` or A11y MCP)
5. **Self-review** (from root CLAUDE.md): check test logic, edge cases, selector stability
6. Show results to the designer: passed/failed, screenshot diffs

### Before committing test changes
1. Verify all tests pass (no skipped, no flaky)
2. Verify accessible selectors used (no CSS classes or DOM structure)
3. Verify screenshot baselines are committed
4. Verify no hardcoded test data that would break in other environments

### When the designer describes a user flow
1. Parse the flow into test steps automatically
2. Search the codebase for existing `data-testid`, labels, button text
3. Generate the Playwright test using accessible selectors
4. If selectors are missing, offer to add `data-testid` to the code

## Test patterns

Follow existing test patterns in this directory. Before writing a new test,
read 2-3 existing test files to match the style.

### Storybook component tests

```typescript
// Open a specific story in Storybook iframe
const storyUrl = (id: string) =>
  `http://localhost:6006/iframe.html?id=${id}`;

test('component loading state', async ({ page }) => {
  await page.goto(storyUrl('components-projectcard--loading'));
  await expect(page.getByTestId('skeleton')).toBeVisible();
  await expect(page).toHaveScreenshot('project-card--loading.png');
});
```

Benefits:
- No auth, no database, no seed data needed
- Each state testable independently
- Fast (no page navigation, no API calls)
- Visual regression per state
- Accessibility testable per state

### Flow tests

```typescript
test('create task flow', async ({ page }) => {
  await page.goto('/projects/123');
  await page.getByRole('button', { name: 'New task' }).click();
  await page.getByLabel('Title').fill('Fix header bug');
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByText('Fix header bug')).toBeVisible();
});
```

### Selector priority
1. `data-testid` attributes (most stable)
2. Accessible roles and labels (`getByRole`, `getByLabel`)
3. Text content (`getByText`) — only for static text
4. Never CSS classes or DOM structure

### Visual regression
- Capture at desktop (1280px) and mobile (375px)
- Name screenshots: `component--state--breakpoint.png`
- Review baseline changes with the designer before committing
