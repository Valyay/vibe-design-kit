# Flow: {{Name}}

## Description

<!-- What is this user flow? What goal does the user achieve? -->

## Actor

<!-- Who performs this flow? (role, persona) -->

## Preconditions

<!-- What must be true before the flow starts? -->

- <!-- User is authenticated -->
- <!-- User has at least one project -->

## Steps

1. <!-- User navigates to /settings -->
2. <!-- User sees the profile form with current data -->
3. <!-- User changes the display name -->
4. <!-- User clicks "Save changes" -->
5. <!-- A success toast appears -->
6. <!-- The header updates with the new name -->

## Error cases

### <!-- Validation error -->
1. <!-- User submits empty name -->
2. <!-- Inline error "Name is required" appears -->
3. <!-- User can fix and retry -->

### <!-- Network error -->
1. <!-- Save request fails -->
2. <!-- Error toast with "Failed to save, try again" -->
3. <!-- Form data is preserved -->

## Postconditions

<!-- What is true after the flow completes successfully? -->

- <!-- Display name is updated in the database -->
- <!-- All UI surfaces reflect the new name -->

## Related

- <!-- Page: /settings -->
- <!-- Component: ProfileForm -->
- <!-- Entity: User -->
- <!-- E2E test: settings.spec.ts -->
