# Feature Specification: Guest Mode

**Feature Branch**: `007-guest-mode`
**Created**: 2025-12-20
**Status**: Draft
**Input**: User description: "Guest mode access to LiDAR scanning without authentication"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Guest Scanning Access (Priority: P1)

User taps "Guest Mode" and navigates directly to scanning screen without authentication.

**Why this priority**: Allows users to try LiDAR scanning before committing to account creation.

**Independent Test**: Tap Guest Mode, verify navigation to scanning screen without login.

**Acceptance Scenarios**:

1. **Given** user on main screen, **When** taps "Guest Mode", **Then** navigates to scanning screen (UC14)
2. **Given** guest mode active, **When** user scans room, **Then** scan data stored locally only
3. **Given** guest scan complete, **When** user attempts to save to project, **Then** feature disabled/hidden

### User Story 2 - Guest Mode Limitations (Priority: P2)

Guest users understand they cannot save to cloud and can only export locally.

**Why this priority**: Sets correct expectations for guest capabilities.

**Independent Test**: Complete scan as guest, verify cloud save options are disabled.

**Acceptance Scenarios**:

1. **Given** guest mode active, **When** scan complete, **Then** "Save to Project" option hidden
2. **Given** guest scan, **When** user views options, **Then** only local GLB export available
3. **Given** guest mode, **When** user attempts backend operation, **Then** prompted to create account

### Edge Cases

- Guest switches to login mid-scan
- Guest tries to access projects list
- Device storage full during guest scan
- Guest closes app with unsaved scans

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST navigate to scanning screen when "Guest Mode" tapped
- **FR-002**: System MUST store all guest scan data locally on device
- **FR-003**: System MUST disable/hide "Save to Project" option in guest mode
- **FR-004**: System MUST allow GLB export to local device storage
- **FR-005**: System MUST NOT make backend API calls in guest mode
- **FR-006**: System MUST identify session as guest (no authentication required)
- **FR-007**: System MUST prompt account creation when guest attempts authenticated features

### Key Entities

- **Guest Session**: Unauthenticated session with limited functionality
- **Local Scan Data**: Scan files stored in app's local storage (not synced to backend)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users enter guest mode within 1 second of tapping button
- **SC-002**: Guest users can complete full scan workflow without authentication
- **SC-003**: 100% of backend operations blocked in guest mode
- **SC-004**: Guest scans export to local storage successfully 95% of time

## Assumptions

- Guest mode provides read-only access to scanning features
- No backend interaction allowed in guest mode
- Guest data not recoverable if app uninstalled
- Guest can upgrade to account at any time but cannot migrate guest data retroactively

## Dependencies

- **Depends on**: UC1 (Main Screen) to trigger guest mode
- **Depends on**: UC14 (LiDAR Scanning) - guest navigates here
- **Blocks**: None - guest mode is optional flow
- **Related to**: UC18 (GLB Export) - guests can export locally
