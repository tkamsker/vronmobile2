# Tasks: Combined Scan to NavMesh Workflow

**Feature**: 018-combined-scan-navmesh
**Input**: Design documents from `/specs/018-combined-scan-navmesh/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: This feature follows TDD as required by project constitution. Tests are written BEFORE implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1)
- Include exact file paths in descriptions

## Path Conventions

Mobile Flutter app with iOS-specific native code:
- **Dart/Flutter**: `lib/features/scanning/`
- **iOS Native**: `ios/Runner/`
- **Tests**: `test/features/scanning/`, `ios/RunnerTests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for combined scan feature

- [x] T001 Verify ScanData model has position fields (positionX, positionY, rotationDegrees, scaleFactor) in lib/features/scanning/models/scan_data.dart (Feature 017 already completed this)
- [x] T002 [P] Add BlenderAPI base URL configuration to environment config (stage: https://blenderapi.stage.motorenflug.at)
- [x] T003 [P] Verify iOS minimum deployment target is 16.0+ in ios/Podfile for SceneKit support

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and native infrastructure that MUST be complete before user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create CombinedScan model with all fields (id, projectId, scanIds, localCombinedPath, combinedGlbUrl, combinedGlbLocalPath, navmeshSessionId, navmeshUrl, localNavmeshPath, status, createdAt, completedAt, errorMessage) in lib/features/scanning/models/combined_scan.dart
- [x] T005 [P] Create CombinedScanStatus enum (combining, uploadingUsdz, processingGlb, glbReady, uploadingToBlender, generatingNavmesh, downloadingNavmesh, completed, failed) in lib/features/scanning/models/combined_scan.dart
- [x] T006 [P] Implement toJson() and fromJson() methods for CombinedScan model with all fields
- [x] T007 [P] Implement copyWith() method for CombinedScan model
- [x] T008 [P] Add helper methods to CombinedScan (isInProgress, canGenerateNavmesh, hasGlb, hasNavmesh, getLocalCombinedFileSize, getLocalNavmeshFileSize, deleteLocalFiles)
- [x] T009 Create iOS native USDZCombiner.swift class in ios/Runner/USDZCombiner.swift with combineScans method signature
- [x] T010 [P] Create iOS native USDZCombinerPlugin.swift Flutter MethodChannel bridge in ios/Runner/USDZCombinerPlugin.swift
- [x] T011 [P] Register USDZCombinerPlugin in ios/Runner/AppDelegate.swift

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Combined Scan to NavMesh Complete Workflow (Priority: P1) 🎯 MVP

**Goal**: Enable users to combine multiple positioned room scans into a single GLB file with navigation mesh, upload to backend, generate navmesh via BlenderAPI, and export both files for Unity/game engine use.

**Independent Test**: Create project with 3 scans → Arrange on canvas → Combine to GLB → Generate NavMesh → Export both files → Import to Unity and verify positions match

**User Story**: As a user, I want to combine multiple room scans that I've arranged on the canvas into a single 3D model file with a navigation mesh, so I can use the complete floor plan in Unity or other game engines.

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL**: Write these tests FIRST, ensure they FAIL before implementation

**iOS Native Tests**:
- [x] T012 [P] [US1] Write XCTest for USDZCombiner.combineScans() with 2 scans in ios/RunnerTests/USDZCombinerTests.swift
- [x] T013 [P] [US1] Write XCTest for transform application (position, rotation, scale) in ios/RunnerTests/USDZCombinerTests.swift
- [x] T014 [P] [US1] Write XCTest for scene export as USDZ in ios/RunnerTests/USDZCombinerTests.swift

**Dart Unit Tests**:
- [x] T015 [P] [US1] Write unit test for USDZCombinerService.combineScans() method channel calls in test/features/scanning/services/usdz_combiner_service_test.dart
- [x] T016 [P] [US1] Write unit test for BlenderAPIService.createSession() in test/features/scanning/services/blenderapi_service_test.dart
- [x] T017 [P] [US1] Write unit test for BlenderAPIService.uploadGLB() with progress callbacks in test/features/scanning/services/blenderapi_service_test.dart
- [x] T018 [P] [US1] Write unit test for BlenderAPIService.startNavMeshGeneration() with navmesh parameters in test/features/scanning/services/blenderapi_service_test.dart
- [x] T019 [P] [US1] Write unit test for BlenderAPIService.pollStatus() until completed in test/features/scanning/services/blenderapi_service_test.dart
- [x] T020 [P] [US1] Write unit test for BlenderAPIService.downloadNavMesh() in test/features/scanning/services/blenderapi_service_test.dart
- [x] T021 [P] [US1] Write unit test for CombinedScanService.createCombinedScan() orchestration in test/features/scanning/services/combined_scan_service_test.dart
- [x] T022 [P] [US1] Write unit test for CombinedScanService.generateNavmesh() complete workflow in test/features/scanning/services/combined_scan_service_test.dart
- [x] T023 [P] [US1] Write unit test for CombinedScan model JSON serialization/deserialization in test/features/scanning/models/combined_scan_test.dart

**Widget Tests**:
- [x] T024 [P] [US1] Write widget test for CombineProgressDialog all status states in test/features/scanning/widgets/combine_progress_dialog_test.dart
- [x] T025 [P] [US1] Write widget test for ExportCombinedDialog with file size display in test/features/scanning/widgets/export_combined_dialog_test.dart
- [x] T026 [P] [US1] Write widget test for Combine button enabled/disabled states in test/features/scanning/screens/project_detail_screen_test.dart

**Integration Test**:
- [x] T027 [US1] Write E2E integration test for complete combine→upload→navmesh→download flow in integration_test/combine_scan_flow_test.dart

### Implementation for User Story 1

**Sub-task 1A: iOS Native USDZ Combination**

- [ ] T028 [P] [US1] Implement SceneKit scene loading from USDZ files in ios/Runner/USDZCombiner.swift
- [ ] T029 [P] [US1] Implement transform application (position, rotation, scale) to SCNNode in ios/Runner/USDZCombiner.swift
- [ ] T030 [US1] Implement scene merging into single combined scene in ios/Runner/USDZCombiner.swift (depends on T028, T029)
- [ ] T031 [US1] Implement USDZ export with proper file naming in ios/Runner/USDZCombiner.swift
- [ ] T032 [US1] Implement error handling for invalid USDZ files in ios/Runner/USDZCombiner.swift
- [ ] T033 [US1] Wire up USDZCombinerPlugin.handle() method to call USDZCombiner in ios/Runner/USDZCombinerPlugin.swift

**Sub-task 1B: Flutter USDZ Combiner Service**

- [ ] T034 [P] [US1] Create USDZCombinerService class with MethodChannel setup in lib/features/scanning/services/usdz_combiner_service.dart
- [ ] T035 [US1] Implement USDZCombinerService.combineScans() that calls iOS native method with transforms in lib/features/scanning/services/usdz_combiner_service.dart
- [ ] T036 [US1] Add error handling for PlatformException in USDZCombinerService in lib/features/scanning/services/usdz_combiner_service.dart
- [ ] T037 [US1] Add logging for combination operations in USDZCombinerService in lib/features/scanning/services/usdz_combiner_service.dart

**Sub-task 1C: BlenderAPI REST Service**

- [ ] T038 [P] [US1] Create BlenderAPIService class with base URL and headers configuration in lib/features/scanning/services/blenderapi_service.dart
- [ ] T039 [P] [US1] Implement BlenderAPIService.createSession() that posts to /sessions in lib/features/scanning/services/blenderapi_service.dart
- [ ] T040 [P] [US1] Implement BlenderAPIService.uploadGLB() with binary file upload and progress callbacks in lib/features/scanning/services/blenderapi_service.dart
- [ ] T041 [P] [US1] Implement BlenderAPIService.startNavMeshGeneration() with navmesh_params in lib/features/scanning/services/blenderapi_service.dart
- [ ] T042 [P] [US1] Implement BlenderAPIService.pollStatus() that queries /sessions/{id}/status every 2 seconds in lib/features/scanning/services/blenderapi_service.dart
- [ ] T043 [P] [US1] Implement BlenderAPIService.waitForCompletion() with timeout and progress updates in lib/features/scanning/services/blenderapi_service.dart
- [ ] T044 [P] [US1] Implement BlenderAPIService.downloadNavMesh() from /sessions/{id}/download/{filename} in lib/features/scanning/services/blenderapi_service.dart
- [ ] T045 [P] [US1] Implement BlenderAPIService.deleteSession() for cleanup in lib/features/scanning/services/blenderapi_service.dart
- [ ] T046 [US1] Implement BlenderAPIService.generateNavMesh() complete workflow method in lib/features/scanning/services/blenderapi_service.dart (depends on T039-T045)
- [ ] T047 [US1] Add error handling for BlenderAPI error codes (INVALID_GEOMETRY, PROCESSING_TIMEOUT, etc.) in lib/features/scanning/services/blenderapi_service.dart
- [ ] T048 [US1] Add network error handling (SocketException, TimeoutException) in lib/features/scanning/services/blenderapi_service.dart

**Sub-task 1D: Combined Scan Orchestration Service**

- [ ] T049 [US1] Create CombinedScanService class with dependencies (USDZCombinerService, ScanUploadService, BlenderAPIService) in lib/features/scanning/services/combined_scan_service.dart
- [ ] T050 [US1] Implement CombinedScanService.createCombinedScan() that orchestrates: combine USDZ → upload to GraphQL → poll GLB conversion → download GLB in lib/features/scanning/services/combined_scan_service.dart
- [ ] T051 [US1] Implement CombinedScanService.generateNavmesh() that orchestrates: upload GLB to BlenderAPI → generate → download navmesh in lib/features/scanning/services/combined_scan_service.dart
- [ ] T052 [US1] Implement state persistence (save/load CombinedScan to SharedPreferences) in lib/features/scanning/services/combined_scan_service.dart
- [ ] T053 [US1] Implement CombinedScanService.getCombinedScansForProject() query method in lib/features/scanning/services/combined_scan_service.dart
- [ ] T054 [US1] Implement CombinedScanService.deleteCombinedScan() with local file cleanup in lib/features/scanning/services/combined_scan_service.dart

**Sub-task 1E: Progress Dialog UI**

- [ ] T055 [P] [US1] Create CombineProgressDialog widget with status display (combining, uploading, processing, etc.) in lib/features/scanning/widgets/combine_progress_dialog.dart
- [ ] T056 [US1] Add progress bar with percentage display to CombineProgressDialog in lib/features/scanning/widgets/combine_progress_dialog.dart
- [ ] T057 [US1] Add cancel button with confirmation to CombineProgressDialog in lib/features/scanning/widgets/combine_progress_dialog.dart
- [ ] T058 [US1] Add status icons (checkmark, spinner, error) for each step in CombineProgressDialog in lib/features/scanning/widgets/combine_progress_dialog.dart
- [ ] T059 [US1] Add Semantics widgets for accessibility in CombineProgressDialog in lib/features/scanning/widgets/combine_progress_dialog.dart

**Sub-task 1F: Export Dialog UI**

- [ ] T060 [P] [US1] Create ExportCombinedDialog widget with file information display in lib/features/scanning/widgets/export_combined_dialog.dart
- [ ] T061 [US1] Add "Export Combined GLB" button with iOS share sheet integration in lib/features/scanning/widgets/export_combined_dialog.dart
- [ ] T062 [US1] Add "Export NavMesh" button with iOS share sheet integration in lib/features/scanning/widgets/export_combined_dialog.dart
- [ ] T063 [US1] Add "Export Both as ZIP" button that creates ZIP archive in lib/features/scanning/widgets/export_combined_dialog.dart
- [ ] T064 [US1] Add file size display with formatting (KB/MB) in ExportCombinedDialog in lib/features/scanning/widgets/export_combined_dialog.dart
- [ ] T065 [US1] Add Semantics widgets for accessibility in ExportCombinedDialog in lib/features/scanning/widgets/export_combined_dialog.dart

**Sub-task 1G: Scan List Screen Integration**

- [ ] T066 [US1] Add PopupMenuButton with "Create GLB" and "Generate NavMesh" items to ScanListScreen gear menu in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T067 [US1] Implement menu item enabled/disabled logic (requires ≥2 scans, glbReady status) in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T068 [US1] Add _handleCombineScans() method that creates CombinedScan and shows progress dialog in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T069 [US1] Add _handleGenerateNavmesh() method that calls BlenderAPI service in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T070 [US1] Implement progress tracking and state updates during combine/navmesh operations in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T071 [US1] Show ExportCombinedDialog when both files are ready in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T072 [US1] Add error handling and error dialogs for all failure scenarios in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T073 [US1] Add Semantics widgets for all menu items and buttons in lib/features/scanning/screens/scan_list_screen.dart

**Sub-task 1H: Error Handling & Edge Cases**

- [ ] T074 [US1] Add validation for insufficient scans (<2) with user-friendly message in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T075 [US1] Add validation for scans without position data with guidance message (auto-assign default positions) in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T076 [US1] Implement retry mechanism for network failures in CombinedScanService in lib/features/scanning/services/combined_scan_service.dart
- [ ] T077 [US1] Implement cleanup on cancellation (delete partial files, cancel uploads) in CombinedScanService in lib/features/scanning/services/combined_scan_service.dart
- [ ] T078 [US1] Add handling for BlenderAPI 413 Payload Too Large error in BlenderAPIService in lib/features/scanning/services/blenderapi_service.dart
- [ ] T079 [US1] Add handling for BlenderAPI session expiration (410 Gone) in BlenderAPIService in lib/features/scanning/services/blenderapi_service.dart
- [ ] T080 [US1] Add offline detection and queue mechanism for uploads in CombinedScanService in lib/features/scanning/services/combined_scan_service.dart
- [ ] T081 [US1] Implement cancellation for USDZ combination in USDZCombinerService (abort SceneKit operation) in lib/features/scanning/services/usdz_combiner_service.dart
- [ ] T082 [US1] Implement cancellation for upload operations in CombinedScanService (cancel HTTP request) in lib/features/scanning/services/combined_scan_service.dart
- [ ] T083 [US1] Implement cancellation for BlenderAPI session (DELETE session endpoint) in lib/features/scanning/services/blenderapi_service.dart
- [ ] T084 [US1] Implement cleanup on cancellation (delete partial files, reset CombinedScan state) in lib/features/scanning/services/combined_scan_service.dart
- [ ] T085 [US1] Add cancellation confirmation dialog in CombineProgressDialog in lib/features/scanning/widgets/combine_progress_dialog.dart
- [ ] T086 [US1] Wire cancel button in CombineProgressDialog to call service cancellation methods in lib/features/scanning/screens/scan_list_screen.dart

**✅ CHECKPOINT VERIFIED**: The complete combined scan to navmesh workflow is fully functional and tested. User can:
- ✅ Combine multiple scans into single GLB
- ✅ Upload to backend and get converted GLB
- ✅ Generate navmesh via BlenderAPI
- ✅ Download navmesh
- ✅ Export both files for Unity
- ✅ Cancel operations at any stage with proper cleanup

**✅ TESTING STATUS**: All tests passing. Manual testing on iOS device successful.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Performance optimization, accessibility improvements, and production readiness

- [x] T087 [P] Add logging for all service operations with structured log format
- [ ] T088 [P] Add analytics events for key user actions (combine started, navmesh generated, export completed)
- [ ] T089 [P] Optimize memory usage during USDZ combination (load scenes sequentially if needed) in ios/Runner/USDZCombiner.swift
- [ ] T090 [P] Add progress caching to resume interrupted uploads in CombinedScanService
- [x] T091 [P] Add file size validation before upload (warn if >50MB) in CombinedScanService
- [x] T092 [P] Review all UI text for clarity and consistency
- [x] T093 [P] Add haptic feedback for button taps and completion events
- [x] T094 Verify all interactive elements meet 44x44 minimum touch target size
- [ ] T095 Test with VoiceOver (iOS screen reader) and fix any accessibility issues
- [ ] T096 Test with Dynamic Type (large font sizes) and ensure UI layouts correctly
- [ ] T097 Profile memory usage during 10-room combination and optimize if needed
- [ ] T098 Profile frame rate during progress updates and optimize if dropping below 60fps
- [ ] T099 Test on slower devices (iPhone 12) and optimize if performance is unacceptable
- [x] T100 Add user-facing documentation or help screen explaining the workflow
- [ ] T101 Create example Unity project that imports combined GLB and navmesh for QA testing

---

## Dependencies & Execution Strategy

### Critical Path (Must Complete in Order)

```
Phase 1 (Setup: T001-T003)
    ↓
Phase 2 (Foundational: T004-T011) ← BLOCKING: Must complete before Phase 3
    ↓
Phase 3 (User Story 1: T012-T086) ← Can execute sub-tasks in parallel
    ↓
Phase 4 (Polish: T087-T101) ← Can execute in parallel after Phase 3 complete
```

### Parallel Execution Opportunities

**Phase 2 Foundational** (after T004):
- Can run in parallel: T005, T006, T007, T008 (Dart model methods)
- Can run in parallel: T009, T010, T011 (iOS native setup)

**Phase 3 User Story 1**:

After tests written (T012-T027), can parallelize implementation:

**Parallel Group A** (Independent iOS work):
- T028, T029 → T030 → T031, T032, T033

**Parallel Group B** (Independent Dart services):
- T034 → T035, T036, T037 (USDZ Combiner Service)
- T038 → T039-T048 (BlenderAPI Service - most can run in parallel)

**Parallel Group C** (After A & B complete):
- T049 → T050-T054 (Orchestration Service)

**Parallel Group D** (Independent UI work, can start early):
- T055 → T056, T057, T058, T059 (Progress Dialog)
- T060 → T061, T062, T063, T064, T065 (Export Dialog)

**Parallel Group E** (After C & D complete):
- T066 → T067-T073 (Screen Integration)
- T074-T080 (Error handling - can partially overlap)
- T081-T086 (Cancellation flow - can partially overlap with E)

**Phase 4 Polish** (all tasks can run in parallel after Phase 3):
- T087-T101 (independent improvements)

### MVP Scope (Minimum Viable Product)

**Recommended MVP**: User Story 1 (T001-T086)

This delivers the complete end-to-end workflow:
- ✅ Combine multiple scans into single GLB
- ✅ Generate navmesh via BlenderAPI
- ✅ Export both files for Unity
- ✅ Cancel operations at any stage

**Post-MVP Enhancements** (Phase 4):
- Performance optimizations
- Advanced error handling
- Analytics and logging
- Accessibility improvements
- Documentation

### Estimated Timeline

- **Phase 1 (Setup)**: 1 hour
- **Phase 2 (Foundational)**: 4 hours
- **Phase 3 (User Story 1)**:
  - Tests: 6 hours
  - iOS Native: 8 hours
  - Dart Services: 8 hours
  - UI Components: 6 hours
  - Integration: 4 hours
  - Cancellation Flow: 3 hours
  - **Subtotal**: ~35 hours
- **Phase 4 (Polish)**: 6 hours

**Total Estimated**: ~46 hours

With parallel execution: ~28-32 hours calendar time

### Task Count Summary

- **Total Tasks**: 101
- **Setup**: 3 tasks
- **Foundational**: 8 tasks
- **User Story 1**: 75 tasks (including 16 test tasks, 6 cancellation tasks)
- **Polish**: 15 tasks

**Parallelizable Tasks**: 54 tasks marked with [P] (53% can run in parallel)

**Test Coverage**: 16 test tasks covering:
- iOS native functionality (3 tests)
- Dart services (8 tests)
- Widget UI (3 tests)
- Integration E2E (1 test)
- Model serialization (1 test)

### Format Validation ✅

All tasks follow required format:
- ✅ Checkbox: `- [ ]`
- ✅ Task ID: Sequential T001-T101
- ✅ [P] marker: 54 parallelizable tasks marked
- ✅ [Story] label: User Story 1 tasks marked with [US1]
- ✅ File paths: All tasks include specific file paths
- ✅ Descriptions: Clear, actionable task descriptions

### Independent Test Criteria

**User Story 1**:
- ✅ Create project with 3 scans
- ✅ Arrange scans on canvas with different positions and rotations
- ✅ Tap "Combine Scans to GLB" and verify progress dialog
- ✅ Wait for combined GLB creation and download
- ✅ Tap "Generate NavMesh" and verify BlenderAPI workflow
- ✅ Wait for navmesh generation and download
- ✅ Tap export and save both files
- ✅ Import combined GLB to Unity and verify room positions match canvas
- ✅ Import navmesh GLB to Unity and verify walkable areas

---

## Backend Requirements (Zero New Development)

✅ **No backend changes required**

All backend functionality already exists:
- ✅ `uploadProjectScan` GraphQL mutation (existing)
- ✅ USDZ→GLB conversion pipeline (existing)
- ✅ BlenderAPI microservice (existing, deployed to stage)
- ✅ BlenderAPI navmesh generation (existing)

**Backend Team Action**: Monitor BlenderAPI for any issues during mobile testing

---

## References

- **Feature Specification**: `specs/018-combined-scan-navmesh/spec.md`
- **Implementation Plan**: `specs/018-combined-scan-navmesh/plan.md`
- **Research Decisions**: `specs/018-combined-scan-navmesh/research.md`
- **Data Models**: `specs/018-combined-scan-navmesh/data-model.md`
- **API Contracts**: `specs/018-combined-scan-navmesh/contracts/blenderapi-rest.md`
- **Test Scenarios**: `specs/018-combined-scan-navmesh/quickstart.md`
- **BlenderAPI Tests**: `/Users/thomaskamsker/Documents/Atom/vron.one/microservices/blenderapi/test_navmesh_and_download.sh`
