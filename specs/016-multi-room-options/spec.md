# Feature Specification: Multi-Room Options

**Feature Branch**: `016-multi-room-options`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-Room Choice (Priority: P1)

After saving scan, user chooses to scan another room or proceed with stitching/export.

**Why this priority**: Decision point for multi-room workflows.

**Independent Test**: Save scan, verify options presented.

**Acceptance Scenarios**:

1. **Given** scan saved, **When** options screen shows, **Then** "Scan another room" and "Continue" buttons visible
2. **Given** "Scan another room" tapped, **When** navigating, **Then** returns to scanning screen
3. **Given** "Continue" tapped, **When** proceeding, **Then** navigates to stitching or export

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present multi-room options after scan save
- **FR-002**: System MUST return to scanning for additional rooms
- **FR-003**: System MUST track multiple scans in session

## Success Criteria *(mandatory)*

- **SC-001**: Options appear immediately after save
- **SC-002**: Multi-room session maintains all scan data

## Dependencies

- **Depends on**: UC15 (Post-Scan Preview)
- **Blocks**: UC17 (Room Stitching) or UC18 (GLB Export)
