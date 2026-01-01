# Tasks: Multi-Room Scanning Options

**Feature**: `016-multi-room-options`
**Input**: Design documents from `/specs/016-multi-room-options/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/room-stitching-api.graphql

**Tests**: Test tasks included per constitution requirement (TDD mandatory)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Mobile Flutter project structure:
- Source: `lib/features/scanning/`
- Tests: `test/features/scanning/`
- Integration tests: `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and JSON serialization setup

**Status**: User Story 1 already 100% complete - no setup tasks needed

- [ ] T001 Verify existing Feature 014 and Feature 015 infrastructure working correctly
- [ ] T002 [P] Review GraphQL API contract in specs/016-multi-room-options/contracts/room-stitching-api.graphql
- [ ] T003 [P] Coordinate with backend team on stitching API endpoint availability timeline

**Checkpoint**: Foundation verified - ready for User Story 2 implementation

---

## Phase 2: User Story 2 - Room Stitching for Complete Property Model (Priority: P2) 🎯 CORE VALUE

**Goal**: Enable users to merge 2+ room scans into a single cohesive 3D property model via backend API with progress tracking and preview

**Independent Test**: Scan two adjacent rooms with overlapping doorway area, select both scans for stitching, initiate merge, verify stitched model shows both rooms correctly aligned with seamless transition (AS2-1 to AS2-6 in spec.md)

**Implementation Status**: ❌ PLACEHOLDER ONLY - Button exists but shows "coming soon" snackbar

### Tests for User Story 2 (TDD - Write FIRST, Ensure FAIL)

- [ ] T004 [P] [US2] Unit test for RoomStitchRequest validation in test/features/scanning/models/room_stitch_request_test.dart (minimum 2 scans, isValid(), generateFilename(), toGraphQLVariables())
- [ ] T005 [P] [US2] Unit test for RoomStitchJob state transitions in test/features/scanning/models/room_stitch_job_test.dart (isTerminal, isSuccessful, statusMessage, copyWith())
- [ ] T006 [P] [US2] Unit test for StitchedModel display logic in test/features/scanning/models/stitched_model_test.dart (displayName, fromJob factory)
- [ ] T007 [P] [US2] Unit test for RoomStitchingService GraphQL mutation in test/features/scanning/services/room_stitching_service_test.dart (startStitching with mock GraphQLService)
- [ ] T008 [P] [US2] Unit test for RoomStitchingService polling logic in test/features/scanning/services/room_stitching_service_test.dart (pollStitchStatus, 2-second interval, maxAttempts timeout, status change callback)
- [ ] T009 [P] [US2] Unit test for RoomStitchingService download logic in test/features/scanning/services/room_stitching_service_test.dart (downloadStitchedModel, file save to Documents/scans/)
- [ ] T010 [P] [US2] Widget test for RoomStitchingScreen in test/features/scanning/screens/room_stitching_screen_test.dart (scan selection UI, checkboxes, "Start Stitching" button, validation: minimum 2 scans)
- [ ] T011 [P] [US2] Widget test for RoomStitchProgressScreen in test/features/scanning/screens/room_stitch_progress_screen_test.dart (progress indicator, status message updates, polling behavior, terminal state navigation)
- [ ] T012 [P] [US2] Widget test for StitchedModelPreviewScreen in test/features/scanning/screens/stitched_model_preview_screen_test.dart (GLB viewer, action buttons: View in AR, Export, Save to Project)
- [ ] T013 [US2] Integration test for complete stitching flow in integration_test/room_stitching_flow_test.dart (scan list → select scans → initiate stitching → poll progress → preview result)

### Implementation for User Story 2

**Models** (Data layer - can be done in parallel):

- [ ] T014 [P] [US2] Create RoomStitchRequest model in lib/features/scanning/models/room_stitch_request.dart (fields: projectId, scanIds, alignmentMode, outputFormat, roomNames; methods: isValid(), generateFilename(), toGraphQLVariables(); JSON serialization)
- [ ] T015 [P] [US2] Create RoomStitchJob model in lib/features/scanning/models/room_stitch_job.dart (fields: jobId, status enum, progress, errorMessage, resultUrl, createdAt, completedAt, estimatedDurationSeconds; getters: isTerminal, isSuccessful, elapsedSeconds, statusMessage; copyWith() for polling updates; JSON serialization)
- [ ] T016 [P] [US2] Create StitchedModel model in lib/features/scanning/models/stitched_model.dart (fields: id, localPath, originalScanIds, roomNames, fileSizeBytes, createdAt, format; getter: displayName; factory: fromJob(); JSON serialization)
- [ ] T017 [US2] Run build_runner to generate JSON serialization code for new models (flutter pub run build_runner build --delete-conflicting-outputs)

**Service** (Business logic - depends on models):

- [ ] T018 [US2] Create RoomStitchingService with GraphQL mutation in lib/features/scanning/services/room_stitching_service.dart (startStitching method: validate request, call StitchRooms mutation, return RoomStitchJob)
- [ ] T019 [US2] Implement polling logic in RoomStitchingService (pollStitchStatus method: 2-second interval, maxAttempts=60, status change callback, terminal state detection, RetryPolicyService integration for errors)
- [ ] T020 [US2] Implement download logic in RoomStitchingService (downloadStitchedModel method: fetch from resultUrl, save to Documents/scans/, return File)
- [ ] T021 [US2] Add error handling and offline queue integration in RoomStitchingService (use Feature 015 offline queue for stitching requests when offline per FR-019)

**UI - Stitching Selection Screen**:

- [ ] T022 [US2] Create RoomStitchingScreen widget in lib/features/scanning/screens/room_stitching_screen.dart (display scan list with checkboxes, show room names or "Scan N", "Start Stitching" button, validation: minimum 2 scans selected)
- [ ] T023 [US2] Add navigation from scan_list_screen.dart to RoomStitchingScreen (replace "coming soon" snackbar at line 378-385 with Navigator.push to RoomStitchingScreen, pass scans from ScanSessionManager)
- [ ] T024 [US2] Add scan selection state management in RoomStitchingScreen (Set<String> for selected scan IDs, toggle selection on checkbox tap, validate minimum 2 scans before enabling "Start Stitching")
- [ ] T025 [US2] Add authentication check in RoomStitchingScreen (prompt guest users to create account before initiating stitch per FR-020)

**UI - Progress Tracking Screen**:

- [ ] T026 [US2] Create RoomStitchProgressScreen widget in lib/features/scanning/screens/room_stitch_progress_screen.dart (CircularProgressIndicator with progress value, status message Text, estimated time remaining display)
- [ ] T027 [US2] Implement polling initiation in RoomStitchProgressScreen initState (call RoomStitchingService.pollStitchStatus with jobId, update UI on status change callback)
- [ ] T028 [US2] Add success navigation in RoomStitchProgressScreen (when job.isSuccessful, download stitched model, create StitchedModel, navigate to StitchedModelPreviewScreen)
- [ ] T029 [US2] Add failure handling in RoomStitchProgressScreen (display AlertDialog with errorMessage, provide "Retry" and "Cancel" buttons, map error codes to user-friendly messages via ErrorMessageService)

**UI - Preview Screen**:

- [ ] T030 [US2] Create StitchedModelPreviewScreen widget in lib/features/scanning/screens/stitched_model_preview_screen.dart (use ModelViewer from model_viewer_plus to display GLB, show model metadata: room names, file size, polygon count if available)
- [ ] T031 [US2] Add action buttons to StitchedModelPreviewScreen ("View in AR" button: launch AR Quick Look on iOS, "Export GLB" button: share file via platform share sheet, "Save to Project" button: upload to project via existing upload service)
- [ ] T032 [US2] Add Semantics labels for accessibility in StitchedModelPreviewScreen (label for model viewer, labels for action buttons, announce completion to screen readers)

**Checkpoint**: At this point, User Story 2 should be fully functional - users can stitch 2+ room scans, track progress, and preview stitched model independently

---

## Phase 3: User Story 3 - Scan Organization and Naming (Priority: P3)

**Goal**: Enable users to assign meaningful names to room scans (e.g., "Living Room", "Master Bedroom") for easier identification during stitching and export

**Independent Test**: Scan three rooms, tap edit on each scan, assign names "Kitchen", "Dining Room", "Living Room", verify names persist in scan list and are used in stitching selection screen (AS3-1 to AS3-4 in spec.md)

**Implementation Status**: ❌ NOT IMPLEMENTED - Currently scans display as "Scan 1", "Scan 2" with no naming UI

### Tests for User Story 3 (TDD - Write FIRST, Ensure FAIL)

- [ ] T033 [P] [US3] Unit test for RoomNameValidator in test/features/scanning/utils/room_name_validator_test.dart (isValid: max 50 chars, alphanumeric + spaces + emojis; validate: return error messages for invalid input)
- [ ] T034 [P] [US3] Unit test for FilenameSanitizer in test/features/scanning/utils/filename_sanitizer_test.dart (sanitizeForFilename: replace spaces with hyphens, remove special chars, convert emojis to hex codes; generateGlbFilename: include room name and timestamp)
- [ ] T035 [P] [US3] Unit test for ScanData.roomName field in test/features/scanning/models/scan_data_test.dart (roomNameOrDefault getter: return roomName if set, else "Scan N"; copyWith preserves roomName)
- [ ] T036 [P] [US3] Widget test for ScanNameEditorDialog in test/features/scanning/widgets/scan_name_editor_dialog_test.dart (TextFormField with validation, "Save" and "Cancel" buttons, keyboard shows on open)
- [ ] T037 [US3] Integration test for scan naming flow in integration_test/scan_naming_flow_test.dart (tap edit on scan → enter name → save → verify name persists in scan list → verify name used in export filename)

### Implementation for User Story 3

**Utilities** (Validation and sanitization - can be done in parallel):

- [ ] T038 [P] [US3] Create RoomNameValidator utility in lib/features/scanning/utils/room_name_validator.dart (static methods: isValid(String name), validate(String? value); constants: maxLength=50, regex pattern for alphanumeric + spaces + emojis)
- [ ] T039 [P] [US3] Create FilenameSanitizer utility in lib/features/scanning/utils/filename_sanitizer.dart (static methods: sanitizeForFilename(String roomName), generateGlbFilename(String roomName, String scanId); logic: replace spaces with hyphens, convert emojis to hex codes, remove special chars, limit to 40 chars for filename)

**Model Update**:

- [ ] T040 [US3] Add roomName field to ScanData model in lib/features/scanning/models/scan_data.dart (add final String? roomName field, add to constructor, add to copyWith(), add roomNameOrDefault(int sequenceNumber) getter, update JSON serialization)
- [ ] T041 [US3] Run build_runner to regenerate JSON serialization for updated ScanData model (flutter pub run build_runner build --delete-conflicting-outputs)

**UI - Name Editor Dialog**:

- [ ] T042 [US3] Create ScanNameEditorDialog widget in lib/features/scanning/widgets/scan_name_editor_dialog.dart (AlertDialog with TextFormField, use RoomNameValidator.validate for validation, "Save" button, "Cancel" button, focus on open)
- [ ] T043 [US3] Add Semantics labels for accessibility in ScanNameEditorDialog (label for text field, hint text, labels for buttons)

**UI - Integration into Scan List**:

- [ ] T044 [US3] Add edit icon button to scan cards in scan_list_screen.dart (IconButton with Icons.edit, positioned in trailing position, onPressed: show ScanNameEditorDialog)
- [ ] T045 [US3] Implement long-press gesture to open name editor in scan_list_screen.dart (GestureDetector with onLongPress callback, shows ScanNameEditorDialog, provide haptic feedback on long-press)
- [ ] T046 [US3] Update scan list UI to display room names in scan_list_screen.dart (use scan.roomNameOrDefault(index + 1) instead of hardcoded "Scan N", update subtitle to show room name prominently)
- [ ] T047 [US3] Pass room names to RoomStitchingScreen in room_stitching_screen.dart (display room names in scan selection checklist instead of "Scan N", include room names in RoomStitchRequest when initiating stitching)

**Export Integration**:

- [ ] T048 [US3] Update export filename generation to include room names (use FilenameSanitizer.generateGlbFilename when exporting individual scans, filename format: "{sanitized-room-name}-{scanId}-{date}.glb")

**Checkpoint**: At this point, User Story 3 should be fully functional - users can name scans and names persist throughout stitching and export workflows independently of User Story 2 and 4

---

## Phase 4: User Story 4 - Batch Operations on Multiple Scans (Priority: P4)

**Goal**: Enable users to perform bulk actions on multiple scans simultaneously (export all, upload all, delete all) to reduce repetitive tapping

**Independent Test**: Scan four rooms, select three using checkboxes, tap "Export All", verify all three scans export as separate GLB files in one batch operation (AS4-1 to AS4-5 in spec.md)

**Implementation Status**: ❌ NOT IMPLEMENTED - No multi-select UI in scan list, individual upload/export only

### Tests for User Story 4 (TDD - Write FIRST, Ensure FAIL)

- [ ] T049 [P] [US4] Widget test for multi-select mode activation in test/features/scanning/screens/scan_list_screen_test.dart (long-press any scan → enters multi-select mode → checkboxes appear → AppBar title changes to "X selected")
- [ ] T050 [P] [US4] Widget test for scan selection toggling in test/features/scanning/screens/scan_list_screen_test.dart (tap scan in multi-select mode → toggles checkbox → updates selected count → exits mode when all deselected)
- [ ] T051 [P] [US4] Widget test for BatchActionBottomSheet in test/features/scanning/widgets/batch_action_bottom_sheet_test.dart ("Export All", "Upload All", "Delete All" buttons visible, selectedCount displayed correctly)
- [ ] T052 [US4] Integration test for batch export flow in integration_test/batch_operations_flow_test.dart (long-press scan → select 3 scans → tap "Export All" → verify progress dialog → verify 3 GLB files exported)
- [ ] T053 [US4] Integration test for batch delete flow in integration_test/batch_operations_flow_test.dart (select multiple scans → tap "Delete All" → confirm → verify scans removed → verify single Undo snackbar)

### Implementation for User Story 4

**UI - Multi-Select State Management**:

- [ ] T054 [US4] Add multi-select mode state to scan_list_screen.dart (bool _multiSelectMode, Set<String> _selectedScanIds, methods: _enterMultiSelectMode(), _exitMultiSelectMode(), _toggleScanSelection(String scanId))
- [ ] T055 [US4] Implement long-press gesture to enter multi-select mode in scan_list_screen.dart (GestureDetector with onLongPress on scan card, call _enterMultiSelectMode() and _toggleScanSelection(), provide haptic feedback)
- [ ] T056 [US4] Update scan card tap behavior for multi-select mode in scan_list_screen.dart (if _multiSelectMode: toggle selection, else: open preview as normal)
- [ ] T057 [US4] Update AppBar to show selection count in scan_list_screen.dart (title: _multiSelectMode ? "${_selectedScanIds.length} selected" : "Scans", leading: _multiSelectMode ? IconButton(Icons.close, onPressed: _exitMultiSelectMode) : null)

**UI - Checkbox Visual Feedback**:

- [ ] T058 [US4] Add checkboxes to scan cards in scan_list_screen.dart (leading widget: _multiSelectMode ? Checkbox(value: _selectedScanIds.contains(scan.id)) : ScanThumbnail(scan), highlight selected cards with background color)
- [ ] T059 [US4] Add Semantics labels for multi-select mode in scan_list_screen.dart (announce mode change "Multi-select mode enabled", announce selection state per scan "Kitchen scan selected")

**UI - Batch Action Bottom Sheet**:

- [ ] T060 [US4] Create BatchActionBottomSheet widget in lib/features/scanning/widgets/batch_action_bottom_sheet.dart (display selectedCount, 3 action buttons: "Export All", "Upload All", "Delete All", each with icon and label)
- [ ] T061 [US4] Add bottom sheet display logic in scan_list_screen.dart (show BatchActionBottomSheet when _multiSelectMode && _selectedScanIds.isNotEmpty, pass callbacks: onExportAll, onUploadAll, onDeleteAll)

**Batch Operations Logic**:

- [ ] T062 [US4] Implement batch export in scan_list_screen.dart (_handleExportAll method: loop through _selectedScanIds, export each scan to GLB using existing export service, show progress dialog "Exporting 3 scans... (2/3 complete)", dismiss on completion)
- [ ] T063 [US4] Implement batch upload in scan_list_screen.dart (_handleUploadAll method: show project selection dialog, loop through _selectedScanIds, upload each scan to selected project using existing upload service, show progress dialog, dismiss on completion, exit multi-select mode)
- [ ] T064 [US4] Implement batch delete in scan_list_screen.dart (_handleDeleteAll method: show confirmation dialog, loop through _selectedScanIds, remove scans from ScanSessionManager, show single Undo snackbar for all deletions, exit multi-select mode)
- [ ] T065 [US4] Add cancellation support for batch operations in scan_list_screen.dart (add "Cancel" button to progress dialog, set cancellation flag, stop loop on cancel, show partial completion message "Exported 2 of 5 scans")

**Progress Feedback**:

- [ ] T066 [US4] Create progress dialog for batch operations in scan_list_screen.dart (AlertDialog with LinearProgressIndicator, status text "Exporting 3 scans... (2/3 complete)", "Cancel" button)
- [ ] T067 [US4] Add Semantics labels for batch operation progress (announce progress updates to screen readers, "Exporting scan 2 of 3")

**Checkpoint**: At this point, User Story 4 should be fully functional - users can select multiple scans and perform batch operations independently of User Stories 2 and 3

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements affecting multiple user stories, final integration, and quality assurance

- [ ] T068 [P] Add error message translations for stitching errors in lib/features/scanning/services/error_message_service.dart (map error codes: INSUFFICIENT_OVERLAP → "Scan with more overlap between rooms", ALIGNMENT_FAILURE → "Scans incompatible", BACKEND_TIMEOUT → "Processing took too long", UNAUTHORIZED → "Please sign in")
- [ ] T069 [P] Add logging for stitching operations (log stitching job initiation, status changes, completion, errors; include jobId, scanIds, room names for debugging)
- [ ] T070 [P] Update CLAUDE.md with Feature 016 patterns (document multi-select pattern, polling pattern for long-running jobs, room naming pattern, add to "Recent Changes" section)
- [ ] T071 [P] Run quickstart.md validation scenarios (verify 5-minute setup, test all code patterns, run integration tests, confirm developer onboarding guide accurate)
- [ ] T072 Verify all Semantics labels for accessibility (screen reader test: navigate through stitching flow, scan naming, batch operations; verify all interactive elements have labels, verify touch targets 44x44 minimum)
- [ ] T073 Performance profiling for stitching UI (measure RoomStitchingScreen load time < 200ms, measure progress polling overhead, measure StitchedModelPreviewScreen load time < 3s for 50MB GLB)
- [ ] T074 Final integration test covering all user stories (US1 → scan multiple rooms → US3 → name scans → US2 → stitch scans → US4 → batch export remaining scans)
- [ ] T075 Code review and refactoring (remove dead code, consolidate duplicate logic, ensure consistent error handling, verify no TODO comments remain)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (verification tasks only)
- **User Story 2 (Phase 2)**: Depends on Setup completion - CORE VALUE STORY
  - Can start immediately after Phase 1 verification
  - Tests MUST be written and FAIL before implementation
- **User Story 3 (Phase 3)**: Depends on Setup completion - INDEPENDENT of US2
  - Can start in parallel with US2 if team capacity allows
  - Enhances US2 but not required for US2 functionality
- **User Story 4 (Phase 4)**: Depends on Setup completion - INDEPENDENT of US2 and US3
  - Can start in parallel with US2 and US3 if team capacity allows
  - Works with or without room names from US3
- **Polish (Phase 5)**: Depends on completion of desired user stories
  - Can start after US2 (MVP)
  - Or wait for US2+US3+US4 (full feature set)

### User Story Dependencies

- **User Story 2 (P2)**: INDEPENDENT - No dependencies on US3 or US4
  - Can be tested and deployed without room naming or batch operations
  - Room names optional in stitching request
- **User Story 3 (P3)**: INDEPENDENT - No dependencies on US2 or US4
  - Can be tested and deployed without stitching or batch operations
  - Enhances US2 if both implemented, but not required
- **User Story 4 (P4)**: INDEPENDENT - No dependencies on US2 or US3
  - Can be tested and deployed without stitching or room naming
  - Batch operations work with default "Scan N" labels or room names if US3 implemented

### Within Each User Story

**User Story 2 (Room Stitching)**:
1. Tests (T004-T013) - Write FIRST, ensure FAIL
2. Models (T014-T017) - Can run in parallel, no interdependencies
3. Service (T018-T021) - Depends on models (T017 complete)
4. UI Screens (T022-T032) - Depends on service (T021 complete)
5. Integration test (T013) - Run after all implementation complete

**User Story 3 (Scan Naming)**:
1. Tests (T033-T037) - Write FIRST, ensure FAIL
2. Utilities (T038-T039) - Can run in parallel, no interdependencies
3. Model update (T040-T041) - Can run in parallel with utilities
4. UI components (T042-T048) - Depends on utilities and model update complete

**User Story 4 (Batch Operations)**:
1. Tests (T049-T053) - Write FIRST, ensure FAIL
2. State management (T054-T057) - Must be done sequentially in scan_list_screen.dart
3. Checkboxes and bottom sheet (T058-T061) - Depends on state management
4. Batch operations logic (T062-T067) - Depends on UI components complete

### Parallel Opportunities

**Within User Story 2**:
```bash
# All tests can run in parallel:
T004, T005, T006, T007, T008, T009, T010, T011, T012 (in parallel)

# All models can run in parallel:
T014, T015, T016 (in parallel) → T017 (build_runner)

# UI screens can run in parallel once service complete:
T022, T026, T030 (in parallel after T021)
```

**Within User Story 3**:
```bash
# All tests can run in parallel:
T033, T034, T035, T036 (in parallel)

# Utilities and model can run in parallel:
T038, T039, T040 (in parallel) → T041 (build_runner)
```

**Across User Stories** (if team capacity allows):
```bash
# After Phase 1 complete, all user stories can start in parallel:
Team Member A: User Story 2 (T004-T032)
Team Member B: User Story 3 (T033-T048)
Team Member C: User Story 4 (T049-T067)

# Each story is independently testable and deployable
```

---

## Parallel Example: User Story 2 (Room Stitching)

```bash
# Step 1: Launch all tests together (write first, ensure they FAIL):
Task T004: "Unit test for RoomStitchRequest validation in test/features/scanning/models/room_stitch_request_test.dart"
Task T005: "Unit test for RoomStitchJob state transitions in test/features/scanning/models/room_stitch_job_test.dart"
Task T006: "Unit test for StitchedModel display logic in test/features/scanning/models/stitched_model_test.dart"
Task T007: "Unit test for RoomStitchingService GraphQL mutation in test/features/scanning/services/room_stitching_service_test.dart"
Task T008: "Unit test for RoomStitchingService polling logic in test/features/scanning/services/room_stitching_service_test.dart"
Task T009: "Unit test for RoomStitchingService download logic in test/features/scanning/services/room_stitching_service_test.dart"
Task T010: "Widget test for RoomStitchingScreen in test/features/scanning/screens/room_stitching_screen_test.dart"
Task T011: "Widget test for RoomStitchProgressScreen in test/features/scanning/screens/room_stitch_progress_screen_test.dart"
Task T012: "Widget test for StitchedModelPreviewScreen in test/features/scanning/screens/stitched_model_preview_screen_test.dart"

# Step 2: Launch all model implementations together:
Task T014: "Create RoomStitchRequest model in lib/features/scanning/models/room_stitch_request.dart"
Task T015: "Create RoomStitchJob model in lib/features/scanning/models/room_stitch_job.dart"
Task T016: "Create StitchedModel model in lib/features/scanning/models/stitched_model.dart"

# Step 3: After models complete, launch service tasks:
Task T018: "Create RoomStitchingService with GraphQL mutation"
Task T019: "Implement polling logic in RoomStitchingService"
Task T020: "Implement download logic in RoomStitchingService"
Task T021: "Add error handling and offline queue integration"

# Step 4: After service complete, launch UI screens in parallel:
Task T022: "Create RoomStitchingScreen widget"
Task T026: "Create RoomStitchProgressScreen widget"
Task T030: "Create StitchedModelPreviewScreen widget"
```

---

## Implementation Strategy

### MVP First (User Story 2 Only)

**Goal**: Deliver core stitching functionality as quickly as possible

1. Complete Phase 1: Setup (T001-T003) - verification only
2. Complete Phase 2: User Story 2 (T004-T032) - room stitching
3. **STOP and VALIDATE**: Test User Story 2 independently (AS2-1 to AS2-6 from spec.md)
4. Deploy MVP if stitching works correctly

**Benefits**:
- Users can merge multi-room scans immediately
- Early feedback on stitching UX and backend API
- Validates core technical approach (polling, progress tracking)

**Limitations**:
- No room naming (scans labeled "Scan 1", "Scan 2")
- No batch operations (must export/upload individually)

### Incremental Delivery

**Recommended Approach**: Deliver each user story independently

1. **Sprint 1**: Setup + User Story 2 (T001-T032)
   - Deploy: Users can stitch rooms with default names
   - Test independently: Room stitching flow end-to-end

2. **Sprint 2**: User Story 3 (T033-T048)
   - Deploy: Users can name scans for better organization
   - Test independently: Scan naming flow end-to-end
   - Benefit: Enhances User Story 2 retroactively

3. **Sprint 3**: User Story 4 (T049-T067)
   - Deploy: Users can batch export/upload/delete
   - Test independently: Batch operations flow end-to-end
   - Benefit: Works with or without room names

4. **Sprint 4**: Polish (T068-T075)
   - Deploy: Final quality improvements
   - Validate: All user stories work together seamlessly

**Each sprint delivers independent value without breaking previous functionality**

### Parallel Team Strategy

With 3 developers after Phase 1 complete:

```text
Developer A:
  - User Story 2: Room Stitching (T004-T032)
  - ~30 tasks, estimated 2-3 weeks
  - Critical path: Models → Service → UI screens

Developer B:
  - User Story 3: Scan Naming (T033-T048)
  - ~16 tasks, estimated 1 week
  - Can start immediately in parallel with Dev A

Developer C:
  - User Story 4: Batch Operations (T049-T067)
  - ~19 tasks, estimated 1-2 weeks
  - Can start immediately in parallel with Dev A and B

Integration:
  - All developers: Phase 5 Polish (T068-T075)
  - ~8 tasks, estimated 3-5 days
```

**Timeline**: All user stories complete in 2-3 weeks (parallel development)

**Sequential Timeline**: All user stories complete in 5-6 weeks (one developer)

---

## Notes

- **[P] tasks**: Different files, no dependencies - can run in parallel
- **[Story] label**: Maps task to specific user story for traceability (US2, US3, US4)
- **TDD Mandatory**: All test tasks (T004-T013, T033-T037, T049-T053) MUST be written FIRST and FAIL before implementation
- **User Story 1**: Already 100% complete (session management, scan list UI, "Scan another room" button) - no tasks needed
- **Independent Testing**: Each user story can be tested independently:
  - US2: Stitching works without room names or batch operations
  - US3: Naming works without stitching or batch operations
  - US4: Batch operations work without stitching or room names
- **Backend Dependency**: User Story 2 requires backend team to implement `/api/stitch-rooms` endpoint (see contracts/room-stitching-api.graphql)
- **Commit Strategy**: Commit after each logical group (e.g., all models for US2, all tests for US3)
- **Stop at Checkpoints**: Validate each user story independently before moving to next priority
- **Avoid**: Vague tasks, same file conflicts (e.g., T054-T057 all touch scan_list_screen.dart - must be sequential), cross-story dependencies that break independence

---

## Task Summary

**Total Tasks**: 75 tasks
- Phase 1 (Setup): 3 tasks (T001-T003)
- Phase 2 (User Story 2 - Room Stitching): 29 tasks (T004-T032)
  - Tests: 10 tasks (T004-T013)
  - Implementation: 19 tasks (T014-T032)
- Phase 3 (User Story 3 - Scan Naming): 16 tasks (T033-T048)
  - Tests: 5 tasks (T033-T037)
  - Implementation: 11 tasks (T038-T048)
- Phase 4 (User Story 4 - Batch Operations): 19 tasks (T049-T067)
  - Tests: 5 tasks (T049-T053)
  - Implementation: 14 tasks (T054-T067)
- Phase 5 (Polish): 8 tasks (T068-T075)

**Parallel Opportunities**: 35 tasks marked [P] can run in parallel within their phase

**Independent User Stories**: All 3 user stories (US2, US3, US4) can be developed and tested independently after Phase 1 complete

**MVP Scope**: Phase 1 + Phase 2 (32 tasks) delivers core room stitching functionality

**Constitution Compliance**: ✅ TDD mandatory (20 test tasks before implementation), ✅ All 6 gates passed in plan.md
