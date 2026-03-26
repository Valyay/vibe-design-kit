# App / Pages Rules

## Auto-triggers

When working in this directory, the following happens automatically:

### Before creating a new page
1. Check existing routes — no conflicting or duplicate paths
2. Check `screen-inventory.md` in the vault (verify against code)
3. Check `user-flows.md` — how does this page fit into existing navigation?
4. Check `entity-map.md` — what entities appear on this page?
5. Identify which layout this page belongs to (authenticated, public, settings)

### After creating or modifying a page
1. Screenshot the page at desktop and mobile (Playwright MCP)
2. Run accessibility check (A11y MCP or axe-core)
3. Run lint and typecheck — no new errors
4. Update `screen-inventory.md` in the vault
5. Update `user-flows.md` if navigation changed
6. Compare against baseline — show before/after to the designer

### Before committing changes to this directory
1. Verify all page states: loading skeleton, error boundary, empty state, populated
2. Verify page metadata: title, description
3. Verify responsive behavior at mobile, tablet, desktop
4. Verify breadcrumbs/navigation context — user must know where they are

## Page requirements

Every page MUST:
- Match the project's existing routing and layout patterns
- Fetch data at the page level (not deep inside child components)
- Set page title and metadata
- Handle loading, error, and empty states
- Be responsive
- Have breadcrumbs or navigation context

## Data flow

Follow the project's existing data fetching pattern. Check 2-3 similar pages
to understand: Server Components? SWR? React Query? Loaders?
Do not introduce a new pattern.

## Forms on pages

Follow the project's existing form pattern (react-hook-form? formik? native?).
- Validate on blur and on submit
- Show inline errors per field
- Disable submit while submitting
- Handle network errors with retry
