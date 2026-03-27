# App / Pages Rules

## Auto-triggers

When working in this directory, the following happens automatically:

### Before creating a new page
1. **Input validation** (from root CLAUDE.md): check feasibility, architectural fit
   (new layout needed? new auth? new data source?), side effects, scope
2. Check existing routes — no conflicting or duplicate paths
3. Check `screen-inventory.md` in the knowledge base (verify against code)
4. Check `user-flows.md` — how does this page fit into existing navigation?
5. Check `entity-map.md` — what entities appear on this page?
6. Identify which layout this page belongs to (authenticated, public, settings)

### After creating or modifying a page
1. Screenshot the page at desktop and mobile (Playwright MCP)
2. Run accessibility check (A11y MCP or axe-core)
3. Run lint and typecheck — no new errors
4. **Self-review** (from root CLAUDE.md): architecture, logic, performance, security
5. Update `screen-inventory.md` in the knowledge base
6. Update `user-flows.md` if navigation changed
7. Compare against baseline — show before/after to the designer

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
