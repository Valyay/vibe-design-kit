# New Component Prompt

> Copy and paste this into Claude Code when you need to create a new UI component.

---

I need to create a new component: **[COMPONENT NAME]**

Before writing any code:

1. **Read the vault index** — check `_index.md` in the knowledge base to find related entities, screens, and existing components
2. **Check for duplicates** — search the component graph and codebase for similar components. If one exists, tell me and suggest extending it instead.
3. **Ask me for context** if I haven't provided:
   - What is this component for? (product surface)
   - Who uses it and when? (context of use)
   - Any constraints? (device, brand, accessibility level)

When creating the component:

4. **Use only design tokens** from DESIGN.md — no hardcoded colors, spacing, or fonts
5. **Implement all five states**: loading, error, empty, populated, partial
6. **Make it responsive** for mobile, tablet, and desktop
7. **Ensure accessibility** — keyboard navigation, ARIA attributes, contrast
8. **Create a Storybook story** showing the main variants
9. **Write a basic test** for the key behavior
10. **Follow existing patterns** — check the `patterns/` directory in the vault for reference implementations

Put the component in the standard location following the project's file structure.
Show me the result with a description of what you built and any design decisions you made.
