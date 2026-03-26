# New Component Prompt

> Copy and paste this into Claude Code when you need to create a new UI component.

---

I need to create a new component: **[COMPONENT NAME]**

Before writing any code:

1. **Check for duplicates** — search the component graph and codebase for similar components. If one exists, tell me and suggest extending it instead.
2. **Ask me for context** if I haven't provided:
   - What is this component for? (product surface)
   - Who uses it and when? (context of use)
   - Any constraints? (device, brand, accessibility level)

When creating the component:

3. **Use only design tokens** from DESIGN.md — no hardcoded colors, spacing, or fonts
4. **Implement all five states**: loading, error, empty, populated, partial
5. **Make it responsive** for mobile, tablet, and desktop
6. **Ensure accessibility** — keyboard navigation, ARIA attributes, contrast
7. **Create a Storybook story** showing the main variants
8. **Write a basic test** for the key behavior
9. **Follow existing patterns** — check the `patterns/` directory in the vault for reference implementations

Put the component in the standard location following the project's file structure.
Show me the result with a description of what you built and any design decisions you made.
