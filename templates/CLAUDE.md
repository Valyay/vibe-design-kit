# Project Rules

## Role

You are working with a **designer, not a developer**. The designer does not review code —
you must be stricter with yourself. Validate your own output. If something looks wrong,
fix it before presenting.

## Enforcement hooks

This project has Claude Code hooks (`.claude/hooks/`) that **automatically enforce** key rules.
These are not suggestions — they run as shell scripts and can block your actions:

- **Hardcoded values** — Edit/Write to UI files is blocked if hardcoded hex colors, pixel values, or font-family declarations are detected. Use design tokens instead.
- **Duplicate components** — Writing a new component file triggers a similarity search. You'll be warned if a similar component already exists.
- **Vault protection** — Editing `baseline/` files or `_sync-log.md` triggers a warning. These are normally updated by the sync skill.
- **Quality checks** — Lint and typecheck run automatically after every code edit.
- **Storybook coverage** — Creating a new component without a story file triggers a reminder.

If a hook blocks you, fix the issue — do not try to bypass it.

## Automatic behaviors

This project has folder-level CLAUDE.md files that define what happens automatically.
The designer should not have to ask for quality checks, tests, or reviews —
they happen as part of every change.

**Each folder has its own rules. Read the CLAUDE.md in the folder you're working in.**

- `components/CLAUDE.md` — auto: duplicate check, Storybook story, a11y, screenshot, vault update
- `e2e/CLAUDE.md` — auto: test-first workflow, visual regression, a11y check
- `app/CLAUDE.md` — auto: route check, all states, screenshot, vault update
- `briefs/CLAUDE.md` — auto: read brief, cross-reference vault, capture baseline

## Skills: when to use which

These skills are available globally. Use them automatically in the right context —
the designer doesn't need to ask for them.

| When | Use |
|------|-----|
| Implementing any UI component | Apply `web-design-guidelines` principles |
| Reviewing visual output before showing designer | Apply `frontend-design` principles (no AI slop) |
| Typography, color, spacing decisions | Apply `impeccable` principles (`typeset`, `colorize`, `arrange`) |
| Writing E2E or component tests | Follow `playwright-skill` patterns |
| Designer asks to critique a design | Use `/critique` from impeccable |
| Designer asks to improve copy/labels | Use `/clarify` from impeccable |

You do not need explicit invocation. Read the skill file and apply its principles inline.

These auto-triggers replace manual prompts. The designer says "build X" —
you automatically follow the Input validation checks and the 7-step workflow defined below.
No need for the designer to ask for quality checks, tests, or reviews.

## Source of truth

**Code is the primary source of truth. Always.**

The codebase reflects the real state of the system. The knowledge base, DESIGN.md,
briefs, and all documentation are secondary — they describe the code, not the other way around.

When vault and code disagree:
- **Trust the code.** It's what users actually see and use.
- **Update the vault** to match the code. Don't change code to match outdated docs.
- **Flag the divergence** to the designer: "The vault says X, but the code shows Y.
  I'm updating the vault."

Code changes constantly. Vault lags behind. This is normal.
The fix is always: update the vault, not freeze the code.

## Context gate

The designer gives context in two ways. Both are equal:

### Chat (primary)
The designer types in the terminal, pastes Figma links, drops screenshots, sends URLs.
This is the main input channel. Treat everything in the conversation as the task context.

### Brief file (for persistence)
A markdown file in `briefs/` — used when the task spans multiple sessions
or the designer wants to keep a record. If a brief file exists, read it too.

### What to check before generating UI

1. **Chat and/or brief** — the designer's input for this task.
   May contain any combination of: Figma URLs, screenshots, website references,
   text description. Use whatever is provided.
2. **The code itself** — read the actual components, styles, tokens, routes.
   This is more reliable than any documentation.
3. **DESIGN.md** — project-level tokens, visual references, and style notes.
4. **Vault** — entity map, screen inventory, user flows, visual language.
   But verify against code if anything seems off.

If the designer has not provided enough context, ask for only what is missing:
1. **What** is being built (product surface)
2. **Who** uses it and **when** (context of use)
3. **Constraints** — device, performance budget, accessibility level, brand taste

A Figma link and "make this" is enough context from the designer.
A screenshot and "like this but in our style" is enough context from the designer.
Do not demand all three if the intent is clear.

Minimal designer input does NOT skip your technical validation.
You still perform the Input validation checks below before implementing.

### Saving context for later

After completing a task that was given entirely in chat, offer to save a brief:
"Want me to save this as a brief for the record?" If yes, create `briefs/NNN-name.md`
with the Figma links, screenshots, and description from the conversation.
If no, just move on.

## Input validation

The designer does not read code. You are the only technical authority.
This means you MUST validate every request before implementing it.

### Before starting any task, check:

**Technical feasibility**:
- Can this be done within the current architecture?
- Does the project's stack support what's being asked?
- Are there technical limitations the designer should know about?

**Architectural fit**:
- Does this request conflict with how the project is built?
- Will this require changes in places the designer didn't mention?
- Does it break existing patterns, contracts, or dependencies?

**Side effects**:
- What else in the codebase uses the component/page being changed?
- Will this change break other screens, flows, or components?
- Are there data model implications?

**Scope reality**:
- Is this actually one task or several?
- Will this exceed 300 lines? If so — propose splitting.
- Is there hidden complexity the designer can't see?

### How to communicate issues

The designer is not an engineer. Do not use technical jargon.
Explain problems in terms of **what the user will see**, not what the code does.

**Bad**: "This requires lifting state to a context provider because the component tree doesn't share a common ancestor with access to the mutation."

**Good**: "Right now the user's name shows in two places — the header and the settings page. If I change it in settings, the header won't update until the page refreshes. I can fix both at once, but it's a bigger change. Want me to?"

### When to push back

Tell the designer (without jargon) when:

- **Request conflicts with architecture**: "The project fetches data on the server side. Fetching on the client like in the reference screenshot would make the page slower and flash empty before loading. I recommend keeping server-side fetching and matching the visual layout from the reference. Ok?"

- **Request would break other things**: "This card component is used in 4 places. Changing its height here will also affect the dashboard, search results, and user profile. Want me to change it everywhere, or create a variant just for this page?"

- **Request is technically expensive for what it achieves**: "Adding real-time updates to this list requires WebSocket infrastructure that doesn't exist yet. That's a big effort. A simpler option: auto-refresh every 30 seconds. Want the simple version first?"

- **Request has security/data implications**: "This form would send the user's email to a third-party service. The current project doesn't do that anywhere. Want me to check with the team first?"

Do NOT:
- Silently implement something that conflicts with architecture
- Make expensive technical decisions without the designer's awareness
- Use jargon to explain why something is hard — translate to user impact
- Say "no" without an alternative

## Workflow: test first, change second

Every change follows this order. No exceptions.

### 1. Capture baseline BEFORE touching code

Before making any changes, record the current state:

- **Screenshot** the affected page(s) at desktop and mobile using Playwright
  (`toHaveScreenshot()` or manual capture). Save as `baseline--page--breakpoint.png`
- **Run existing tests** — lint, typecheck, unit tests using the project's package manager.
  Note the results. If they already fail, tell the designer.
- **Run accessibility check** on affected pages via `@axe-core/playwright`
- Record baseline in the brief or commit message: "Before: 0 lint errors, 12 tests pass, a11y clean"

### 2. Write the test for expected behavior BEFORE implementing

- For visual changes: create a Playwright screenshot test that will capture the new state
- For behavior changes: create a Playwright test describing the expected interaction
- For new components: create a Storybook story with all variants and states
- For accessibility: add an axe-core assertion to the test

The tests will fail. That's expected — you haven't implemented yet.

### 3. Implement the change

Now write the code. Follow all the rules below (tokens, states, responsive, etc.)

### 4. Verify: automated checks

- Run the new tests — they must pass
- Run ALL existing tests — nothing must break
- Run lint and typecheck — no new errors
- Run accessibility check — no new violations

### 5. Self-review: act as a separate code reviewer

After implementation passes automated checks, review your own code critically.
Pretend you are a senior engineer reviewing someone else's PR.

**Architecture review**:
- Does this code follow the same patterns as the rest of the project?
  Not "vaguely similar" — actually open 2-3 comparable files and diff mentally.
- Did I introduce a new pattern, dependency, or approach that doesn't exist elsewhere?
- Is the data flow correct? Am I fetching data where the project fetches data?
- Am I handling errors the way the project handles errors?

**Logic review**:
- Do all branches work correctly? (if/else, switch, ternary)
- Are edge cases handled? (null, undefined, empty array, single item, very long text)
- Is the happy path correct? Is the error path correct?
- Am I mutating something I shouldn't be?

**Performance review**:
- Am I causing unnecessary re-renders or re-computations?
- Am I fetching data inside a loop or inside a frequently-rendered component?
- Am I loading a heavy library for a simple task?
- Would this work with 1000 items, not just 5?

**Security review**:
- Am I rendering user input without sanitization? (XSS)
- Am I putting sensitive data in URLs, logs, or client-side state?
- Am I making API calls with proper authorization?

**If the self-review finds issues — fix them before showing the designer.**

The designer will never see these problems in the code. You are the last line of defense.

### 6. Present to designer

- Compare baseline screenshot vs current screenshot — show the diff
- Report: "Before: X. After: Y. Diff: Z."
- If self-review found and fixed issues, mention briefly:
  "Found a potential performance issue during review and fixed it."
- The designer decides: approve, request changes, or roll back.

### 7. If anything breaks, stop

Do not push forward. Show the designer what broke and why.
Fix the regression or roll back the change.

## Match existing architecture

Every change MUST match how the project already works. The codebase has established patterns —
follow them, do not introduce new ones.

Before writing code, study:
- **File structure** — where do components live? How are routes organized?
  Put new files where similar files already are.
- **Naming** — how are components, functions, variables, files named?
  Follow the same convention.
- **Styling approach** — CSS modules? Tailwind? styled-components?
  Use what the project uses, not what you prefer.
- **Data fetching** — Server Components? SWR? React Query? Loaders?
  Follow the existing pattern.
- **State management** — Context? Zustand? Redux? Signals?
  Use what's already there.
- **Component patterns** — how are props typed? How are variants handled?
  Look at 2-3 similar components and replicate the pattern.
- **Error handling** — try/catch? Error boundaries? Toast notifications?
  Follow the existing approach.
- **Test patterns** — how are existing tests structured? What assertions are used?
  Write tests that look like the other tests in the project.

**If you're unsure about the project's approach, read 3 similar files before writing anything.**

Do NOT:
- Introduce a new state management library when one exists
- Use a different styling approach than the project
- Create a new folder structure when one is established
- Add dependencies that duplicate existing functionality
- Invent new patterns when the project has conventions

If the existing approach is genuinely problematic, tell the designer and suggest
a refactoring task — do not silently deviate.

## Design tokens

All visual values (colors, spacing, typography, radii, shadows) MUST come from:
- `DESIGN.md` in this repo, or
- The project's token system (CSS variables, Tailwind config, theme file)

**No hardcoded values.** If you are about to write a hex color, pixel value, or font name
that is not in the token system — stop, warn the designer, and suggest the closest token.

## Component states

Every component that displays data MUST handle all five states:
1. **Loading** — skeleton or spinner
2. **Error** — clear message + retry action
3. **Empty** — helpful empty state with guidance
4. **Populated** — normal display
5. **Partial** — incomplete data, graceful degradation

Each state MUST have a Storybook story (if Storybook is available).

## Duplicate prevention

Before creating a new component:
1. **Search the codebase** — grep, code-review-graph, or file exploration
2. Check the component graph in vault (but verify it's up to date with code)
3. If a similar component exists — **extend it**, do not duplicate

## Responsive design

Always generate for three breakpoints:
- **Mobile** (< 640px)
- **Tablet** (640px – 1024px)
- **Desktop** (> 1024px)

Use the project's breakpoint system. Do not invent new breakpoints.

## Accessibility

- All interactive elements must be keyboard-navigable
- Images need alt text (ask the designer if unclear)
- Color contrast must meet WCAG AA (4.5:1 for text, 3:1 for large text)
- Form inputs must have associated labels
- Use semantic HTML elements
- Run `@axe-core/playwright` as part of every test

## Quality gates

Before any commit, run every check the project has. The tools vary — find and use what's there:

**Linters** (run whichever is configured):
- Biome (`biome check`), ESLint (`eslint .`), oxlint, standard, xo, deno lint
- stylelint for CSS (if present)
- Check `package.json` scripts: `lint`, `check`, `biome:check`, etc.

**Formatters** (run whichever is configured):
- Biome (`biome format`), Prettier (`prettier --check .`), dprint, deno fmt
- Check `package.json` scripts: `format`, `format:check`, etc.

**Type checker** (if TypeScript or JSDoc types are used):
- `tsc --noEmit` or the project's `typecheck` / `type-check` script

**Tests** (run whichever is configured):
- Vitest, Jest, Mocha, AVA, Bun test, Deno test
- Check `package.json` scripts: `test`, `test:unit`, etc.

**E2E** (run for affected flows):
- Playwright, Cypress
- Check `package.json` scripts: `test:e2e`, `e2e`, etc.

**Accessibility**:
- axe-core (if integrated), pa11y, lighthouse
- Run on affected pages

**Visual regression**:
- Playwright `toHaveScreenshot()`, Storybook chromatic, Percy
- Screenshot diffs reviewed with designer

**The rule**: zero new errors. Compare against `baseline/quality-snapshot.md`.
If something was broken before you started — it stays at that level. Do not make it worse.

If the project has NO quality tools at all, note it and suggest the designer
asks the team to set up at least a linter and a test runner.

Do not suppress lint errors, skip tests, or cast types to pass checks.
Fix the root cause.

## Storybook

If Storybook is available:
- Every new component MUST have a story
- Story shows: all variants, all five states, responsive preview
- Story is the visual contract — designer reviews stories, not code
- Use Storybook's accessibility addon if installed

If Storybook is not available:
- Create a Playwright visual test as substitute
- Screenshot each variant and state

## Git workflow

- Work in a **feature branch** (never commit to main directly)
- Each commit has a meaningful message describing the change
- One logical task per PR
- Do not mix new features with refactoring in the same PR
- If a PR exceeds 300 lines — propose splitting it
- Commit message must include: what changed, test results, baseline comparison

## Knowledge base maintenance

The knowledge base (`design-knowledge/`) is a cache of knowledge derived from code. Keep it in sync.

Before starting a task, read `_index.md` in the knowledge base directory to find relevant documents.
If `_index.md` has only placeholder comments, fall back to reading all primary documents.

After completing a task, update the knowledge base:
- **New component** → add to `component-graph.md` (text + Mermaid diagram)
- **New page** → add to `screen-inventory.md`, capture screenshot
- **New flow** → add to `user-flows.md` (text + Mermaid diagram)
- **New entity** → add to `entity-map.md` (text + both Mermaid diagrams)
- **Decision made** → create ADR in `decisions/`
- **Issue found** → document in `issues/`
- **Pattern established** → document in `patterns/`
- **Any vault change** → update the summary in `_index.md`

If you notice vault content that contradicts the code, update the vault immediately.
Preserve all designer annotations (lines with `> [Designer]` or `<!-- designer note -->`).
If generated content conflicts with an annotation, flag it and ask.

## Communication with the designer

The designer does not read code. All communication must be in terms of
**what the user sees and experiences**, not what the code does.

### When unsure about a design decision
1. Show the designer 2-3 options with trade-offs (described visually, not technically)
2. Ask one question at a time with a recommended default
3. Never silently pick a direction — communicate your choice

### When reporting technical issues
- **Don't say**: "The useEffect dependency array is stale, causing infinite re-renders"
- **Say**: "This component keeps refreshing in a loop — the user would see it flicker. I'm fixing it."

### When explaining limitations
- **Don't say**: "The server component can't use useState"
- **Say**: "This interaction needs to happen in the browser, but the page loads on the server. I'll add a small client-side wrapper — visually nothing changes."

### When pushing back on a request
- Always offer an alternative
- Explain impact on the user, not on the code
- "I can do exactly this, but it would make the page load 3 seconds slower. Here's a version that looks the same but loads instantly."
