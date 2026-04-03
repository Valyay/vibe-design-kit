# DESIGN.md Auto-Fill Rules

After generating `visual-language.md` and `token-audit.md`, use them to pre-fill DESIGN.md.

## Three-tier classification

| Marker | Condition | Action |
|--------|-----------|--------|
| `[auto-filled]` | Value from token system, used consistently | Fill and mark for designer review |
| `[inconsistent]` | Multiple values for same purpose | List all variants, ask designer to pick |
| `[missing]` | No value exists in code | Mark so designer knows it's intentional |

## Sections to auto-fill

| DESIGN.md section | Source |
|-------------------|--------|
| Brand | Product name from `<title>`, README, or `package.json`. Voice/logo: leave blank |
| Colors — Primary | Tokenized colors from token-audit.md |
| Colors — Semantic | Success, warning, error, info tokens |
| Colors — Neutrals | Background, surface, border, text tokens |
| Typography | Font families from `@font-face`/Google Fonts, sizes from tokens |
| Spacing | Spacing scale from Tailwind config or CSS variables |
| Border radius | Radius tokens |
| Shadows | Shadow tokens |
| Breakpoints | From Tailwind config or media queries |
| Animation | Duration/easing from CSS variables or transition patterns |

## Sections to NOT auto-fill (require designer intent)

Component guidelines, visual references, Figma links, designer notes.

## After populating

Report to designer: N auto-filled, N inconsistent (pick one), N missing (fill or skip).
Tell them to search for `[auto-filled]`, `[inconsistent]`, `[missing]` in DESIGN.md.
