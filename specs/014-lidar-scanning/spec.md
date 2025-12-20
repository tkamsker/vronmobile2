# Feature Specification: LiDAR Scanning

**Feature Branch**: `014-lidar-scanning`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start Scan (Priority: P1)

User with LiDAR-capable device initiates room scan.

**Why this priority**: Core app functionality - room capture.

**Independent Test**: Tap Start Scanning, verify camera/sensor permissions requested and scan begins.

**Acceptance Scenarios**:

1. **Given** user logged in or guest, **When** navigates to scanning, **Then** "Start Scanning" button visible
2. **Given** button visible, **When** device has LiDAR, **Then** button enabled
3. **Given** button tapped, **When** permissions granted, **Then** scan interface appears
4. **Given** scanning active, **When** room captured, **Then** scan data stored locally

### User Story 2 - Upload GLB (Priority: P2)

User can upload existing GLB file instead of scanning.

**Why this priority**: Alternative input method for pre-existing models.

**Independent Test**: Select file picker, choose GLB, verify uploaded.

**Acceptance Scenarios**:

1. **Given** scanning screen, **When** user taps upload, **Then** file picker opens
2. **Given** GLB selected, **When** upload completes, **Then** file stored locally

### Edge Cases

- Device lacks LiDAR sensor
- Permissions denied
- Insufficient device storage
- Scan interrupted by phone call

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST check device LiDAR capability
- **FR-002**: System MUST disable button if no LiDAR
- **FR-003**: System MUST request camera/sensor permissions
- **FR-004**: System MUST use flutter_roomplan for scanning
- **FR-005**: System MUST store raw scan data locally
- **FR-006**: System MUST support GLB file upload

## Success Criteria *(mandatory)*

- **SC-001**: Scan initiates within 2 seconds of button tap
- **SC-002**: Scanning maintains 30fps minimum
- **SC-003**: Scan data captured without data loss

## Dependencies

- **Depends on**: UC7 (Guest Mode) or UC2 (Auth) for access
- **Blocks**: UC15 (Post-Scan Preview)
