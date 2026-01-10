# Feature Specification: Search Projects

**Feature Branch**: `009-search-projects`
**Created**: 2025-12-20
**Status**: ✅ Complete
**Completed**: 2026-01-10
**Updated**: 2026-01-10 - Fixed filter buttons to clear search query

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Search by Name (Priority: P1)

User types in search bar to filter projects by name.

**Why this priority**: Essential for users with many projects.

**Independent Test**: Type search term, verify filtered results.

**Acceptance Scenarios**:

1. **Given** projects list displayed, **When** user types in search bar, **Then** projects filter by name
2. **Given** search active, **When** results update, **Then** only matching projects shown

### Edge Cases

- No search results found
- Search with special characters
- Very long search queries
- Filter buttons (All, Active, BYO, Archived) must clear active search query to show all results for that filter

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide search bar in projects list
- **FR-002**: System MUST call projects query with search parameter
- **FR-003**: System MUST debounce search input (300ms)
- **FR-004**: System MUST display "no results" message when no matches
- **FR-005**: System MUST clear search query when filter button is pressed (All, Active, BYO, Archived)

### GraphQL Contract

```graphql
query projects($search: String, $limit: Int, $offset: Int) {
  projects(search: $search, limit: $limit, offset: $offset) {
    id name description thumbnailUrl
  }
}
```

## Success Criteria *(mandatory)*

- **SC-001**: Search results appear within 500ms of typing
- **SC-002**: Search handles 100+ projects smoothly

## Dependencies

- **Depends on**: UC8 (View Projects)
- **Depends on**: Backend projects query with search parameter
