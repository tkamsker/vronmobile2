# Feature Specification: Multi-Room Scanning Options

**Feature Branch**: `016-multi-room-options`
**Created**: 2025-01-01
**Status**: In Progress (60% Complete)
**Input**: User description: "016-multi-room-options read codebase and mark finnished what is alerady done"

## Implementation Status Summary

**Already Implemented (✅):**
- Session management for multiple scans (ScanSessionManager)
- Scan list UI with "Scan another room" button
- Multi-scan navigation flow
- Individual scan preview and management
- Delete with undo functionality
- Multi-room capability detection (iOS 17+)

**Still Needs Implementation (❌):**
- Room stitching UI and backend integration
- Stitched model preview
- Scan naming/organization
- Batch operations
- Enhanced accessibility

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multiple Room Scanning Session (Priority: P1) ✅ IMPLEMENTED

Users can scan multiple rooms in a single session, adding each room sequentially and managing all scans from a central list view before proceeding to export or stitching.

**Why this priority**: Foundation for all multi-room workflows - enables users to capture complete property scans room by room without losing context.

**Independent Test**: Start app, scan first room, save to session, tap "Scan another room", scan second room, verify both scans appear in scan list with correct metadata and actions.

**Implementation Status**: ✅ COMPLETE
- `lib/features/scanning/services/scan_session_manager.dart` - Session management implemented
- `lib/features/scanning/screens/scan_list_screen.dart` - Full UI with "Scan another room" button (lines 118-137)
- Navigation flow works: ScanningScreen → ScanListScreen → ScanningScreen (repeat)

**Acceptance Scenarios**:

1. ✅ **Given** user completes first room scan, **When** viewing scan list, **Then** "Scan another room" button is visible and functional
2. ✅ **Given** user taps "Scan another room", **When** scanning completes, **Then** returns to scan list with new scan added
3. ✅ **Given** multiple scans in session, **When** viewing scan list, **Then** each scan shows: thumbnail, timestamp, file size, and action buttons (USDZ View, GLB View, Delete)
4. ✅ **Given** user taps Delete on any scan, **When** delete confirms, **Then** scan removed from list with Undo option in snackbar
5. ✅ **Given** no scans in session, **When** viewing scan list, **Then** empty state displays with prompt to start scanning

---

### User Story 2 - Room Stitching for Complete Property Model (Priority: P2) ❌ NOT IMPLEMENTED

After scanning multiple rooms, users can merge them into a single cohesive 3D model of the entire property, with the system intelligently aligning overlapping areas and creating seamless transitions between rooms.

**Why this priority**: Core value proposition of multi-room scanning - transforms individual room scans into a complete walkable property model for VR experiences or architectural visualization.

**Independent Test**: Scan two adjacent rooms with overlapping doorway area, select both scans for stitching, initiate merge, verify stitched model shows both rooms correctly aligned with seamless transition.

**Implementation Status**: ❌ PLACEHOLDER ONLY
- `scan_list_screen.dart:378-385` - Button exists but shows "coming soon" snackbar
- Missing: RoomStitchingScreen, room_stitching_service.dart, backend API integration

**Acceptance Scenarios**:

1. ❌ **Given** user has 2+ scans in session, **When** viewing scan list, **Then** "Room stitching" button is enabled (currently disabled until 2+ scans, but no functionality)
2. ❌ **Given** user taps "Room stitching", **When** stitching screen opens, **Then** displays scan selection checklist with preview thumbnails
3. ❌ **Given** user selects scans to stitch, **When** taps "Start Stitching", **Then** uploads selected scans to backend and initiates stitching job
4. ❌ **Given** stitching job started, **When** processing, **Then** progress screen shows: status (uploading/processing/aligning/merging), percentage complete, estimated time remaining
5. ❌ **Given** stitching completes successfully, **When** done, **Then** navigates to stitched model preview with options to: view in AR, export GLB, save to project
6. ❌ **Given** stitching fails (insufficient overlap, alignment error), **When** error occurs, **Then** displays specific error message with recovery suggestions (e.g., "Scan with more overlap between rooms")

---

### User Story 3 - Scan Organization and Naming (Priority: P3) ❌ NOT IMPLEMENTED

Users can assign meaningful names to each room scan (e.g., "Living Room", "Master Bedroom") and organize scans by room type or sequence, making it easier to identify and manage scans before stitching or export.

**Why this priority**: Improves user experience when managing multiple scans - especially important for large properties with 5+ rooms where generic "Scan 1, Scan 2" becomes confusing.

**Independent Test**: Scan three rooms, tap edit on each scan, assign names "Kitchen", "Dining Room", "Living Room", verify names persist in scan list and are used in stitching selection screen.

**Implementation Status**: ❌ NOT IMPLEMENTED
- Currently scans display as "Scan 1", "Scan 2" with no naming UI
- ScanData model has no `roomName` field

**Acceptance Scenarios**:

1. ❌ **Given** user views scan in list, **When** long-press or tap edit icon, **Then** opens name editor dialog with keyboard
2. ❌ **Given** user enters room name, **When** saves, **Then** scan list displays custom name instead of "Scan N"
3. ❌ **Given** user has named scans, **When** selecting scans for stitching, **Then** stitching screen shows room names for easy identification
4. ❌ **Given** user exports or uploads scan, **When** file is saved, **Then** filename includes room name (e.g., "living-room-scan-2025-01-01.glb")

---

### User Story 4 - Batch Operations on Multiple Scans (Priority: P4) ❌ NOT IMPLEMENTED

Users can perform bulk actions on multiple scans simultaneously, such as: export all scans as individual GLB files, upload all scans to a project, or delete multiple scans at once.

**Why this priority**: Efficiency improvement for users managing many scans - reduces repetitive tapping and streamlines common workflows.

**Independent Test**: Scan four rooms, select three using checkboxes, tap "Export All", verify all three scans export as separate GLB files in one batch operation.

**Implementation Status**: ❌ NOT IMPLEMENTED
- No multi-select UI in scan list
- Individual upload/export only

**Acceptance Scenarios**:

1. ❌ **Given** user views scan list, **When** long-press any scan, **Then** enters multi-select mode with checkboxes on each scan card
2. ❌ **Given** multi-select mode active, **When** user selects 3 scans, **Then** bottom sheet shows batch actions: Export All, Upload All, Delete All
3. ❌ **Given** user taps "Export All", **When** batch export starts, **Then** shows progress: "Exporting 3 scans... (2/3 complete)"
4. ❌ **Given** user taps "Upload All", **When** selecting target project, **Then** uploads all selected scans to project with single confirmation
5. ❌ **Given** user taps "Delete All", **When** confirms deletion, **Then** removes all selected scans with single Undo option

---

### Edge Cases

- User starts stitching but loses network connectivity mid-process (should queue and retry when online)
- User has 10+ scans and tries to stitch all at once (system should warn about processing time or memory limits)
- User scans same room twice with different settings (system should allow duplicate scans but warn about confusion)
- User exits app during stitching progress (should be able to resume/check status on return)
- Stitching fails after 50% progress due to backend error (should preserve uploaded scans and allow retry without re-upload)
- User tries to stitch scans from different properties (should detect incompatible scans and warn)
- Guest user accumulates 5+ scans then tries to stitch (should prompt account creation since stitching requires backend authentication)
- User's device runs out of storage during batch GLB export (should gracefully handle partial export and notify)
- Scan names contain special characters or emojis (should sanitize for filenames but display correctly in UI)
- User rotates device during stitching progress (progress should persist across orientation changes)

## Requirements *(mandatory)*

### Functional Requirements

#### Already Implemented ✅

- **FR-001**: ✅ System MUST maintain session of multiple scans in memory across app navigation without persistence to disk (session-only per architecture guidelines)
- **FR-002**: ✅ System MUST display scan list showing all scans for current session with metadata: scan number, timestamp (relative: Today/Yesterday/Date), file size, format (USDZ/GLB)
- **FR-003**: ✅ System MUST provide "Scan another room" button that navigates to scanning screen and returns updated scan list after new scan completes
- **FR-004**: ✅ System MUST allow individual scan deletion with Undo capability via snackbar for 5 seconds
- **FR-005**: ✅ System MUST provide individual scan preview (USDZ View, GLB View buttons) for each scan in list
- **FR-006**: ✅ System MUST detect multi-room capability (iOS 17.0+ with LiDAR) and show appropriate UI elements only on supported devices

#### Not Yet Implemented ❌

- **FR-007**: ❌ System MUST provide room stitching functionality that merges 2+ selected scans into single cohesive 3D model via backend API
- **FR-008**: ❌ System MUST upload selected scans to backend stitching service and poll for completion status with progress updates
- **FR-009**: ❌ System MUST display stitching progress: status (uploading/processing/aligning/merging), percentage complete, estimated time
- **FR-010**: ❌ System MUST handle stitching errors gracefully with specific error messages: insufficient overlap, alignment failure, backend timeout, incompatible scan formats
- **FR-011**: ❌ System MUST present stitched model preview screen allowing users to: view merged model, export as GLB, save to project, or retry stitching with different parameters
- **FR-012**: ❌ System MUST allow users to assign custom names to room scans (max 50 characters, alphanumeric + spaces)
- **FR-013**: ❌ System MUST persist room names in scan metadata and display in scan list instead of generic "Scan N"
- **FR-014**: ❌ System MUST support multi-select mode in scan list for batch operations via long-press gesture
- **FR-015**: ❌ System MUST provide batch actions: Export All (GLB), Upload All (to project), Delete All (with single Undo)
- **FR-016**: ❌ System MUST show batch operation progress: "Exporting 5 scans... (3/5 complete)" with cancellation option
- **FR-017**: ❌ System MUST sanitize room names for use in exported filenames while preserving display characters (emojis, special chars)
- **FR-018**: ❌ System MUST validate scan compatibility before stitching (same property, overlapping timestamps, compatible formats)
- **FR-019**: ❌ System MUST queue stitching requests when offline and process when connectivity restored (using existing offline queue from Feature 015)
- **FR-020**: ❌ System MUST require authentication for stitching operations and prompt guest users to create account before initiating stitch

### Key Entities

**Already Implemented ✅:**

- **ScanData**: Represents individual room scan with fields: id, localPath, format (USDZ/GLB), fileSizeBytes, capturedAt, status, metadata, glbLocalPath
- **ScanSessionManager**: Singleton managing in-memory collection of ScanData objects for current session with add/remove/retrieve operations
- **LidarCapability**: Device capability detection including isMultiRoomSupported flag for iOS 17.0+

**Needs Implementation ❌:**

- **RoomStitchRequest**: Stitching job request containing: selectedScanIds (array), alignmentMode (auto/manual), outputFormat (GLB/USDZ), roomNames (map of scanId to name)
- **RoomStitchJob**: Active stitching operation with: jobId, status (pending/uploading/processing/completed/failed), progress (0-100), startedAt, completedAt, errorMessage
- **StitchedModel**: Result of stitching operation with: jobId, mergedModelPath (local GLB file), originalScanIds, stitchParameters, createdAt, metadata (polygon count, file size)

## Success Criteria *(mandatory)*

**Already Achieved ✅:**

- **SC-001**: ✅ Users can add unlimited scans to session with instant UI updates (< 500ms to add scan and refresh list)
- **SC-002**: ✅ Scan list accurately displays all session scans with correct metadata and timestamps
- **SC-003**: ✅ "Scan another room" workflow completes in under 3 taps (scan button → capture → return to list)
- **SC-004**: ✅ Delete with Undo prevents accidental data loss (5-second undo window)

**Pending Implementation ❌:**

- **SC-005**: ❌ Users can successfully stitch 2-5 room scans into cohesive model in under 5 minutes (including upload + processing time)
- **SC-006**: ❌ Stitching success rate exceeds 85% for scans with sufficient overlap (>20% common area between adjacent rooms)
- **SC-007**: ❌ Stitching error messages enable user self-recovery in 70% of cases without support contact
- **SC-008**: ❌ Users can identify scans by room name in under 2 seconds when managing 5+ scans (vs 8+ seconds with generic "Scan N" labels)
- **SC-009**: ❌ Batch export of 5 scans completes 80% faster than individual exports (measured user time, not system time)
- **SC-010**: ❌ Guest users convert to accounts at 30% rate after accumulating 3+ scans (measured conversion funnel)

## Dependencies

- **Depends on**:
  - Feature 014 (LiDAR Scanning) - Scanning screens and ScanData models
  - Feature 015 (Backend Error Handling) - Offline queue for stitching requests
  - BlenderAPI Backend - New endpoint for room stitching (needs API design)
- **Blocks**:
  - Feature 017 (Room Stitching - if separate) ❌ BLOCKED until FR-007 to FR-011 implemented
  - Feature 018 (GLB Export Enhancements) - Batch export depends on FR-015
- **Enables**:
  - Complete multi-room property scanning workflow
  - VR walkthrough experiences spanning entire properties
  - Architectural visualization of full floor plans

## Assumptions

- Backend team will provide `/api/stitch-rooms` endpoint accepting array of scan URLs and returning stitched model
- Stitching processing time: 1-3 minutes for 2-5 rooms (user expectation for "reasonable wait")
- Users typically scan 2-5 rooms per session (average property), rarely exceeding 10 rooms
- Room stitching requires authenticated users (guest mode insufficient due to backend storage/processing requirements)
- Scans must be taken within same session or same property for stitching compatibility (no mixing scans from different properties)
- Sufficient device storage available for stitched models (merged GLB files may be 2-3x larger than individual scans)
- iOS 17.0+ adoption rate high enough among target users to justify multi-room features (LiDAR + multi-room APIs)
- Room naming is optional - users can proceed with stitching using default "Scan N" labels if desired
- Backend handles actual alignment/merging algorithms - mobile app only manages UI and job orchestration
