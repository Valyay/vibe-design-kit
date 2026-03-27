# Visual Identity

> Fill in this file with the project's design intent: tokens and visual guidelines.
> When this file and the code's token system disagree, the code wins — flag the discrepancy.
> Delete the placeholder comments as you fill in real values.

## Brand

- **Product name**: <!-- e.g. Acme Dashboard -->
- **Brand voice**: <!-- e.g. professional but friendly, minimal, playful -->
- **Logo**: <!-- path to logo file or Figma link -->

## Colors

### Primary palette

<!-- Define your main colors as CSS custom properties or Tailwind values -->

| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | <!-- #3B82F6 --> | Primary actions, links |
| `--color-primary-hover` | <!-- #2563EB --> | Hover state |
| `--color-secondary` | <!-- #6B7280 --> | Secondary actions |
| `--color-accent` | <!-- #F59E0B --> | Highlights, badges |

### Semantic colors

| Token | Value | Usage |
|-------|-------|-------|
| `--color-success` | <!-- #10B981 --> | Success states |
| `--color-warning` | <!-- #F59E0B --> | Warnings |
| `--color-error` | <!-- #EF4444 --> | Errors, destructive |
| `--color-info` | <!-- #3B82F6 --> | Informational |

### Neutrals

| Token | Value | Usage |
|-------|-------|-------|
| `--color-bg` | <!-- #FFFFFF --> | Page background |
| `--color-surface` | <!-- #F9FAFB --> | Card/section background |
| `--color-border` | <!-- #E5E7EB --> | Borders, dividers |
| `--color-text` | <!-- #111827 --> | Primary text |
| `--color-text-secondary` | <!-- #6B7280 --> | Secondary text |
| `--color-text-muted` | <!-- #9CA3AF --> | Disabled, placeholder |

## Typography

| Token | Font | Size | Weight | Line height | Usage |
|-------|------|------|--------|-------------|-------|
| `--font-heading` | <!-- Inter --> | — | — | — | Font family for headings |
| `--font-body` | <!-- Inter --> | — | — | — | Font family for body text |
| `--text-h1` | — | <!-- 2.25rem --> | <!-- 700 --> | <!-- 1.2 --> | Page titles |
| `--text-h2` | — | <!-- 1.5rem --> | <!-- 600 --> | <!-- 1.3 --> | Section headings |
| `--text-h3` | — | <!-- 1.25rem --> | <!-- 600 --> | <!-- 1.4 --> | Sub-headings |
| `--text-body` | — | <!-- 1rem --> | <!-- 400 --> | <!-- 1.5 --> | Default text |
| `--text-small` | — | <!-- 0.875rem --> | <!-- 400 --> | <!-- 1.5 --> | Captions, labels |

## Spacing

<!-- Use a consistent spacing scale. Example: 4px base unit -->

| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | <!-- 0.25rem (4px) --> | Tight gaps |
| `--space-2` | <!-- 0.5rem (8px) --> | Small gaps |
| `--space-3` | <!-- 0.75rem (12px) --> | Form spacing |
| `--space-4` | <!-- 1rem (16px) --> | Default gap |
| `--space-6` | <!-- 1.5rem (24px) --> | Section spacing |
| `--space-8` | <!-- 2rem (32px) --> | Large spacing |
| `--space-12` | <!-- 3rem (48px) --> | Page sections |

## Border radius

| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | <!-- 0.25rem --> | Small elements (badges) |
| `--radius-md` | <!-- 0.5rem --> | Default (buttons, inputs) |
| `--radius-lg` | <!-- 0.75rem --> | Cards, dialogs |
| `--radius-full` | <!-- 9999px --> | Avatars, pills |

## Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | <!-- 0 1px 2px rgba(0,0,0,0.05) --> | Subtle elevation |
| `--shadow-md` | <!-- 0 4px 6px rgba(0,0,0,0.1) --> | Cards, dropdowns |
| `--shadow-lg` | <!-- 0 10px 15px rgba(0,0,0,0.1) --> | Modals, popovers |

## Breakpoints

| Name | Value | Usage |
|------|-------|-------|
| Mobile | <!-- < 640px --> | Single column, stacked |
| Tablet | <!-- 640px – 1024px --> | Two columns, compact nav |
| Desktop | <!-- > 1024px --> | Full layout, sidebar |

## Animation

- **Duration**: <!-- 150ms for micro, 300ms for transitions, 500ms for page -->
- **Easing**: <!-- ease-out for enter, ease-in for exit, ease-in-out for move -->
- **Reduce motion**: Respect `prefers-reduced-motion: reduce`

## Component guidelines

<!-- Add notes about specific component decisions -->

### Buttons
- Primary: filled, used for main action per section
- Secondary: outlined, used for supporting actions
- Destructive: red variant, requires confirmation for irreversible actions

### Forms
- Labels above inputs
- Error messages below the field in `--color-error`
- Required fields marked with asterisk

### Tables
- Zebra striping on rows
- Sticky header on scroll
- Responsive: collapse to card layout on mobile

## Figma

- **Design file**: <!-- https://figma.com/design/... -->
- **Component library**: <!-- https://figma.com/design/... -->
- **Figma variables**: <!-- Synced via Figma MCP / Code Connect -->

## Visual references

<!-- Project-level references that define the overall look and feel.
     Keep only what you have — delete empty sections. -->

### Reference websites

<!-- Sites that capture the desired visual direction. -->

- <!-- https://example.com — clean layout, good whitespace -->

### Reference screenshots

<!-- Screenshots of apps/sites that match the desired style.
     Place files in the project root under references/ and link here. -->

- <!-- ![dashboard reference](references/dashboard-inspiration.png) -->

### Style notes

<!-- Free-form notes about the desired aesthetic. -->

- <!-- Minimal, lots of whitespace, no gradients -->
- <!-- Rounded corners, soft shadows -->
- <!-- Dark mode as secondary theme -->

## Notes

<!-- Any additional design guidelines, do's and don'ts, brand rules -->
