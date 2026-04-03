# Token Sources Reference

How to detect, read, and normalize tokens from each source type.

## Figma Variables

Call `get_variable_defs` with the fileKey and a root nodeId.
Figma returns variable collections with:
- Variable name (e.g., `colors/primary`, `spacing/md`)
- Value per mode (light mode, dark mode)
- Variable type (COLOR, FLOAT, STRING)

Normalize Figma variable names to CSS token format:
- `colors/primary` → `--color-primary`
- `spacing/md` → `--space-md` (or closest match)
- `radius/lg` → `--radius-lg`

If the project uses Tailwind naming, also map to Tailwind equivalents:
- `--color-primary` → `colors.primary`
- `--space-4` → `spacing.4`

## DESIGN.md

Parse each token table (Colors, Typography, Spacing, Border radius, Shadows).
Extract rows where the Value column is not a placeholder comment.

Build a flat map: `{ token_name → { value, usage, section } }`

## Code tokens

### Detection order

1. **CSS custom properties** — files matching `*.css` that contain `--color-*`, `--space-*`, `--font-*`, `--radius-*`, `--shadow-*`
2. **Tailwind config** — `tailwind.config.{js,ts,mjs,cjs}`, look in `theme.extend` and `theme.colors`
3. **Theme objects** — `theme.{ts,js}`, `tokens.{ts,js}`, `design-tokens.{ts,js}` in common paths (`src/`, `styles/`, `lib/`)
4. **CSS-in-JS** — `styled-components` ThemeProvider, Stitches tokens, Panda CSS tokens

### Parsing rules

- CSS: `:root { --color-primary: #3B82F6; }` → `--color-primary = #3B82F6`
- Tailwind: `colors: { primary: '#3B82F6' }` → `--color-primary = #3B82F6`
- Theme object: `export const colors = { primary: '#3B82F6' }` → `--color-primary = #3B82F6`

Build a flat map: `{ token_name → { value, file, line } }`

## Value equivalence rules

When comparing values across sources, treat these as equivalent:
- `#3B82F6` and `rgb(59, 130, 246)` and `hsl(217, 91%, 60%)`
- `1rem` and `16px` (assuming default font size)
- `0.5rem` and `8px`
- Color values that differ by ≤ 2 in any RGB channel (rounding from Figma)

When values are equivalent but in different formats, mark as `≈` and note the format difference.
