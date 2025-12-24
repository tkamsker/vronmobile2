# Feature Specification: Complete Project Management Features

**Feature Branch**: `008-view-projects`
**Created**: 2025-12-24
**Status**: Implementation Completion
**Updated**: Based on codebase analysis

## Overview

Complete the remaining functionality for the project management system. The core project list and detail screens are already implemented. This specification covers the missing features identified in the codebase analysis:
1. Create new project functionality
2. Project sorting capabilities
3. Product creation from project detail screen
4. Product search within projects

## Context

**Already Implemented**:
- ✅ Project list display with search and filtering
- ✅ Project detail screen with three tabs (Viewer, Project Data, Products)
- ✅ Project data editing with update mutation
- ✅ Project models, services, and GraphQL integration
- ✅ Comprehensive test coverage

**Implementation Gaps** (from codebase TODOs):
- ❌ Create project screen (`/create-project` → PlaceholderScreen)
- ❌ Sort functionality (UI exists, logic missing)
- ❌ Product creation navigation from project detail
- ❌ Product search in project products tab

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create New Project (Priority: P1) 🎯 MVP

User can create a new project with name, slug, and description.

**Why this priority**: Core functionality gap blocking users from adding projects. Route exists but leads to placeholder.

**Independent Test**: Tap FAB on home screen, fill form, save, verify new project appears in list.

**Acceptance Scenarios**:

1. **Given** user on home screen, **When** user taps floating action button, **Then** create project screen displays
2. **Given** create form displayed, **When** user enters name "My Room", **Then** slug auto-generates as "my-room"
3. **Given** form filled with valid data, **When** user taps save, **Then** project is created and user returns to home screen
4. **Given** new project created, **When** home screen reloads, **Then** new project appears at top of list
5. **Given** form has validation errors, **When** user attempts save, **Then** error messages display and save is blocked

### User Story 2 - Sort Projects (Priority: P2)

User can sort projects by name, date, or status.

**Why this priority**: Helps users organize large project lists. UI button exists but not functional.

**Independent Test**: Tap sort button, select "Name A-Z", verify list reorders alphabetically.

**Acceptance Scenarios**:

1. **Given** projects list displayed, **When** user taps sort button, **Then** sort options menu appears
2. **Given** sort menu open, **When** user selects "Name A-Z", **Then** list sorts alphabetically ascending
3. **Given** sort menu open, **When** user selects "Date (Newest)", **Then** list sorts by creation date descending
4. **Given** sort menu open, **When** user selects "Status", **Then** active projects appear first, then archived
5. **Given** sort applied with search active, **When** results display, **Then** results are sorted according to selected option

### User Story 3 - Create Product from Project (Priority: P3)

User can add products to a project from the project detail screen.

**Why this priority**: Completes project-product relationship management.

**Independent Test**: In project detail products tab, tap "Add Product", create product, verify it appears in project's product list.

**Acceptance Scenarios**:

1. **Given** project detail products tab displayed, **When** user taps "+" FAB, **Then** create product screen displays with project context
2. **Given** create product form, **When** user enters product details, **Then** product is linked to current project automatically
3. **Given** product created, **When** user returns to products tab, **Then** new product appears in project's product list

### User Story 4 - Search Products in Project (Priority: P3)

User can search products within a specific project.

**Why this priority**: Helps navigate large product lists within projects.

**Independent Test**: In products tab with 10+ products, type "chair" in search, verify only matching products display.

**Acceptance Scenarios**:

1. **Given** products tab with search field, **When** user types search text, **Then** product list filters in real-time
2. **Given** search active, **When** user clears search, **Then** all project products display again

### Edge Cases

- Empty project name (validation)
- Duplicate project slug (backend error handling)
- Network failure during project creation
- Invalid characters in project slug
- Sort applied to empty list
- Search with no results
- Product creation with invalid project context

## Requirements *(mandatory)*

### Functional Requirements

**Create Project (US1)**:
- **FR-001**: System MUST display create project form with fields: name (required), slug (auto-generated), description (optional)
- **FR-002**: System MUST auto-generate URL-friendly slug from project name as user types
- **FR-003**: System MUST validate project name (min 3 chars, max 100 chars)
- **FR-004**: System MUST validate slug (lowercase alphanumeric with hyphens only)
- **FR-005**: System MUST call createProject GraphQL mutation with validated data
- **FR-006**: System MUST display validation errors inline on form fields
- **FR-007**: System MUST show loading state during project creation
- **FR-008**: System MUST handle duplicate slug errors from backend
- **FR-009**: System MUST navigate back to home screen after successful creation
- **FR-010**: System MUST refresh project list to show newly created project

**Sort Projects (US2)**:
- **FR-011**: System MUST display sort options menu with: Name (A-Z), Name (Z-A), Date (Newest), Date (Oldest), Status
- **FR-012**: System MUST persist selected sort preference during session
- **FR-013**: System MUST apply sort to both filtered and unfiltered views
- **FR-014**: System MUST maintain sort order when search is active
- **FR-015**: System MUST indicate current sort selection in UI

**Product Management in Projects (US3 & US4)**:
- **FR-016**: System MUST navigate to product creation screen with project context pre-filled
- **FR-017**: System MUST link created product to current project automatically
- **FR-018**: System MUST implement real-time product search within project
- **FR-019**: System MUST display search results count
- **FR-020**: System MUST handle empty search results gracefully

### Non-Functional Requirements

- **NFR-001**: Project creation MUST complete within 3 seconds on normal network
- **NFR-002**: Slug auto-generation MUST respond instantly to name input (< 100ms)
- **NFR-003**: Sort operation MUST complete within 500ms for lists up to 1000 projects
- **NFR-004**: Product search MUST filter results in real-time (< 200ms per keystroke)
- **NFR-005**: All forms MUST be accessible with screen readers

## Success Criteria *(mandatory)*

- **SC-001**: User can create a project and see it in their list within 5 seconds
- **SC-002**: Slug auto-generation updates within 100ms of typing
- **SC-003**: Form validation prevents invalid data submission with clear error messages
- **SC-004**: Sort menu displays within 300ms of button tap
- **SC-005**: Sorted list renders within 500ms for typical project counts (< 100 projects)
- **SC-006**: Product search filters results within 200ms of keystroke
- **SC-007**: Navigation from project to product creation preserves project context

## Key Entities

**Project** (already exists):
- id: String (UUID)
- name: String (3-100 chars)
- slug: String (URL-friendly)
- description: String (optional)
- imageUrl: String (optional)
- status: ProjectStatus enum
- subscription: ProjectSubscription

**ProjectSortOption** (new enum):
- nameAscending
- nameDescending
- dateNewest
- dateOldest
- status

## Dependencies

- **Depends on**: Existing ProjectService with fetchProjects() method
- **Depends on**: Existing ProductService for product creation
- **Depends on**: GraphQL createProject mutation (backend)
- **Blocks**: None (completes existing feature gaps)

## Assumptions

1. **Backend API**: createProject mutation accepts name, slug, description and returns full Project object
2. **Slug uniqueness**: Backend validates slug uniqueness and returns clear error on conflict
3. **Product linking**: Existing product creation flow supports pre-filling project context
4. **Sorting**: All project data needed for sorting is available in current fetchProjects() response
5. **Search**: Product search is client-side (no backend query needed for initial implementation)

## Out of Scope

- 3D/VR viewer implementation (project viewer tab remains placeholder)
- Project deletion
- Project archiving workflow
- Bulk project operations
- Project templates
- Project sharing/collaboration
- Advanced filtering (by date range, custom fields)
- Project import/export
