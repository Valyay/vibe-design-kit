---
name: onboarding
description: Analyze an existing codebase and produce a designer-friendly knowledge base with product overview, entity map, screen inventory, component graph, user flows, and visual language audit. Use when a designer joins a new project, says "onboard me", "I'm new to this codebase", needs a design handoff, or no documented overview exists.
---

# Onboarding Skill

Produces six documents: `product-overview.md`, `entity-map.md`, `screen-inventory.md`, `component-graph.md`, `user-flows.md`, `visual-language.md` — plus `_index.md`, `token-audit.md`, `architecture.md`, `baseline/quality-snapshot.md`.

See `references/output-templates.md` for exact format of each document.

## Step 0: Ask the designer what code can't tell you

Before analyzing code, ask these questions (accept whatever they can answer, skip the rest):

- **Team/process**: Who works on this? What's the release process?
- **Access**: Staging/production URL? Storybook? Test credentials?
- **Design artifacts**: Figma file URL? Previous design decisions?
- **Scope**: What are you here to do? (redesign, new feature, design system, ongoing support)

Store answers in `product-overview.md` under "Designer context".
If the designer says "just analyze the code" — proceed, come back to questions later.

## Step 1: Understand the product

**From codebase** (primary): README, meta tags, UI copy, user roles, API routes, database models/types.

**From public sources** (secondary, if not NDA-protected): company website, Product Hunt, G2, blog posts. Mark clearly: `> [External source: ...] description`.

Output → `product-overview.md`

## Step 2: Map the entities

Trace business entities from: database schema/ORM models, TypeScript types, API responses, form fields, URL structure (what gets an ID is an entity).

For each entity document: name, plain-language meaning, designer-relevant fields, lifecycle states, UI locations, user actions. Add Mermaid relationship diagrams.

Output → `entity-map.md`

## Step 3: Screenshot every screen

Try in order, use the first that works:

1. **Staging/production URL** (from Step 0) → Playwright capture
2. **Local dev server** → start and capture all routes
3. **Storybook** → capture every story for component catalog
4. **Static analysis only** → infer from JSX/CSS, flag as incomplete

```bash
# Discover routes
find src/app -name 'page.tsx' -o -name 'page.ts' | sed 's|src/app||;s|/page\.tsx\?||' | sort

# Playwright capture at two viewports
npx playwright screenshot --viewport-size=1280,800 "$URL" "screenshots/${name}--desktop.png"
npx playwright screenshot --viewport-size=375,812 "$URL" "screenshots/${name}--mobile.png"
```

Always try Storybook in addition to pages if available (pages = integration, Storybook = anatomy).

Output → `screen-inventory.md` + `screenshots/` directory

## Step 4: Build the component graph

Scan all UI components. For each, trace: usage locations, props (→ entity fields), child components, interactions (click → navigate, submit → API).

Group by role: Layout, Navigation, Data display, Data input, Feedback, Atoms.
Note: status, variants, implemented states, design issues.

Output → `component-graph.md`

## Step 5: Trace user flows

Combine screen inventory + entity map + component graph to reconstruct user journeys.
Read navigation structure, trace link targets and form submissions, identify CRUD flows per entity and cross-entity flows.

Flag missing flows (no delete? no 403 handling?).

Output → `user-flows.md`

## Step 6: Document the visual language

Extract what the product actually looks like from code and screenshots:
- Colors: from tokens (good), hardcoded but consistent (fixable), inconsistent (problem)
- Typography: fonts loaded, sizes used, inconsistencies
- Spacing: common gaps, consistency
- Component styling: real examples of buttons, cards, forms, tables, empty states
- Consistency report: what's good, broken, missing

Output → `visual-language.md` (reference raw data in `token-audit.md`)

## Step 7: Generate supporting files

- **token-audit.md** — raw token/hardcoded value data, referenced from visual-language.md
- **architecture.md** — tech stack, project structure, build tools, testing setup
- **baseline/quality-snapshot.md** — run checks and record starting counts:

```bash
npm run lint 2>&1 | tail -5
npx tsc --noEmit 2>&1 | tail -5
npm run test -- --run 2>&1 | tail -5
```

Record: lint (N errors, N warnings), TypeScript (N errors), tests (N pass, N fail).
If quality infrastructure is missing, note it clearly.

## Step 7b: Populate DESIGN.md from code

Use visual-language.md and token-audit.md to pre-fill DESIGN.md.
See `references/design-md-autofill.md` for classification rules and section mapping.

If the designer has a Figma file with variables, suggest running `vdk-sync-tokens` after onboarding.

## Step 8: Storybook inventory (if available)

If Storybook is installed: list all stories, screenshot each, note coverage gaps.
Feed into component-graph.md: "documented", "fully documented", or "needs story".
If not installed, skip and note in component-graph.md.

## Step 9: Generate the master index

Create `_index.md` — single entry point for AI and designers:
1. Primary documents table with concrete summaries and dates
2. Supporting reference table
3. Detail layer table
4. Quick lookup: each entity → its screens, components, flows
5. Designer annotations count

Summaries must be concrete: "5 entities (Org, Project, Task, User, Comment)" not "Entity relationships".

## Step 10: Present to the designer

Do NOT dump files. Present a guided walkthrough:

1. The product in one sentence
2. Key screenshots (3-5)
3. Main entities and how they connect (show graph)
4. Top user flows
5. Design system health: what's working, what's broken
6. Code quality baseline
7. DESIGN.md status: N auto-filled, N inconsistent, N missing
8. Tooling gaps and recommendations (see `references/recommended-tools.md`)
9. Recommended first actions: quick wins, larger fixes, quality gaps, needs discussion

Tell the designer where each file is and what question it answers.

## Output location

Place files in the knowledge base project directory if configured, or `design-knowledge/` at project root. Screenshots in `screenshots/` subdirectory. When code changes later, update via the sync skill.
