# Visual Identity

> **How to use this file**
>
> This is your project's design spec — the **intended** visual language.
> It can be filled in three ways:
>
> 1. **Auto-populated by onboarding** — if you ran the onboarding skill, consistent
>    values from the code were pre-filled here. Look for `[auto-filled]` markers.
>    Review and approve them, or change them to what you actually want.
> 2. **From your Figma file** — if you have a design system in Figma, copy your
>    token values here. This becomes the reference AI uses when building UI.
> 3. **From scratch** — fill in the tables below. Replace the `<!-- example -->` 
>    comments with real values. Delete sections you don't need yet.
>
> **When this file and the code disagree**, the code wins day-to-day — but flag
> the discrepancy. This file captures your *intent*; the code captures *reality*.
> The goal is to close the gap over time.
>
> **Markers you may see:**
> - `[auto-filled]` — value extracted from code, consistent across the codebase. Review and approve.
> - `[inconsistent]` — code uses multiple values for this purpose. Pick one and AI will consolidate.
> - `[missing]` — no value found in code. Fill in or leave blank to skip.

## Brand

- **Product name**: <!-- e.g. Acme Dashboard -->
- **Brand voice**: <!-- e.g. professional but friendly, minimal, playful -->
- **Logo**: <!-- path to logo file or Figma link -->

## Colors

### Primary palette

<!-- Source: CSS variables, Tailwind config, or theme file in the codebase.
     Onboarding auto-fills these from tokenized values in visual-language.md. -->

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

<!-- Source: @font-face declarations, Google Fonts links, Tailwind font config.
     Onboarding extracts actual font usage from the codebase. -->

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

<!-- Source: spacing scale in Tailwind config, CSS variables, or theme file.
     Onboarding detects common gaps used in the codebase. -->

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

<!-- These are design decisions, not code facts. Onboarding does NOT auto-fill this section.
     Describe how you want components to behave. AI follows these rules when building UI. -->

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

<!-- These come from YOU, not from code. Paste links, screenshots, or mood descriptions
     that capture the look and feel you're going for. AI uses these as creative direction. -->

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
