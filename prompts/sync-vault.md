# Sync Vault Prompt

> Copy and paste this into Claude Code to update the vault after changes.

---

Sync the Obsidian vault with the current state of the code.

1. Check git log since the last sync — what files changed?
2. Compare each vault document against the current codebase:
   - Are there new components, pages, entities, flows not in the vault?
   - Are there removed or renamed items still listed?
   - Has the visual language changed (new tokens, new hardcoded values)?
3. **Preserve my annotations** — anything I wrote manually in the vault stays.
   If my notes conflict with the code, flag it and let me decide.
4. Update the generated content to match reality.
5. Re-capture screenshots for changed pages if the app is running.
6. Write a sync log and tell me what changed and what needs my attention.
