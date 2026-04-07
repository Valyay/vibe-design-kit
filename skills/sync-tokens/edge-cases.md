# Edge Cases

Reference for handling non-standard situations during token reconciliation.

## Figma not connected

Work with DESIGN.md ↔ Code only. Note: "Figma MCP is not connected.
I can only compare DESIGN.md and code. Connect Figma in Settings > MCP for full sync."

## DESIGN.md is empty (all placeholders)

Offer to populate from code: "DESIGN.md has no real values yet.
Want me to fill it in from the code's current tokens?"

## No token system in code

The project uses only hardcoded values. Report this:
"No token system found in code. All values are hardcoded.
Want me to generate a token file from DESIGN.md? I'll create the file and
show you what to set up."

## Multiple token files in code

List all sources and ask: "I found tokens in 3 places:
- `src/styles/globals.css` (CSS variables)
- `tailwind.config.ts` (Tailwind theme)
- `src/theme/tokens.ts` (JS object)

Which is the primary source? The others might be duplicates or layers."

## Dark mode / multiple modes

Figma may have multiple modes (light/dark). Check DESIGN.md's `## Theming` section first.

**If `## Theming` is present**: compare Figma dark mode tokens against the "Dark mode overrides"
table. Report drift the same way as light mode tokens.

**If `## Theming` is absent**: offer to add it:
"Figma has light and dark mode tokens but DESIGN.md has no Theming section yet.
Want me to add it and fill in the dark mode overrides?"

**If Figma is not connected**: check whether code has a `.dark { }`, `[data-theme="dark"] { }`,
or `prefers-color-scheme: dark` block. If yes, offer to populate the Theming section from code:
"Code has a dark mode override block. Want me to fill in DESIGN.md's Theming section from it?"

Always report each mode separately in the reconciliation report (Step 4).

## Token naming mismatch

Figma uses `colors/primary/500`, code uses `--color-primary`.
Show the mapping and ask: "Figma names don't match code names exactly.
Here's how I'd map them — does this look right?"

| Figma name | → | Code token |
|---|---|---|
| `colors/primary/500` | → | `--color-primary` |
| `colors/primary/600` | → | `--color-primary-hover` |
| `spacing/md` | → | `--space-4` |
