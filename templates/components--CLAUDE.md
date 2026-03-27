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
1. Create or update a Storybook story (if Storybook is available)
   - Show all variants, all five states, responsive preview
   - Use Storybook MCP to verify the story renders correctly
2. Run lint and typecheck — no new errors
3. Run accessibility check (axe-core or A11y MCP)
4. **Self-review** (from root CLAUDE.md): architecture, logic, performance, security
5. Screenshot the component at desktop and mobile (Playwright MCP)
6. Update `component-graph.md` in the knowledge base if the component is new
7. Compare against baseline — show before/after to the designer

### Before committing changes to this directory
1. Verify all five states exist for data-displaying components:
   loading, error, empty, populated, partial
2. Verify no hardcoded visual values (use design tokens)
3. Verify responsive behavior at mobile, tablet, desktop
4. Verify Storybook story exists and covers key variants

## Component requirements

Every component MUST:
- Match the project's existing patterns (study 2-3 similar components first)
- Use only design tokens from DESIGN.md or the project's theme
- Handle all five states (if it displays data)
- Be responsive for mobile, tablet, desktop
- Be keyboard-navigable and accessible
- Have a Storybook story (or Playwright visual test if no Storybook)

## File placement

Follow the project's existing component structure. If unsure, check where
similar components are placed and replicate the pattern.

## Naming

Follow the project's existing naming convention. Check 3 existing component
files before naming a new one.
