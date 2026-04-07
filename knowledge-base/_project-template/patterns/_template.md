# Pattern: {{Name}}

## Category

<!-- Form | Table | Layout | Navigation | Modal | List | Card | Chart -->

## Description

<!-- What does this pattern solve? When should it be used? -->

## Reference implementation

<!-- Path to the canonical example in the codebase -->

**File**: <!-- src/components/user-table.tsx -->

## Key decisions

<!-- Non-obvious choices in this pattern that AI should replicate -->

- <!-- Uses virtualized rows for performance (react-window) -->
- <!-- Column definitions are typed and declarative -->
- <!-- Sort state is in URL params, not component state -->

## Anatomy

<!-- Structure of the pattern -->

```
┌─────────────────────────────┐
│ Header (title + actions)    │
├─────────────────────────────┤
│ Filters / Search            │
├─────────────────────────────┤
│ Content area                │
│ (table rows / list items)   │
├─────────────────────────────┤
│ Pagination / Load more      │
└─────────────────────────────┘
```

## States

- **Loading**: <!-- skeleton rows matching column count -->
- **Empty**: <!-- illustration + "No items yet" + CTA button -->
- **Error**: <!-- error banner above content area -->

## Responsive behavior

- **Desktop**: <!-- full table with all columns -->
- **Tablet**: <!-- hide low-priority columns -->
- **Mobile**: <!-- card layout instead of table rows -->

## Accessibility

- <!-- Table uses proper thead/tbody/th semantics -->
- <!-- Sort controls are keyboard-accessible buttons -->
- <!-- Live region announces sort changes -->

## Anti-patterns

<!-- What NOT to do when implementing this pattern -->

- <!-- Do NOT fetch data inside table rows — fetch at page level -->
- <!-- Do NOT hardcode column widths — use flex or grid -->
- <!-- Do NOT paginate with offset in API — use cursor -->

## Related

- <!-- [[component-graph]] — DataTable component -->
- <!-- [[flows/browse-items]] — Browse items flow -->
- <!-- [[decisions/005-table-virtualization]] — ADR-005 -->
