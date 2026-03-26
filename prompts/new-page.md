# New Page Prompt

> Copy and paste this into Claude Code when you need to create a new page/route.

---

I need to create a new page: **[PAGE NAME]** at route **[/route-path]**

Before writing any code:

1. **Check existing routes** — make sure there's no conflicting or duplicate route
2. **Ask me for context** if I haven't provided:
   - What does this page show? (purpose)
   - Where does the user come from? (navigation flow)
   - Where can the user go next? (outbound links/actions)
   - What data does the page need? (entities, API calls)

When creating the page:

3. **Use the correct layout** — identify which layout this page belongs to (authenticated, public, settings, etc.)
4. **Set page metadata** — title, description for SEO and browser tab
5. **Implement all states**:
   - Loading: skeleton layout matching the final structure
   - Error: error boundary with retry action
   - Empty: meaningful empty state with guidance
   - Populated: normal display
6. **Fetch data at page level** — do not fetch deep inside child components
7. **Make it responsive** for mobile, tablet, desktop
8. **Add breadcrumbs / navigation context** — user must know where they are
9. **Reuse existing components** — check the component graph before creating anything new

If this page has forms:
10. Validate on blur and on submit
11. Show inline errors per field
12. Handle network errors with retry option
13. Show success feedback after submission

Put the page in the correct route directory following the project's routing conventions.
Show me the result and explain the data flow.
