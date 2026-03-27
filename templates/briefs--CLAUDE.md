# Briefs Rules

Briefs are **optional**. The designer may work entirely through chat.

## Auto-triggers

When the designer gives a task (in chat or as a brief file), the following happens automatically:

### On receiving any task input
1. Read all provided references:
   - Figma URL → read via Figma MCP
   - Screenshot / image → analyze visually
   - Website URL → fetch and study the visual approach
   - Text → follow the description and constraints
2. Cross-reference with DESIGN.md tokens and component graph
3. Verify against the actual code (code is source of truth, not vault)
4. **Input validation** (from root CLAUDE.md): check feasibility, architectural fit,
   side effects, scope. If there's a problem — tell the designer before proceeding.
5. Capture baseline (screenshots + tests) BEFORE making changes
6. Write test for expected behavior BEFORE implementing
7. Implement
8. **Self-review** (from root CLAUDE.md): architecture, logic, performance, security
9. Verify: test passes, baseline not worse, show diff to designer

### After completing a task
1. Offer to save context as a brief (if work was done entirely in chat)
2. Update vault documents that were affected
3. Show the designer: what changed, test results, before/after screenshots

## Two input modes

### Chat (primary)
The designer types in the terminal: pastes Figma links, drops screenshots,
sends website URLs, describes what they want. This is the default way to work.

### Brief files (for persistence)
A markdown file in this directory. Used when:
- The task spans multiple sessions
- The designer wants a record
- Someone else needs to pick up the work

Do not ask the designer to create a brief file. If they're chatting, they want to chat.

## When to suggest saving a brief

After completing a chat-only task, offer **once**:
"Want me to save this as a brief for the record?"

Save if:
- The conversation contained Figma links or screenshots worth keeping
- The task might need follow-up in a future session
- The designer explicitly says yes

Don't save if:
- It was a quick fix or small change
- The designer says no or ignores the offer

## How a designer creates a brief file (when they choose to)

1. Copy `_template.md` → rename to `NNN-short-name.md`
2. Write one sentence in **What** (only required field)
3. Add any references: Figma links, screenshots in `assets/`, URLs, text
4. Tell you: "Work on brief 001"

See `examples/` for five real briefs showing different combinations.

## Priority when references conflict

Between reference types:
1. **Figma** — highest priority (precise design intent)
2. **Screenshots** — visual reference, may not be pixel-perfect
3. **Websites** — inspiration, adapt to project's system
4. **Text** — constraints and clarification

Between references and design system:
- **DESIGN.md tokens** win for colors, spacing, typography
- **Reference** wins for layout, composition, visual hierarchy
- Real conflict → ask the designer

## File naming (when using brief files)

- Brief: `NNN-short-name.md` (e.g., `001-hero-section.md`)
- Assets: `assets/NNN-description.png` (e.g., `assets/002-stripe-pricing.png`)
- Done: move to `done/` or add `## Status: Done` at the top
