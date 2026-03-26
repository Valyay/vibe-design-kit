# Entity: {{Name}}

## Description

<!-- What is this entity? Business meaning, not technical definition -->

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | yes | Unique identifier |
| <!-- name --> | <!-- string --> | <!-- yes --> | <!-- Display name --> |

## Relationships

| Related entity | Relationship | Description |
|---------------|-------------|-------------|
| <!-- User --> | <!-- belongs to --> | <!-- Each {{Name}} is owned by a User --> |

## States / Lifecycle

<!-- What states can this entity be in? -->

1. <!-- Draft — just created, not yet published -->
2. <!-- Active — live and visible -->
3. <!-- Archived — hidden but not deleted -->

## UI surfaces

<!-- Where does this entity appear in the UI? -->

- <!-- List view: /entities page -->
- <!-- Detail view: /entities/[id] page -->
- <!-- Inline: as a card in the dashboard -->

## Business rules

<!-- Non-obvious rules that AI should know -->

- <!-- A {{Name}} cannot be deleted if it has active children -->
- <!-- Name must be unique within the same organization -->

## Scenarios

<!-- Common user actions involving this entity -->

1. **Create** — <!-- user fills form, submits, redirected to detail -->
2. **Edit** — <!-- inline editing on detail page -->
3. **Delete** — <!-- confirmation dialog, soft delete -->
4. **Search** — <!-- filterable by name, status, date -->
