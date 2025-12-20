# Feature Specification: Project Detail

**Feature Branch**: `010-project-detail`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Project Info (Priority: P1)

User views detailed project information after tapping "Enter project".

**Why this priority**: Core navigation destination from projects list.

**Independent Test**: Navigate from projects list, verify detail screen displays.

**Acceptance Scenarios**:

1. **Given** user taps project, **When** detail loads, **Then** project name, description, details displayed
2. **Given** detail screen shown, **When** loaded, **Then** options for "Project data" and "Products" visible

### Edge Cases

- Project deleted between list and detail view
- Network failure during detail load
- Missing project data fields

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST call project query with project ID
- **FR-002**: System MUST display project name, description, and details
- **FR-003**: System MUST provide navigation to "Project data" (UC11)
- **FR-004**: System MUST provide navigation to "Products" (UC12)

### GraphQL Contract

```graphql
query project($id: ID!) {
  project(id: $id) {
    id name description
  }
}
```

## Success Criteria *(mandatory)*

- **SC-001**: Project detail loads within 1 second
- **SC-002**: Navigation options clearly visible

## Dependencies

- **Depends on**: UC8 (View Projects) for navigation
- **Blocks**: UC11 (Project Data), UC12 (View Products)
