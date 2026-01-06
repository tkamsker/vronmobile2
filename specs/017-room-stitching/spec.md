# Feature Specification: Room Stitching

**Feature Branch**: `017-room-stitching`
**Created**: 2026-01-02
**Updated**: 2026-01-02 (Canvas Layout Enhancement)
**Status**: In Progress - Major Refactoring
**Input**: User description: "refactor stitch rooms to have similar layout than @Requirements/RoomStitching.jpg"

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

### User Story 5 - Visual Room Layout Canvas (Priority: P1)

Users see a 2D canvas representation of their selected scans where each room is drawn as an outline with estimated boundaries extracted from the 3D scan data. The canvas displays room names, automatically estimates door locations based on scan geometry, and provides a visual layout of how rooms will be stitched together.

**Why this priority**: Visual representation is essential for users to understand spatial relationships between rooms and make informed decisions about room positioning and door connections before committing to stitching.

**Independent Test**: Select 3 scans (Living Room, Kitchen, Bathroom), tap "Start Stitching", verify canvas opens showing 3 room outlines with different colors, verify each room displays its name label, verify estimated door positions shown as symbols, verify rooms are positioned with some overlap where doors connect.

**Acceptance Scenarios**:

1. **Given** user selects 2+ scans and taps "Start Stitching", **When** canvas screen loads, **Then** displays 2D canvas with outline representation of each selected room
2. **Given** canvas is displaying rooms, **When** viewing room outlines, **Then** each room has unique border color (cycling through: blue, green, purple, orange) with dashed borders
3. **Given** room outlines are rendered, **When** viewing canvas, **Then** each room displays its name as a label centered within the outline
4. **Given** rooms are rendered on canvas, **When** door estimation completes, **Then** displays orange door symbols at estimated doorway locations on room borders
5. **Given** canvas shows multiple rooms, **When** rooms share estimated door locations, **Then** door symbols connect rooms with visual link indicating relationship
6. **Given** user views canvas, **When** no doors detected, **Then** rooms are positioned with default spacing without door connections

---

### User Story 6 - Interactive Room Selection on Canvas (Priority: P1)

Users can tap on room outlines in the canvas to select/deselect individual rooms for manipulation. Selected rooms are highlighted with a different visual treatment (solid border instead of dashed), and only selected rooms can be moved or rotated. Tapping the same room again deselects it.

**Why this priority**: Selection mechanism is fundamental for enabling room manipulation - users need a clear way to indicate which room they want to adjust before moving, rotating, or adding doors.

**Independent Test**: Open canvas with 3 rooms, tap on Kitchen outline to select it (border becomes solid), tap Move button and drag Kitchen to new position, tap Kitchen again to deselect (border becomes dashed), verify other rooms remain in original positions.

**Acceptance Scenarios**:

1. **Given** canvas displays room outlines, **When** user taps on a room outline, **Then** room becomes selected with solid border and slightly brighter color
2. **Given** a room is selected, **When** user taps on the same room again, **Then** room becomes deselected returning to dashed border
3. **Given** one room is selected, **When** user taps on a different room, **Then** previous room deselects and new room becomes selected (single-selection mode)
4. **Given** no room is selected, **When** user taps "Select" button, **Then** enters selection mode with visual indicator (blue button highlight)
5. **Given** a room is selected, **When** viewing bottom toolbar, **Then** Move, Rotate, and Add Door buttons become enabled
6. **Given** no room is selected, **When** viewing bottom toolbar, **Then** Move, Rotate, and Add Door buttons are disabled/grayed out

---

### User Story 7 - Room Manipulation (Move and Rotate) (Priority: P1)

After selecting a room on the canvas, users can move it to a different position by dragging or tapping Move button, and rotate it in configurable degree increments (default 45°) using the Rotate button. Movement and rotation are constrained to the canvas bounds and provide visual feedback during manipulation.

**Why this priority**: Room positioning is critical for accurate stitching - users must be able to adjust room alignment to match real-world spatial relationships, especially when automatic alignment fails or needs refinement.

**Independent Test**: Select Kitchen room, tap Move button, drag Kitchen outline 100 pixels to the right, release to confirm new position, tap Rotate button 2 times, verify Kitchen rotates 90° clockwise (2 × 45°), verify door symbols move with room and maintain connections.

**Acceptance Scenarios**:

1. **Given** room is selected and Move button enabled, **When** user taps Move button, **Then** enters move mode with visual indicator (Move button highlighted, cursor changes)
2. **Given** in move mode, **When** user drags room outline, **Then** room follows drag gesture in real-time with smooth animation
3. **Given** room is being moved, **When** drag ends, **Then** room snaps to final position and move mode deactivates
4. **Given** room is selected and Rotate button enabled, **When** user taps Rotate button, **Then** room rotates by configured degrees (default 45° clockwise)
5. **Given** rotation configuration exists in .env (ROOM_ROTATION_DEGREES=45), **When** app loads, **Then** Rotate button uses configured degree value for each rotation step
6. **Given** room has door symbols, **When** room is moved or rotated, **Then** door symbols move with room maintaining their relative positions on borders
7. **Given** connected rooms via doors, **When** one room is moved, **Then** door connection line stretches/adjusts to maintain visual link between rooms
8. **Given** room is rotated 8 times at 45°, **When** completing full 360° rotation, **Then** room returns to original orientation

---

### User Story 8 - Door Management and Room Connections (Priority: P2)

Users can manually add door symbols by activating a room and clicking on its border, creating a red door marker at the clicked location. Door symbols from different rooms can be connected to establish relationships between rooms. The stitching algorithm uses these door connections to guide room alignment and create seamless transitions.

**Why this priority**: Manual door placement gives users control over room connections when automatic door detection fails or when users want to define specific connection points for better stitching results.

**Independent Test**: Select Living Room, tap "Add Door" button, tap on right border of Living Room outline to place door symbol (red), select Kitchen, tap on left border of Kitchen to place second door, verify system suggests connecting the two doors with visual link, tap "Done" to save door configuration with stitching job.

**Acceptance Scenarios**:

1. **Given** room is selected, **When** user taps "Add Door" button, **Then** enters door placement mode with visual indicator (Add Door button highlighted, border glow effect)
2. **Given** in door placement mode, **When** user taps on room border, **Then** places red door symbol at tap location on border edge
3. **Given** door symbol placed, **When** placement completes, **Then** exits door placement mode and door symbol remains on border
4. **Given** two rooms have door symbols, **When** doors are within connection threshold distance (< 50 pixels), **Then** system displays suggested connection line (dashed yellow line) between doors
5. **Given** door connection suggested, **When** user taps on connection line, **Then** connection becomes confirmed (solid green line) and stored in stitching configuration
6. **Given** doors are connected, **When** user taps "Done" button, **Then** stitching job includes door connection metadata with room IDs and door positions
7. **Given** door symbols exist, **When** user taps on existing door symbol, **Then** shows door action menu with options: "Delete Door" or "Adjust Position"
8. **Given** user deletes door, **When** door was part of connection, **Then** connection is removed and other room's door becomes unconnected

---

### Edge Cases

- **What happens when user has only 1 scan?** - Room stitching button is disabled with minimum requirement message "Need 2+ scans to stitch"
- **What happens if backend stitching fails due to insufficient overlap?** - Error dialog displays with specific message "Insufficient overlap detected. Scan with more overlap between rooms" and option to retry or cancel
- **What happens if user loses network connection during stitching?** - Polling continues to retry, timeout after 5 minutes shows error dialog with retry option
- **What happens if user exits app during stitching?** - Stitching continues on backend, but progress is lost. User must restart stitching from scan list. Job is eventually cleaned up by backend timeout
- **What happens if stitched model download fails?** - Error dialog shows "Failed to download stitched model" with retry option to re-attempt download from cached job result URL
- **What happens if user selects very large rooms (100+ MB combined)?** - Upload takes longer, progress stays at "Uploading" longer, but eventually progresses. Backend enforces size limits and returns error if exceeded
- **What happens when user taps back during progress?** - Shows confirmation dialog "Stitching in progress. Leave anyway?" with options to stay or abort
- **What happens when room outlines overlap completely on canvas?** - System detects overlap and shows warning "Rooms overlapping - adjust positions for better stitching"
- **What happens when user tries to move room outside canvas bounds?** - Movement is constrained to canvas edges, room cannot be dragged beyond visible area
- **What happens when door estimation fails for a scan?** - Room renders without door symbols, user can manually add doors using Add Door function
- **What happens when user rotates room with connected doors?** - Door connection lines rotate with room and stretch to maintain connection, may show warning if connection angle becomes unrealistic (> 90° bend)
- **What happens when user places door too close to corner?** - System snaps door to nearest valid border position, maintaining minimum distance from corners (10% of border length)
- **What happens when ROOM_ROTATION_DEGREES not set in .env?** - App uses default value of 45° and logs warning message
- **What happens when user connects doors that are too far apart?** - Connection line stretches but displays warning indicator (yellow color) suggesting rooms should be repositioned closer
- **What happens when user taps Done without connecting any doors?** - Shows confirmation dialog "No door connections set. Stitch with automatic alignment?" with Continue/Cancel options

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
- **FR-018**: System MUST render 2D canvas representation of selected room scans before stitching begins
- **FR-019**: System MUST extract room outline/boundary from 3D scan data and render as 2D polygon on canvas
- **FR-020**: System MUST assign unique visual styling to each room outline (color cycling: blue, green, purple, orange) with dashed borders
- **FR-021**: System MUST display room name as text label centered within each room outline on canvas
- **FR-022**: System MUST estimate door locations from scan geometry and display as symbols on room borders
- **FR-023**: System MUST support single-selection interaction where tapping room outline toggles selection state (selected/unselected)
- **FR-024**: System MUST visually distinguish selected rooms with solid borders and brighter colors
- **FR-025**: System MUST enable Move, Rotate, and Add Door buttons only when a room is selected
- **FR-026**: System MUST support drag gesture to move selected room within canvas bounds
- **FR-027**: System MUST rotate selected room by configured degrees (default 45°) when Rotate button tapped
- **FR-028**: System MUST read ROOM_ROTATION_DEGREES from .env file for rotation increment configuration (fallback: 45°)
- **FR-029**: System MUST constrain room movement to canvas boundaries preventing rooms from moving outside visible area
- **FR-030**: System MUST update door symbol positions when room is moved or rotated maintaining relative border positions
- **FR-031**: System MUST allow manual door placement on room borders when in Add Door mode
- **FR-032**: System MUST display door connection suggestions (dashed yellow lines) when two doors are within 50-pixel threshold
- **FR-033**: System MUST allow users to confirm door connections by tapping suggestion line (changes to solid green)
- **FR-034**: System MUST include door connection metadata (room IDs, door positions, rotation angles) in stitching request when Done tapped
- **FR-035**: System MUST persist room layout configuration (positions, rotations, door connections) in scan metadata for later retrieval
- **FR-036**: System MUST provide door action menu (Delete/Adjust) when user taps existing door symbol

### Key Entities

- **RoomStitchRequest**: Request to backend containing project ID, list of scan IDs to stitch, optional map of room names, and room layout configuration (positions, rotations, door connections)
- **RoomStitchJob**: Represents ongoing stitching operation with job ID, status enum (pending/uploading/processing/aligning/merging/completed/failed), progress percentage, optional error message, and result URL when complete
- **StitchedModel**: Completed stitching result containing job ID, list of source scan IDs, GLB file path on device, file size, creation timestamp, and optional room names metadata
- **RoomOutline**: 2D polygon representation of room boundaries extracted from 3D scan with: scan ID, list of points (x, y coordinates), center point, bounding box, estimated dimensions
- **RoomLayout**: Canvas state for a room containing: room outline, position (x, y), rotation angle (degrees), visual style (color, border width), selection state, associated door symbols
- **DoorSymbol**: Represents doorway connection point with: unique ID, parent room ID, position on room border (edge index, offset), symbol type (estimated/manual), connection status (unconnected/suggested/confirmed), connected door ID
- **DoorConnection**: Represents link between two doors with: connection ID, door A ID, door B ID, connection type (automatic/manual), visual style (dashed/solid), distance between doors
- **CanvasConfiguration**: Canvas settings including: canvas width/height, zoom level, pan offset, grid settings, snap-to-grid enabled, rotation increment from .env

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
- **SC-009**: Canvas renders room outlines for 2-5 scans in under 1 second after scan selection
- **SC-010**: Room selection responds to tap within 100ms with immediate visual feedback
- **SC-011**: Room movement via drag gesture maintains 60fps animation with no lag or jitter
- **SC-012**: Door estimation accuracy exceeds 70% for rooms with clear doorway geometry
- **SC-013**: Users can position and connect 3+ rooms with manual doors in under 2 minutes without training
- **SC-014**: Canvas manipulation (select, move, rotate, add door) works intuitively without requiring user manual or tooltips for 80%+ of users
- **SC-015**: Room layout configuration persists across app restarts allowing users to resume stitching work
- **SC-016**: Door connection suggestions appear within 500ms when doors move within threshold distance

## Dependencies

- **Depends on**: Feature 016-multi-room-options (scan session management, scan list UI)
- **Depends on**: Backend room stitching API (job creation, status polling, model download endpoints, room layout metadata support)
- **Depends on**: Device AR capabilities (ARKit on iOS, ARCore on Android) for AR preview
- **Depends on**: Flutter CustomPainter for canvas rendering
- **Depends on**: 3D geometry processing library for room outline extraction from USDZ/GLB files
- **Depends on**: .env configuration for rotation increment (ROOM_ROTATION_DEGREES)
- **Blocks**: Advanced 3D model editing features, multi-floor building stitching

## Assumptions

- Backend stitching service is operational and accessible
- Backend enforces max file size limits (likely 200-300MB total)
- Stitching typically completes within 2-5 minutes for 2-3 rooms
- Backend supports USDZ input and returns GLB/USDZ output
- Backend accepts room layout metadata (positions, rotations, door connections) in stitching request
- Device has sufficient storage for downloading stitched models (50-200MB typically)
- Network connection is reasonably stable during upload/download phases
- AR viewer (QuickLook on iOS, Scene Viewer on Android) is available on device
- 3D scan files contain sufficient geometric data to extract 2D floor plan outlines
- Door detection can achieve 70%+ accuracy using geometry analysis (wall openings, gaps in mesh)
- Canvas interaction (touch/drag) works smoothly on devices with minimum 2GB RAM
- .env file is accessible at project root for configuration reading
- Room outline extraction completes in under 500ms per scan on target devices

## Out of Scope

- Real-time preview during stitching (only final result preview)
- Stitching optimization hints (suggestions for better overlap)
- Batch stitching (combining multiple sets of rooms in one operation)
- Stitching history and versioning (re-stitch with different room combinations)
- Local offline stitching (requires backend processing)
- Automatic room layout optimization (AI-powered optimal positioning)
- Wall thickness editing or detailed floor plan CAD features
- Multi-floor/multi-story building support (vertical room relationships)
- Curved wall or irregular room shape editing
- Furniture or object placement within rooms
- Measurement tools or dimension annotations on canvas
- Export of room layout as separate image/PDF file
- Undo/redo for individual canvas operations (only session-level undo via back button)
