# Components Rules

## Auto-triggers

When working in this directory, the following happens automatically:

### Before creating a new component
1. **Input validation** (from root CLAUDE.md): check feasibility, architectural fit,
   side effects (who else uses this component?), scope
2. Search the codebase for similar components (grep, code-review-graph)
3. Check `component-graph.md` in the knowledge base (verify against code)
4. If a similar component exists → tell the designer and suggest extending it
5. Run `impeccable` or `web-design-guidelines` skill to validate the design approach

### After creating or modifying a component
1. Create or update Storybook stories (see "Storybook + E2E pipeline" below)
2. Write E2E tests against each story (see pipeline below)
3. Run lint and typecheck — no new errors
4. Run accessibility check (axe-core or A11y MCP)
5. **Self-review** (from root CLAUDE.md): architecture, logic, performance, security
6. Screenshot the component at desktop and mobile (Playwright MCP)
7. Update `component-graph.md` in the knowledge base if the component is new
8. Compare against baseline — show before/after to the designer

### Before committing changes to this directory
1. Verify all five states have Storybook stories AND passing E2E tests
2. Verify no hardcoded visual values (use design tokens)
3. Verify responsive behavior at mobile, tablet, desktop
4. Verify accessibility check passes for each story

## Storybook + E2E pipeline

Every component with data goes through this pipeline:

```
Component → Storybook stories (per state) → Playwright tests (per story) → Verified
```

### Step 1: Create Storybook stories

Each data-displaying component MUST have a story for every state:

```typescript
// project-card.stories.tsx
export const Loading: Story = { args: { isLoading: true } };
export const Error: Story = { args: { error: "Failed to load project" } };
export const Empty: Story = { args: { project: null } };
export const Populated: Story = { args: { project: sampleProject } };
export const Partial: Story = { args: { project: { ...sampleProject, description: undefined } } };
```

Plus variant stories if the component has variants:
```typescript
export const CardView: Story = { args: { variant: "card", project: sampleProject } };
export const ListRow: Story = { args: { variant: "row", project: sampleProject } };
```

Plus responsive stories:
```typescript
export const Mobile: Story = { parameters: { viewport: { defaultViewport: "mobile1" } }, args: { project: sampleProject } };
```

### Step 2: Write E2E tests against Storybook stories

Playwright tests open each story in isolation — no app, no auth, no database:

```typescript
// project-card.spec.ts
import { test, expect } from '@playwright/test';

const storyUrl = (story: string) =>
  `http://localhost:6006/iframe.html?id=components-projectcard--${story}`;

test.describe('ProjectCard', () => {
  test('loading state shows skeleton', async ({ page }) => {
    await page.goto(storyUrl('loading'));
    await expect(page.getByTestId('skeleton')).toBeVisible();
    await expect(page).toHaveScreenshot('project-card--loading.png');
  });

  test('error state shows message and retry', async ({ page }) => {
    await page.goto(storyUrl('error'));
    await expect(page.getByText('Failed to load project')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible();
  });

  test('empty state shows guidance', async ({ page }) => {
    await page.goto(storyUrl('empty'));
    await expect(page.getByText(/no project/i)).toBeVisible();
  });

  test('populated state shows all data', async ({ page }) => {
    await page.goto(storyUrl('populated'));
    await expect(page.getByText('Sample Project')).toBeVisible();
    await expect(page).toHaveScreenshot('project-card--populated.png');
  });

  test('partial data degrades gracefully', async ({ page }) => {
    await page.goto(storyUrl('partial'));
    // description is missing — should not crash
    await expect(page.getByText('Sample Project')).toBeVisible();
  });

  test('is accessible in all states', async ({ page }) => {
    for (const story of ['loading', 'error', 'empty', 'populated', 'partial']) {
      await page.goto(storyUrl(story));
      const results = await new AxeBuilder({ page }).analyze();
      expect(results.violations).toEqual([]);
    }
  });
});
```

### Why this matters

- **Isolated testing** — no need to set up the whole app, auth, or seed data
- **Every state verified** — loading, error, empty, populated, partial all tested
- **Visual regression** — `toHaveScreenshot()` catches unintended changes
- **Accessibility per state** — axe-core runs on each state, not just populated
- **Designer reviews stories** — Storybook is the visual contract, not code

### If Storybook is not available

Fall back to Playwright component testing or Playwright visual tests:
- Create a test file that renders the component directly
- Test each state with screenshots
- This is less convenient but achieves the same coverage

## Component requirements

Every component MUST:
- Match the project's existing patterns (study 2-3 similar components first)
- Use only design tokens from DESIGN.md or the project's theme
- Handle all five states (if it displays data)
- Have Storybook stories for each state (or Playwright visual tests if no Storybook)
- Have E2E tests verifying each story
- Be responsive for mobile, tablet, desktop
- Be keyboard-navigable and accessible

## File placement

Follow the project's existing component structure. If unsure, check where
similar components are placed and replicate the pattern.

## Naming

Follow the project's existing naming convention. Check 3 existing component
files before naming a new one.
