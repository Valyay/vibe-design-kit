# Sync Tokens Prompt

> Copy and paste this into Claude Code to reconcile design tokens.

---

Check if my design tokens are in sync across Figma, DESIGN.md, and code.

1. Read my Figma Variables (the file URL is in DESIGN.md under Figma section)
2. Parse the token tables in DESIGN.md
3. Scan the code for token definitions (CSS variables, Tailwind config, theme files)
4. Compare all three sources and show me:
   - What's in sync
   - What drifted (different values)
   - What's new in one source but missing in others
5. For anything that doesn't match — ask me which source is correct.
6. Show me the code snippets before writing anything. I decide what gets changed.
