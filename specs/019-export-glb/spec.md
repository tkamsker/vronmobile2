# Feature Specification: Export Session to GLB

**Feature Branch**: `018-export-glb`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate GLB (Priority: P1)

Stitched room layout converted to single GLB 3D model file.

**Why this priority**: Final output generation.

**Independent Test**: Complete stitching, trigger export, verify GLB generated locally.

**Acceptance Scenarios**:

1. **Given** stitching complete, **When** user triggers export, **Then** GLB generation begins
2. **Given** generation in progress, **When** processing, **Then** progress indicator shown
3. **Given** generation complete, **When** finished, **Then** GLB file stored locally

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST process scan files and stitching data
- **FR-002**: System MUST generate single GLB file
- **FR-003**: System MUST store GLB locally
- **FR-004**: System MUST show generation progress

## Success Criteria *(mandatory)*

- **SC-001**: GLB generation completes within 30 seconds for typical scans
- **SC-002**: Generated files are valid GLB format

## Dependencies

- **Depends on**: UC17 (Room Stitching) or UC15 (single room)
- **Blocks**: UC19 (Preview GLB)
