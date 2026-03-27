# Onboarding Prompt

> Copy and paste this into Claude Code when starting work on a new client project.

---

I'm a designer joining this project. I need to understand what this product is,
how it works, and what it looks like before I touch anything.

Run the **onboarding** skill. Start by asking me a few questions — then analyze the code.

**First, ask me** (I'll answer what I can):
- Is there a staging/production URL where you can see the live product?
- Is there a Figma file for this project?
- Who else works on this? Who approves design changes?
- What am I here to do? (redesign, new feature, design system cleanup, etc.)
- Any screens or flows I already know are problematic?

**Then analyze the codebase** and build me a complete picture:

1. **Product overview** — what does this product do, who uses it, what's the domain language?
   Search public sources too (company website, Product Hunt, reviews) — mark them as external.

2. **Entity map** — what are the key business objects?
   How do they relate? Where does each appear in the UI? What lifecycle does each go through?

3. **Screen inventory** — screenshot every key page at desktop and mobile.
   Try staging URL first, then local dev, then Storybook. If nothing works, analyze from code.
   For each screen: entities, components, navigation, states handled.

4. **Component graph** — how do components nest inside each other on each page?
   What data does each consume? Where is each reused? Are there duplicates?
   If Storybook exists — inventory all stories and note coverage gaps.

5. **User flows** — what do people actually do? Trace each flow through screens.
   Flag dead ends, missing error handling, broken paths.

6. **Visual language** — what does the design system look like in reality?
   Real colors, fonts, spacing. What's consistent, what's broken, what's missing?

7. **Quality baseline** — run lint, typecheck, tests. Record the starting numbers.
   How many Storybook stories exist? What's the test coverage like?
   This is our baseline — every change must not make it worse.

Place everything in the knowledge base (`design-knowledge/`). Put screenshots in `screenshots/`.

Walk me through the summary first:
- The product in one sentence
- 3-5 key screenshots
- Entity graph
- Top user flows
- Design system health score
- Quality baseline numbers
- What to fix first

Then I'll dig into the details and start editing the vault with my own notes.
