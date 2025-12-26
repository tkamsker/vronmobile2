# Tasks: LiDAR Scanning

**Input**: Design documents from `/specs/014-lidar-scanning/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Test tasks are included following TDD/Test-First Development (constitution requirement)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app with feature-based architecture:
- **Feature code**: `lib/features/scanning/`
- **Core services**: `lib/core/services/`, `lib/core/constants/`
- **Tests**: `test/features/scanning/`, `test/integration/`
- **Platform config**: `ios/Runner/`, `android/app/`

---

## Phase 1: Setup (Dependencies & Platform Configuration)

**Purpose**: Install packages and configure iOS/Android for LiDAR scanning

**Estimated Time**: 15-20 minutes

- [X] T001 Add flutter_roomplan ^1.0.7 to pubspec.yaml dependencies
- [X] T002 Add file_picker ^10.3.8 to pubspec.yaml dependencies
- [X] T003 Add path_provider ^2.1.5 to pubspec.yaml dependencies
- [X] T004 Run flutter pub get to install new dependencies
- [X] T005 [P] Update ios/Runner/Info.plist with NSCameraUsageDescription key
- [X] T006 [P] Update ios/Podfile minimum platform to iOS 16.0
- [X] T007 [P] Run cd ios && pod install to update iOS dependencies
- [X] T008 [P] Add camera permissions to android/app/src/main/AndroidManifest.xml (for future Android support)

**Checkpoint**: Dependencies installed, platform configuration complete

---

## Phase 2: Foundational (Core Models & Services)

**Purpose**: Setup data models and foundational services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T009 [P] Create lib/features/scanning/models/ directory
- [X] T010 [P] Create lib/features/scanning/services/ directory
- [X] T011 [P] Create lib/features/scanning/screens/ directory
- [X] T012 [P] Create lib/features/scanning/widgets/ directory
- [X] T013 [P] Create lib/features/scanning/utils/ directory
- [X] T014 [P] Create test/features/scanning/models/ directory
- [X] T015 [P] Create test/features/scanning/services/ directory
- [X] T016 [P] Create test/features/scanning/widgets/ directory
- [X] T017 [P] Create test/integration/ directory (if doesn't exist)
- [X] T018 Add scanning error message strings to lib/core/constants/app_strings.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Start LiDAR Scan (Priority: P1) 🎯 MVP

**Goal**: Enable authenticated or guest users to scan rooms with LiDAR-capable devices, storing USDZ files locally

**Independent Test**: Tap "Start Scanning" button on iPhone 12 Pro+, verify camera/sensor permissions requested, complete scan, verify USDZ file stored in Documents directory

**Success Criteria**:
- Scan initiates within 2 seconds of button tap (SC-001)
- Scanning maintains 30fps minimum (SC-002)
- Scan data captured without data loss (SC-003)

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T019 [P] [US1] Write unit test for LidarCapability.detect() on supported device in test/features/scanning/models/lidar_capability_test.dart
- [X] T020 [P] [US1] Write unit test for LidarCapability.detect() on unsupported device (Android) in test/features/scanning/models/lidar_capability_test.dart
- [X] T021 [P] [US1] Write unit test for ScanData JSON serialization/deserialization in test/features/scanning/models/scan_data_test.dart
- [X] T022 [P] [US1] Write unit test for ScanData file existence check in test/features/scanning/models/scan_data_test.dart
- [X] T023 [P] [US1] Write unit test for ScanningService.checkCapability() in test/features/scanning/services/scanning_service_test.dart
- [X] T024 [P] [US1] Write unit test for ScanningService.startScan() success case in test/features/scanning/services/scanning_service_test.dart
- [X] T025 [P] [US1] Write unit test for ScanningService._saveScanLocally() in test/features/scanning/services/scanning_service_test.dart
- [X] T026 [P] [US1] Write widget test for ScanButton disabled when LiDAR unsupported in test/features/scanning/widgets/scan_button_test.dart
- [X] T027 [P] [US1] Write widget test for ScanButton enabled when LiDAR supported in test/features/scanning/widgets/scan_button_test.dart
- [X] T028 [P] [US1] Write widget test for ScanProgress indicator during active scan in test/features/scanning/widgets/scan_progress_test.dart
- [X] T029 [P] [US1] Write integration test for complete scan workflow (start → capture → store) in test/integration/scanning_flow_test.dart

**TDD Checkpoint**: ✅ All US1 tests written and FAILING - proceed to implementation

### Implementation for User Story 1

- [X] T030 [P] [US1] Create LidarCapability model in lib/features/scanning/models/lidar_capability.dart
- [X] T031 [P] [US1] Create ScanData model with JSON serialization in lib/features/scanning/models/scan_data.dart
- [X] T032 [US1] Implement ScanningService with flutter_roomplan integration in lib/features/scanning/services/scanning_service.dart
- [X] T033 [US1] Implement checkCapability() method using flutter_roomplan.isSupported() in lib/features/scanning/services/scanning_service.dart
- [X] T034 [US1] Implement startScan() method with progress callbacks in lib/features/scanning/services/scanning_service.dart
- [X] T035 [US1] Implement _saveScanLocally() method using path_provider in lib/features/scanning/services/scanning_service.dart
- [X] T036 [US1] Implement FileStorageService for USDZ file management in lib/features/scanning/services/file_storage_service.dart
- [X] T037 [US1] Create ScanButton widget with capability detection in lib/features/scanning/widgets/scan_button.dart
- [X] T038 [US1] Create ScanProgress widget with real-time updates in lib/features/scanning/widgets/scan_progress.dart
- [X] T039 [US1] Create ScanningScreen with scan lifecycle management in lib/features/scanning/screens/scanning_screen.dart
- [X] T040 [US1] Add navigation to ScanningScreen from project detail screen
- [X] T041 [US1] Implement interruption handlers (phone call, backgrounding) in lib/features/scanning/services/scanning_service.dart
- [X] T042 [US1] Verify all US1 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor if needed while keeping tests green

**Checkpoint**: User Story 1 (MVP) is fully functional - users can scan rooms with LiDAR and store USDZ locally

### Additional MVP Enhancements (Completed During Implementation)

- [X] T043a [US1] Create LidarRouterScreen to route between scan list and scanning based on auth state in lib/features/scanning/screens/lidar_router_screen.dart
- [X] T043b [US1] Create ScanListScreen matching Requirements/ScanList.jpg design in lib/features/scanning/screens/scan_list_screen.dart
- [X] T043c [US1] Implement ScanSessionManager singleton for in-memory scan storage in lib/features/scanning/services/scan_session_manager.dart
- [X] T043d [US1] Add "Scan another room" button to ScanListScreen with navigation to ScanningScreen
- [X] T043e [US1] Implement scan list display with scan details (time, file size, format)
- [X] T043f [US1] Add scan deletion functionality with undo capability in ScanListScreen
- [X] T043g [US1] Fix scan duplication bug (removed duplicate addScan call in scan_list_screen.dart)
- [X] T043h [US1] Remove interruption handling (RoomPlan handles this natively)
- [X] T043i [US1] Fix Navigator locked assertion error by removing lifecycle observer
- [X] T043j [US1] Fix UI overflow in scan list header (removed redundant date text)
- [X] T043k [US1] Add detailed logging for navigation flow debugging
- [X] T043l [US1] Add guest mode success dialog with account creation button linked to VRON_MERCHANTS_URL

**Implementation Notes**:
- Logged-in users see scan list first, then tap "Scan another room" to initiate scanning
- Guest users are taken directly to scanning screen with auto-launch
- Interruption handling removed as RoomPlan handles its own lifecycle management
- Scans stored in memory only (session-based, cleared on app restart)

---

## Phase 4: User Story 2 - Upload GLB File (Priority: P2)

**Goal**: Enable users (Android or iOS) to upload existing GLB files from device storage as alternative to LiDAR scanning

**Independent Test**: Tap "Upload GLB" button, select .glb file from device storage, verify file copied to app Documents directory and metadata saved

**Success Criteria**:
- File size validation (250 MB limit)
- File extension validation (.glb only)
- Files stored locally before upload to backend

### Tests for User Story 2 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T043 [P] [US2] Write unit test for FileUploadService.pickAndValidateGLB() success case in test/features/scanning/services/file_upload_service_test.dart
- [ ] T044 [P] [US2] Write unit test for FileUploadService GLB extension validation (reject .obj) in test/features/scanning/services/file_upload_service_test.dart
- [ ] T045 [P] [US2] Write unit test for FileUploadService file size validation (reject 300 MB file) in test/features/scanning/services/file_upload_service_test.dart
- [ ] T046 [P] [US2] Write widget test for FileUploadScreen file picker UI in test/features/scanning/screens/file_upload_screen_test.dart
- [ ] T047 [P] [US2] Write widget test for FileUploadScreen error message display in test/features/scanning/screens/file_upload_screen_test.dart
- [ ] T048 [P] [US2] Write integration test for GLB upload workflow in test/integration/file_upload_flow_test.dart

**TDD Checkpoint**: ✅ All US2 tests written and FAILING - proceed to implementation

### Implementation for User Story 2

- [ ] T049 [US2] Create FileUploadService with file_picker integration in lib/features/scanning/services/file_upload_service.dart
- [ ] T050 [US2] Implement pickAndValidateGLB() method with extension validation in lib/features/scanning/services/file_upload_service.dart
- [ ] T051 [US2] Implement file size validation (250 MB limit) in lib/features/scanning/services/file_upload_service.dart
- [ ] T052 [US2] Implement file copy to Documents directory using path_provider in lib/features/scanning/services/file_upload_service.dart
- [ ] T053 [US2] Create FileUploadScreen with file picker button in lib/features/scanning/screens/file_upload_screen.dart
- [ ] T054 [US2] Add error message display for invalid files in lib/features/scanning/screens/file_upload_screen.dart
- [ ] T055 [US2] Add success message and file details display in lib/features/scanning/screens/file_upload_screen.dart
- [ ] T056 [US2] Add navigation to FileUploadScreen from main menu
- [ ] T057 [US2] Verify all US2 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor file upload logic while keeping tests green

**Checkpoint**: User Story 2 complete - users can upload GLB files as alternative to LiDAR scanning

---

## Phase 5: User Story 3 - Save Scan to Project (Backend Upload & Conversion)

**Goal**: Enable authenticated users to upload USDZ scans to backend, triggering server-side USDZ→GLB conversion

**Independent Test**: Complete LiDAR scan, tap "Save to Project", select project, verify USDZ uploaded to backend, poll for conversion status, verify GLB URL returned

**Success Criteria**:
- File upload <30 seconds for 50 MB file on 10 Mbps connection
- Server-side conversion 5-30 seconds for typical room
- Conversion status polling with progress updates
- Both USDZ and GLB URLs returned

### Tests for User Story 3 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T058 [P] [US3] Write unit test for ConversionResult.success factory in test/features/scanning/models/conversion_result_test.dart
- [ ] T059 [P] [US3] Write unit test for ConversionResult.failure factory in test/features/scanning/models/conversion_result_test.dart
- [ ] T060 [P] [US3] Write unit test for ConversionResult error code mapping in test/features/scanning/models/conversion_result_test.dart
- [ ] T061 [P] [US3] Write unit test for ScanUploadService.uploadScan() success case in test/features/scanning/services/scan_upload_service_test.dart
- [ ] T062 [P] [US3] Write unit test for ScanUploadService.uploadScan() network error handling in test/features/scanning/services/scan_upload_service_test.dart
- [ ] T063 [P] [US3] Write unit test for ScanUploadService.pollConversionStatus() completion in test/features/scanning/services/scan_upload_service_test.dart
- [ ] T064 [P] [US3] Write unit test for ScanUploadService.pollConversionStatus() failure in test/features/scanning/services/scan_upload_service_test.dart
- [ ] T065 [P] [US3] Write widget test for SaveToProjectScreen upload progress indicator in test/features/scanning/screens/save_to_project_screen_test.dart
- [ ] T066 [P] [US3] Write widget test for SaveToProjectScreen conversion progress indicator in test/features/scanning/screens/save_to_project_screen_test.dart
- [ ] T067 [P] [US3] Write integration test for complete upload + conversion workflow in test/integration/scan_upload_flow_test.dart

**TDD Checkpoint**: ✅ All US3 tests written and FAILING - proceed to implementation

### Implementation for User Story 3

- [ ] T068 [P] [US3] Create ConversionResult model in lib/features/scanning/models/conversion_result.dart
- [ ] T069 [P] [US3] Create ConversionStats model in lib/features/scanning/models/conversion_result.dart
- [ ] T070 [US3] Extend GraphQLService with uploadProjectScan mutation in lib/core/services/graphql_service.dart
- [ ] T071 [US3] Create ScanUploadService with GraphQL file upload in lib/features/scanning/services/scan_upload_service.dart
- [ ] T072 [US3] Implement uploadScan() method with multipart file upload in lib/features/scanning/services/scan_upload_service.dart
- [ ] T073 [US3] Implement pollConversionStatus() method with 2-second interval in lib/features/scanning/services/scan_upload_service.dart
- [ ] T074 [US3] Implement _updateLocalScanData() to persist upload status in lib/features/scanning/services/scan_upload_service.dart
- [ ] T075 [US3] Create SaveToProjectScreen with project selection in lib/features/scanning/screens/save_to_project_screen.dart
- [ ] T076 [US3] Add upload progress indicator (CircularProgressIndicator) in lib/features/scanning/screens/save_to_project_screen.dart
- [ ] T077 [US3] Add conversion progress indicator with status text in lib/features/scanning/screens/save_to_project_screen.dart
- [ ] T078 [US3] Add error handling for network failures with retry button in lib/features/scanning/screens/save_to_project_screen.dart
- [ ] T079 [US3] Add error handling for conversion failures with user-friendly messages in lib/features/scanning/screens/save_to_project_screen.dart
- [ ] T080 [US3] Implement guest mode detection and account creation dialog in lib/features/scanning/screens/save_to_project_screen.dart
- [ ] T081 [US3] Add navigation from ScanningScreen to SaveToProjectScreen
- [ ] T082 [US3] Verify all US3 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor upload and polling logic while keeping tests green

**Checkpoint**: User Story 3 complete - users can upload scans to backend with server-side USDZ→GLB conversion

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final enhancements, accessibility, error handling, and production readiness

- [ ] T083 [P] Add Semantics labels to all interactive widgets (ScanButton, FileUploadButton, SaveButton) for screen reader support
- [ ] T084 [P] Verify touch target sizes are ≥44x44 logical pixels per accessibility requirements
- [ ] T085 [P] Add battery level warning (<15%) before starting scan in lib/features/scanning/services/scanning_service.dart
- [ ] T086 [P] Add storage space check before scan (warn if <500 MB free) in lib/features/scanning/services/scanning_service.dart
- [ ] T087 [P] Implement scan list view showing all local scans in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T088 [P] Add delete scan functionality with confirmation dialog in lib/features/scanning/screens/scan_list_screen.dart
- [ ] T089 [P] Add USDZ file preview using iOS ARQuickLook in lib/features/scanning/widgets/scan_preview.dart
- [ ] T090 [P] Add GLB file preview using WebView + Three.js in lib/features/scanning/widgets/scan_preview.dart
- [ ] T091 [P] Implement retry logic for failed uploads (exponential backoff) in lib/features/scanning/services/scan_upload_service.dart
- [ ] T092 [P] Add analytics tracking for scan events (started, completed, uploaded, failed)
- [ ] T093 [P] Add error reporting for conversion failures (send error codes to backend)
- [ ] T094 Update app_strings.dart with all scanning-related error messages
- [ ] T095 [P] Verify all scanning screens work in dark mode
- [ ] T096 [P] Verify all scanning screens work with increased font sizes (accessibility)
- [ ] T097 Test complete LiDAR scan workflow on iPhone 12 Pro (minimum device) - **Requires physical device**
- [ ] T098 Test complete LiDAR scan workflow on iPhone 15 Pro (latest device) - **Requires physical device**
- [ ] T099 Test GLB upload workflow on Android device - **Requires physical device**
- [ ] T100 Test scan interruption handling (simulate phone call) - **Requires physical device**
- [ ] T101 Test low battery warning during scan (<15%) - **Requires physical device**
- [ ] T102 Test network failure during upload (airplane mode) - **Requires physical device**
- [ ] T103 Test conversion timeout scenario (>30 seconds) - **Requires backend integration**
- [ ] T104 Code review and final refactoring (constitution compliance check)

**Final Checkpoint**: Feature code-complete and ready for production deployment

---

## Dependencies & Execution Strategy

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                        ↓
     ┌──────────────────┼──────────────────┐
     ↓                  ↓                  ↓
  Phase 3 (US1)    Phase 4 (US2)    Phase 5 (US3)
   [MVP - P1]        [P2]             [P2]
     ↓                  ↓                  ↓
     └──────────────────┼──────────────────┘
                        ↓
                  Phase 6 (Polish)
```

**Dependency Analysis**:
- **Phase 1 & 2**: MUST complete first (setup + foundation)
- **US1 (P1)**: Independent - can start after Phase 2
- **US2 (P2)**: Independent - can start after Phase 2 (parallel with US1)
- **US3 (P2)**: Depends on US1 or US2 (requires existing scan files)
- **Phase 6**: Depends on all user stories

### Parallel Execution Opportunities

**Within Phase 1 (Setup)**:
- T002, T003, T004 can run in parallel (different dependencies)
- T005, T006, T007, T008 can run in parallel (different platforms)

**Within Phase 2 (Foundational)**:
- T009-T017 can all run in parallel (creating directories)
- T018 can run in parallel with directory creation

**Within Phase 3 (US1)**:
- T019-T029 (tests) can all be written in parallel
- T030, T031 (models) can run in parallel
- After models complete: T032-T036 (services) mostly sequential
- T037, T038 (widgets) can run in parallel after services
- T039-T041 (screens) mostly sequential (depend on widgets + services)

**Within Phase 4 (US2)**:
- T043-T048 (tests) can all be written in parallel
- T049-T052 (service) mostly sequential
- T053-T055 (screen) sequential after service
- T056 can run in parallel with screen work

**Within Phase 5 (US3)**:
- T058-T067 (tests) can all be written in parallel
- T068, T069 (models) can run in parallel
- T070, T071 (services) sequential
- T072-T074 (service methods) sequential
- T075-T079 (screen) mostly sequential
- T080, T081 (integration) can run in parallel with screen

**Within Phase 6 (Polish)**:
- T083-T096 can all run in parallel (independent enhancements)
- T097-T103 must run sequentially (physical device/backend testing)

### MVP Delivery Strategy

**Minimum Viable Product (MVP) = Phase 1 + Phase 2 + Phase 3 (US1 only)**

This delivers:
- ✅ LiDAR scanning capability detection
- ✅ Room scanning with flutter_roomplan
- ✅ Local USDZ storage
- ✅ Scan progress indicators
- ✅ Interruption handling
- ✅ Permission management

**MVP Task Count**: T001-T042 (42 tasks)
**Estimated MVP Time**: 1-2 weeks (including TDD cycle)

**Incremental Delivery**:
1. **Sprint 1 (MVP)**: Phases 1-3 → US1 functional (LiDAR scanning + local storage)
2. **Sprint 2**: Phase 4 → US2 GLB upload capability
3. **Sprint 3**: Phase 5 → US3 backend upload + server-side conversion
4. **Sprint 4**: Phase 6 → Polish and production readiness

### Test-First Development (TDD) Workflow

**Constitution Requirement**: Tests MUST be written before implementation

**Red-Green-Refactor Cycle**:

1. **RED Phase**: Write failing tests
   - US1: Write T019-T029, verify they FAIL
   - US2: Write T043-T048, verify they FAIL
   - US3: Write T058-T067, verify they FAIL

2. **GREEN Phase**: Implement minimum code to pass tests
   - US1: Implement T030-T041, verify tests PASS
   - US2: Implement T049-T056, verify tests PASS
   - US3: Implement T068-T081, verify tests PASS

3. **REFACTOR Phase**: Improve code quality while keeping tests green
   - Extract helper methods
   - Simplify conditional logic
   - Improve naming and structure
   - Verify tests still PASS after each refactor

**Test Coverage Goals**:
- Unit tests: Models (ScanData, LidarCapability, ConversionResult), Services (ScanningService, FileUploadService, ScanUploadService)
- Widget tests: ScanButton, ScanProgress, FileUploadScreen, SaveToProjectScreen
- Integration tests: Complete scan workflow, GLB upload workflow, backend upload + conversion workflow

---

## Implementation Notes

### Platform-Specific Considerations

**iOS**:
- flutter_roomplan package is iOS-only (no Android support in flutter_roomplan v1.0.7)
- Minimum iOS 16.0 (RoomPlan framework requirement)
- LiDAR hardware required: iPhone 12 Pro+, iPad Pro 2020+
- Camera permission: NSCameraUsageDescription key in Info.plist mandatory
- Test on physical devices (LiDAR simulation not available in iOS Simulator)

**Android**:
- GLB upload only (no LiDAR scanning capability)
- File picker integration via file_picker package
- Camera permission in AndroidManifest.xml (placeholder for future Android LiDAR support)

### Backend Coordination

**GraphQL Mutation Required**: `uploadProjectScan(input: UploadProjectScanInput!)`
- Input: `projectId` (ID), `scanFile` (Upload), `format` (ScanFormat), `metadata` (JSON)
- Output: `scan` (Scan), `success` (Boolean), `message` (String)
- Backend validates token with user authentication
- Backend handles USDZ→GLB conversion via Sirv API or AWS Lambda
- Backend stores both USDZ and GLB in S3 (or equivalent cloud storage)

**Contract Location**: `specs/014-lidar-scanning/contracts/graphql-api.md`

### Security Checklist

- [ ] USDZ/GLB files never contain sensitive user data (only geometric data)
- [ ] Files stored in app sandbox (not accessible to other apps)
- [ ] Backend upload requires authentication (validated JWT token)
- [ ] File size validated before upload (250 MB limit)
- [ ] HTTPS enforced for all GraphQL API calls
- [ ] Error messages don't expose sensitive info (file paths, internal errors)

### Accessibility Checklist

- [ ] ScanButton has semantic label ("Start scanning room with LiDAR")
- [ ] Screen reader announces button state ("Scanning in progress", "Scan complete")
- [ ] Progress indicators accessible (semantic labels with percentage)
- [ ] Error messages accessible to screen readers
- [ ] Touch target size adequate (44x44 logical pixels minimum)
- [ ] Works with increased font sizes (textScaleFactor up to 2.0)
- [ ] Works in dark mode (contrast ratios meet WCAG AA standards)

---

## Task Summary

**Total Tasks**: 104
**MVP Tasks** (US1 only): 42 (T001-T042)
**Test Tasks**: 32 (T019-T029, T043-T048, T058-T067, constitution-required TDD)
**Implementation Tasks**: 72 (excluding tests)

**Task Distribution by Phase**:
- Phase 1 (Setup): 8 tasks
- Phase 2 (Foundational): 10 tasks
- Phase 3 (US1 - MVP): 24 tasks (11 tests + 13 implementation)
- Phase 4 (US2): 15 tasks (6 tests + 9 implementation)
- Phase 5 (US3): 25 tasks (10 tests + 15 implementation)
- Phase 6 (Polish): 22 tasks

**Parallel Opportunities**: 48 tasks marked [P] can run in parallel

**Independent Test Criteria**:
- ✅ US1: Complete LiDAR scan, verify USDZ stored in Documents directory, check SharedPreferences metadata
- ✅ US2: Upload GLB file via file picker, verify file copied to Documents directory, check file size and extension validation
- ✅ US3: Save scan to project, verify backend upload successful, poll conversion status, verify GLB URL returned

---

## Next Steps

1. **Start with MVP**: Execute T001-T042 to deliver functional LiDAR scanning with local storage
2. **Follow TDD**: Write failing tests BEFORE implementation (constitution requirement)
3. **Test on Physical Devices**: LiDAR scanning requires iPhone 12 Pro+ (not available in simulator)
4. **Coordinate with Backend**: Ensure `uploadProjectScan` GraphQL mutation is deployed before US3 implementation
5. **Incremental Delivery**: Ship US1 (MVP) → US2 (GLB upload) → US3 (backend integration) → Polish

**Recommended First Task**: T001 (add flutter_roomplan dependency to pubspec.yaml)

**Estimated Total Time**: 3-4 weeks (including TDD, device testing, backend integration, polish)
