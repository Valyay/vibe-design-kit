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

Figma may have multiple modes (light/dark). Report each mode separately:
"Figma has light and dark mode tokens. Code only has light mode.
Want me to generate dark mode tokens too?"

## Token naming mismatch

Figma uses `colors/primary/500`, code uses `--color-primary`.
Show the mapping and ask: "Figma names don't match code names exactly.
Here's how I'd map them — does this look right?"

| Figma name | → | Code token |
|---|---|---|
| `colors/primary/500` | → | `--color-primary` |
| `colors/primary/600` | → | `--color-primary-hover` |
| `spacing/md` | → | `--space-4` |
