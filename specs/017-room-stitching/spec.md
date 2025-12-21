# Feature Specification: Room Stitching & Editing

**Feature Branch**: `017-room-stitching`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 2D Room Layout (Priority: P1)

User views 2D top-down editor with floor plan outlines of each scanned room.

**Why this priority**: Core stitching functionality.

**Independent Test**: Open stitching, verify rooms displayed as movable floor plans.

**Acceptance Scenarios**:

1. **Given** multiple rooms scanned, **When** stitching opens, **Then** 2D editor shows room outlines
2. **Given** editor displayed, **When** user drags room, **Then** room outline moves
3. **Given** editor displayed, **When** user rotates room, **Then** room outline rotates

### User Story 2 - Add Doors (Priority: P2)

User draws door connections between room outlines.

**Why this priority**: Logical room connections.

**Independent Test**: Use door tool, draw line on room edge, verify door created.

**Acceptance Scenarios**:

1. **Given** editor active, **When** "Add Door" tool selected, **Then** can draw line on room edge
2. **Given** door drawn, **When** saved, **Then** door connection recorded

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display 2D top-down view of room floor plans
- **FR-002**: System MUST support drag/rotate gestures for room positioning
- **FR-003**: System MUST provide "Add Door" tool
- **FR-004**: System MUST record room positions and door locations

## Success Criteria *(mandatory)*

- **SC-001**: Editor interactions maintain 60fps
- **SC-002**: Stitching data persists correctly

## Dependencies

- **Depends on**: UC16 (Multi-Room Options)
- **Blocks**: UC18 (GLB Export)
