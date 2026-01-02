# Feature Specification: Room Stitching

**Feature Branch**: `017-room-stitching`
**Created**: 2026-01-02
**Status**: Implemented
**Input**: User description: "start featue 017-room-stitching"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select Scans for Stitching (Priority: P1)

Users can view all available scans in their session and select two or more scans to combine into a single unified 3D model. The scan selection interface clearly displays each scan's name, capture time, and file size, allowing users to make informed decisions about which rooms to stitch together.

**Why this priority**: Essential foundation for room stitching - users must be able to select scans before any stitching can occur. This is the entry point to the entire stitching workflow.

**Independent Test**: Scan three rooms, open room stitching screen, verify all scans displayed with checkboxes, select two scans, verify "Start Stitching" button becomes enabled, tap button to initiate stitching.

**Acceptance Scenarios**:

1. **Given** user has 2+ scans in session, **When** user taps "Room stitching" button from scan list, **Then** room stitching screen opens showing all available scans with checkboxes
2. **Given** room stitching screen is open, **When** user views scan list, **Then** each scan displays: room name (or "Scan N"), file size in MB, and selection checkbox
3. **Given** no scans selected, **When** viewing stitching screen, **Then** "Start Stitching" button is disabled with helper text "Select 2 or more scans"
4. **Given** only 1 scan selected, **When** viewing button state, **Then** "Start Stitching" button remains disabled
5. **Given** 2+ scans selected, **When** viewing button state, **Then** "Start Stitching" button becomes enabled and tappable
6. **Given** user is in guest mode, **When** user taps "Start Stitching", **Then** system shows authentication required dialog instead of starting stitching

---

### User Story 2 - Monitor Stitching Progress (Priority: P1)

After initiating room stitching, users see real-time progress updates showing the current stage of processing (uploading, processing, aligning, merging) with visual indicators and percentage completion. This provides transparency into the backend operation and manages user expectations during the potentially lengthy stitching process.

**Why this priority**: Critical user experience element - stitching takes 2-5 minutes, users need feedback to know the system is working and not frozen. Without progress tracking, users would abandon the process.

**Independent Test**: Start stitching with 2 scans, verify progress screen shows initial status, watch status updates progress through: uploading (10%) → processing (30%) → aligning (60%) → merging (85%) → completed (100%), verify each status displays appropriate icon and message.

**Acceptance Scenarios**:

1. **Given** user taps "Start Stitching", **When** stitching begins, **Then** navigates to progress screen showing initial "Uploading" status at 10% with upload icon
2. **Given** stitching in progress, **When** backend updates job status, **Then** progress screen automatically updates to show new status without user interaction
3. **Given** status changes to "Processing", **When** viewing progress, **Then** displays progress bar at 30% with processing icon and message "Validating scan data"
4. **Given** status changes to "Aligning", **When** viewing progress, **Then** displays progress bar at 60% with alignment icon and message "Aligning rooms"
5. **Given** status changes to "Merging", **When** viewing progress, **Then** displays progress bar at 85% with merge icon and message "Merging geometry"
6. **Given** stitching completes successfully, **When** reaching 100%, **Then** displays success icon, downloads stitched model, and automatically navigates to preview screen
7. **Given** stitching fails (insufficient overlap, timeout, network error), **When** failure detected, **Then** displays error dialog with specific error message and "Retry" option
8. **Given** network timeout occurs, **When** polling fails, **Then** shows timeout dialog suggesting "Try again with fewer scans or smaller rooms"

---

### User Story 3 - Preview Stitched Model (Priority: P1)

After successful stitching, users immediately see a preview of the combined 3D model with options to view it in AR, export as GLB file, or save to a project. The preview provides confirmation that rooms were stitched correctly before committing to further actions.

**Why this priority**: Completes the stitching workflow - users need to verify the stitched result before deciding what to do with it. This is the payoff for the stitching operation.

**Independent Test**: Complete stitching process, wait for automatic navigation to preview screen, verify stitched model displays, tap "View in AR" to open AR viewer, verify model appears in AR, return and tap "Export GLB" to save file, verify file saved successfully.

**Acceptance Scenarios**:

1. **Given** stitching completes, **When** model downloads, **Then** automatically navigates to stitched model preview screen
2. **Given** preview screen opens, **When** viewing model, **Then** displays 3D visualization of combined rooms with rotation/zoom controls
3. **Given** viewing preview, **When** user taps "View in AR" button, **Then** opens device AR viewer with stitched model placed in real environment
4. **Given** viewing preview, **When** user taps "Export GLB" button, **Then** opens file picker to save GLB file to device storage
5. **Given** export initiated, **When** save location selected, **Then** displays success snackbar with message "Stitched model exported to [location]"
6. **Given** viewing preview, **When** user taps "Save to Project" button, **Then** opens project selection screen to upload model to VRon project
7. **Given** preview displayed, **When** user taps back button, **Then** returns to scan list with all original scans still available

---

### User Story 4 - Handle Room Names in Stitching (Priority: P2)

When users have assigned custom names to their room scans (e.g., "Living Room", "Kitchen"), these names are preserved and passed to the backend during stitching, allowing the stitched model metadata to maintain room identification for navigation and labeling within VR experiences.

**Why this priority**: Enhances usability for users with many rooms - custom names make it easier to identify which rooms were stitched together and provide better organization in the final VR project.

**Independent Test**: Scan two rooms, assign names "Bedroom" and "Bathroom" via scan list, open stitching screen, verify room names display instead of "Scan 1" / "Scan 2", select both and stitch, verify backend receives room names in stitching request.

**Acceptance Scenarios**:

1. **Given** scans have custom room names in metadata, **When** viewing stitching screen, **Then** displays custom names instead of generic "Scan N" labels
2. **Given** scans have no custom names, **When** viewing stitching screen, **Then** falls back to "Scan 1", "Scan 2", etc. as display names
3. **Given** user selects scans with custom names, **When** starting stitching, **Then** backend request includes roomNames map with scan IDs mapped to room names
4. **Given** some scans named and others not, **When** starting stitching, **Then** backend request includes names only for named scans, others use scan IDs

---

### Edge Cases

- **What happens when user has only 1 scan?** - Room stitching button is disabled with minimum requirement message "Need 2+ scans to stitch"
- **What happens if backend stitching fails due to insufficient overlap?** - Error dialog displays with specific message "Insufficient overlap detected. Scan with more overlap between rooms" and option to retry or cancel
- **What happens if user loses network connection during stitching?** - Polling continues to retry, timeout after 5 minutes shows error dialog with retry option
- **What happens if user exits app during stitching?** - Stitching continues on backend, but progress is lost. User must restart stitching from scan list. Job is eventually cleaned up by backend timeout
- **What happens if stitched model download fails?** - Error dialog shows "Failed to download stitched model" with retry option to re-attempt download from cached job result URL
- **What happens if user selects very large rooms (100+ MB combined)?** - Upload takes longer, progress stays at "Uploading" longer, but eventually progresses. Backend enforces size limits and returns error if exceeded
- **What happens when user taps back during progress?** - Shows confirmation dialog "Stitching in progress. Leave anyway?" with options to stay or abort

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to select 2 or more scans from their session for stitching
- **FR-002**: System MUST disable stitching initiation when fewer than 2 scans are selected
- **FR-003**: System MUST block guest users from starting stitching and prompt for authentication
- **FR-004**: System MUST upload selected USDZ scan files to backend stitching service
- **FR-005**: System MUST poll backend job status at 2-second intervals during stitching
- **FR-006**: System MUST display current stitching stage (pending, uploading, processing, aligning, merging, completed, failed)
- **FR-007**: System MUST show progress percentage matching backend job status (10% uploading, 30% processing, 60% aligning, 85% merging, 100% complete)
- **FR-008**: System MUST automatically download stitched model when job completes
- **FR-009**: System MUST navigate to preview screen upon successful download
- **FR-010**: System MUST display error dialog with specific error message when stitching fails
- **FR-011**: System MUST provide retry option when stitching fails due to recoverable errors
- **FR-012**: System MUST handle network timeouts gracefully with user-friendly messages
- **FR-013**: System MUST pass room names to backend when scans have custom names in metadata
- **FR-014**: System MUST support viewing stitched model in device AR viewer
- **FR-015**: System MUST allow exporting stitched model as GLB file to device storage
- **FR-016**: System MUST provide option to save stitched model to VRon project
- **FR-017**: System MUST preserve original individual scans after stitching completes

### Key Entities

- **RoomStitchRequest**: Request to backend containing project ID, list of scan IDs to stitch, and optional map of room names
- **RoomStitchJob**: Represents ongoing stitching operation with job ID, status enum (pending/uploading/processing/aligning/merging/completed/failed), progress percentage, optional error message, and result URL when complete
- **StitchedModel**: Completed stitching result containing job ID, list of source scan IDs, GLB file path on device, file size, creation timestamp, and optional room names metadata

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users with 2+ scans can initiate stitching in under 30 seconds from scan list
- **SC-002**: Stitching progress updates display within 3 seconds of backend status changes
- **SC-003**: Completed stitched model automatically downloads and displays preview within 5 seconds of job completion
- **SC-004**: Error messages provide specific actionable guidance for 90%+ of failure scenarios
- **SC-005**: Users can complete entire flow (select scans → monitor progress → preview result → export/save) without developer documentation or support
- **SC-006**: System handles network interruptions gracefully without crashing or data loss
- **SC-007**: Stitching workflow supports rooms ranging from 10MB to 100MB per scan without performance degradation
- **SC-008**: Progress screen maintains responsive UI (no freezing) throughout multi-minute stitching operations

## Dependencies

- **Depends on**: Feature 016-multi-room-options (scan session management, scan list UI)
- **Depends on**: Backend room stitching API (job creation, status polling, model download endpoints)
- **Depends on**: Device AR capabilities (ARKit on iOS, ARCore on Android) for AR preview
- **Blocks**: Advanced stitching features (manual alignment adjustment, room layout editing)

## Assumptions

- Backend stitching service is operational and accessible
- Backend enforces max file size limits (likely 200-300MB total)
- Stitching typically completes within 2-5 minutes for 2-3 rooms
- Backend supports USDZ input and returns GLB/USDZ output
- Device has sufficient storage for downloading stitched models (50-200MB typically)
- Network connection is reasonably stable during upload/download phases
- AR viewer (QuickLook on iOS, Scene Viewer on Android) is available on device

## Out of Scope

- Manual room alignment editing (drag rooms in 2D editor to adjust positioning)
- Door placement and connection drawing between rooms
- Real-time preview during stitching (only final result preview)
- Stitching optimization hints (suggestions for better overlap)
- Batch stitching (combining multiple sets of rooms in one operation)
- Stitching history and versioning (re-stitch with different room combinations)
- Local offline stitching (requires backend processing)
