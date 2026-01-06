# Feature Specification: Generate NavMesh & Save to Project

**Feature Branch**: `020-save-to-project`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - NavMesh Generation (Priority: P1)

User generates navigation mesh for GLB model.

**Why this priority**: Enables spatial navigation in VR/AR.

**Independent Test**: Request NavMesh generation, verify completion.

**Acceptance Scenarios**:

1. **Given** GLB preview shown, **When** "Generate NavMesh" tapped, **Then** GLB uploaded to NavMesh service
2. **Given** processing, **When** complete, **Then** NavMesh GLB received

### User Story 2 - Save Assets to Project (Priority: P1)

User selects which assets to save (raw scan, final GLB, NavMesh) and associates with project.

**Why this priority**: Persists work to cloud.

**Independent Test**: Select assets, choose project, verify upload and association.

**Acceptance Scenarios**:

1. **Given** assets ready, **When** "Save to Project" screen opens, **Then** asset checkboxes displayed
2. **Given** assets selected, **When** user chooses project and saves, **Then** files uploaded via multipart request
3. **Given** upload complete, **When** confirmed, **Then** project association created via mutation

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST upload GLB to NavMesh generation service
- **FR-002**: System MUST receive NavMesh GLB in response
- **FR-003**: System MUST display asset selection checkboxes
- **FR-004**: System MUST upload selected assets via multipart POST
- **FR-005**: System MUST call updateProjectWorlds or uploadWorldAssets mutation
- **FR-006**: System MUST show upload progress
- **FR-007**: System MUST be disabled/hidden in guest mode

## Success Criteria *(mandatory)*

- **SC-001**: NavMesh generation completes within 60 seconds
- **SC-002**: Asset uploads show progress
- **SC-003**: Successful saves confirmed with feedback

## Dependencies

- **Depends on**: UC19 (Preview GLB)
- **Depends on**: Authenticated session (not available in guest mode UC7)
- **Depends on**: Backend NavMesh service, upload endpoint, updateProjectWorlds mutation
