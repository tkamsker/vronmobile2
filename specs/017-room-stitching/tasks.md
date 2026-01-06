# Tasks: Room Stitching - Canvas Enhancement

**Input**: Design documents from `/specs/017-room-stitching/`
**Prerequisites**: plan.md, spec.md
**Status**: 🚧 Canvas Enhancement In Progress

**Original Implementation**: ✅ US1-US4 completed and merged (2026-01-02)
**Canvas Enhancement**: 🚧 US5-US8 implementation in progress

**Tests**: TDD approach - test tasks included for all new features

**Organization**: Tasks organized by user story for independent implementation and parallel development.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US5, US6, US7, US8)
- Include exact file paths in descriptions

## Path Conventions

Mobile app using feature-based architecture:
- **Models**: `lib/features/scanning/models/`
- **Services**: `lib/features/scanning/services/`
- **Screens**: `lib/features/scanning/screens/`
- **Widgets**: `lib/features/scanning/widgets/`
- **Tests**: `test/features/scanning/` (mirrors source structure)
- **Integration Tests**: `integration_test/`
- **Config**: `.env` (project root)

---

## Phase 1: Setup (Dependencies & Configuration)

**Purpose**: Add new dependencies and configuration for canvas rendering

**Status**: ⏳ Pending

- [ ] T001 Add flutter_dotenv ^5.1.0 to pubspec.yaml for .env configuration reading
- [ ] T002 Add vector_math ^2.1.4 to pubspec.yaml for 2D/3D transformations and polygon operations
- [ ] T003 [P] Add path_parsing ^1.0.1 to pubspec.yaml for SVG-style path operations
- [ ] T004 [P] Verify json_annotation and json_serializable already exist (from original implementation)
- [ ] T005 Run flutter pub get to fetch all new dependencies
- [ ] T006 Create .env file in project root with ROOM_ROTATION_DEGREES=45, DOOR_CONNECTION_THRESHOLD=50, CANVAS_GRID_SIZE=20
- [ ] T007 Load .env configuration in main.dart using flutter_dotenv before app initialization

**Checkpoint**: Dependencies installed, .env configuration ready

---

## Phase 2: Foundational (Canvas Infrastructure)

**Purpose**: Core infrastructure that MUST be complete before ANY canvas user story can be implemented

**⚠️ CRITICAL**: No canvas work can begin until this phase is complete

**Status**: ⏳ Pending

- [ ] T008 Create CanvasConfiguration model in lib/features/scanning/models/canvas_configuration.dart with fields: canvasWidth, canvasHeight, zoomLevel, panOffset, rotationIncrement (from .env), doorConnectionThreshold (from .env), gridSize (from .env) - ~60 lines
- [ ] T009 Add @JsonSerializable annotation to CanvasConfiguration and run build_runner for code generation
- [ ] T010 Implement CanvasConfiguration.fromEnv() factory constructor to load values from .env with fallback defaults
- [ ] T011 Create CanvasInteractionMode enum in lib/features/scanning/models/canvas_interaction_mode.dart with values: idle, selecting, moving, rotating, placingDoor
- [ ] T012 Verify existing ScanSessionManager and ScanData models exist (from Feature 016)

**Checkpoint**: Foundation ready - canvas development can now begin

---

## Phase 3: User Story 5 - Visual Room Layout Canvas (Priority: P1) 🎯 MVP

**Goal**: Render 2D canvas with room outlines extracted from 3D scans, display room names, estimate and show door locations

**Independent Test**: Select 3 scans (Living Room, Kitchen, Bathroom), tap "Start Stitching", verify canvas opens showing 3 room outlines with different colors, verify each room displays name label, verify estimated door positions shown as symbols

**Status**: ⏳ Pending

### Tests for User Story 5

> **NOTE: These tests should be written FIRST, ensured they FAIL before implementation (TDD)**

- [ ] T013 [P] [US5] Create room_outline_test.dart in test/features/scanning/models/ - test polygon operations, point-in-polygon, bounding box, rotation transforms - ~200 lines
- [ ] T014 [P] [US5] Create room_layout_test.dart in test/features/scanning/models/ - test layout state management, position/rotation updates, door symbol storage - ~180 lines
- [ ] T015 [P] [US5] Create door_symbol_test.dart in test/features/scanning/models/ - test door placement on borders, connection status, serialization - ~150 lines
- [ ] T016 [P] [US5] Create canvas_configuration_test.dart in test/features/scanning/models/ - test .env loading, default values, validation - ~100 lines
- [ ] T017 [P] [US5] Create room_outline_extractor_test.dart in test/features/scanning/services/ - test 3D→2D extraction with mock USDZ/GLB files, polygon simplification - ~300 lines
- [ ] T018 [P] [US5] Create door_detection_service_test.dart in test/features/scanning/services/ - test door estimation from geometry, gap detection, false positive filtering - ~250 lines
- [ ] T019 [P] [US5] Create room_layout_canvas_test.dart in test/features/scanning/widgets/ - test CustomPainter rendering, layer drawing order, color assignment - ~350 lines
- [ ] T020 [P] [US5] Create room_layout_canvas_screen_test.dart in test/features/scanning/screens/ - test screen initialization, loading states, canvas display - ~300 lines

### Implementation for User Story 5

- [ ] T021 [P] [US5] Create RoomOutline model in lib/features/scanning/models/room_outline.dart with fields: scanId, points (List<Offset>), centerPoint, boundingBox, estimatedDimensions - ~120 lines
- [ ] T022 [P] [US5] Add @JsonSerializable and polygon utility methods to RoomOutline (pointInPolygon, rotate, translate, getBounds) - add ~60 lines
- [ ] T023 [P] [US5] Run build_runner to generate room_outline.g.dart
- [ ] T024 [P] [US5] Create DoorSymbol model in lib/features/scanning/models/door_symbol.dart with fields: id, parentRoomId, edgeIndex, offsetOnEdge, symbolType (estimated/manual), connectionStatus, connectedDoorId - ~100 lines
- [ ] T025 [P] [US5] Add @JsonSerializable to DoorSymbol and run build_runner for door_symbol.g.dart
- [ ] T026 [P] [US5] Create RoomLayout model in lib/features/scanning/models/room_layout.dart with fields: roomOutline, position (Offset), rotationAngle, visualStyle (color, borderWidth), isSelected, doors (List<DoorSymbol>) - ~150 lines
- [ ] T027 [P] [US5] Add @JsonSerializable to RoomLayout and run build_runner for room_layout.g.dart
- [ ] T028 [US5] Create RoomOutlineExtractor service in lib/features/scanning/services/room_outline_extractor.dart - implement extractOutline() method using horizontal slice algorithm (1m above floor) - ~250 lines
- [ ] T029 [US5] Implement 3D mesh parsing (USDZ/GLB) in RoomOutlineExtractor using vector_math for vertex processing
- [ ] T030 [US5] Implement polygon simplification in RoomOutlineExtractor to reduce points to 4-12 vertices using Douglas-Peucker algorithm
- [ ] T031 [US5] Create DoorDetectionService in lib/features/scanning/services/door_detection_service.dart - implement estimateDoors() method to find wall gaps - ~200 lines
- [ ] T032 [US5] Implement wall surface detection in DoorDetectionService to identify vertical surfaces in mesh
- [ ] T033 [US5] Implement gap detection logic in DoorDetectionService - find discontinuities > 0.7m wide and > 1.8m tall
- [ ] T034 [US5] Implement false positive filtering in DoorDetectionService - remove corners, limit to 4 doors/room, minimum 0.8m spacing
- [ ] T035 [US5] Create RoomLayoutCanvas widget (CustomPainter) in lib/features/scanning/widgets/room_layout_canvas.dart - implement paint() method with 7 rendering layers - ~350 lines
- [ ] T036 [US5] Implement background layer rendering in RoomLayoutCanvas - canvas background color, optional grid
- [ ] T037 [US5] Implement room outline layer rendering in RoomLayoutCanvas - draw polygons with dashed borders, color cycling (blue, green, purple, orange)
- [ ] T038 [US5] Implement door symbol layer rendering in RoomLayoutCanvas - draw orange door icons at border positions
- [ ] T039 [US5] Implement label layer rendering in RoomLayoutCanvas - render room names as centered text overlays
- [ ] T040 [US5] Create RoomLayoutCanvasScreen in lib/features/scanning/screens/room_layout_canvas_screen.dart - main screen UI with canvas and toolbar - ~400 lines
- [ ] T041 [US5] Implement screen initialization in RoomLayoutCanvasScreen - load selected scans, call RoomOutlineExtractor for each scan
- [ ] T042 [US5] Implement loading state UI in RoomLayoutCanvasScreen - show progress while extracting outlines and detecting doors
- [ ] T043 [US5] Call DoorDetectionService.estimateDoors() for each extracted outline in RoomLayoutCanvasScreen
- [ ] T044 [US5] Initialize RoomLayout objects with extracted outlines, default positions, and detected doors
- [ ] T045 [US5] Integrate RoomLayoutCanvas widget into RoomLayoutCanvasScreen with GestureDetector wrapper
- [ ] T046 [US5] Update scan_list_screen.dart _roomStitching() method to navigate to RoomLayoutCanvasScreen instead of old RoomStitchingScreen

**Checkpoint**: User Story 5 complete - canvas renders room outlines with doors and labels

---

## Phase 4: User Story 6 - Interactive Room Selection on Canvas (Priority: P1)

**Goal**: Enable tap-to-select/deselect rooms on canvas with visual feedback (solid border for selected, dashed for unselected)

**Independent Test**: Open canvas with 3 rooms, tap Kitchen outline to select (border becomes solid), tap Move button and verify it's enabled, tap Kitchen again to deselect (border becomes dashed), verify Move button disabled

**Status**: ⏳ Pending

### Tests for User Story 6

> **NOTE: These tests should be written FIRST, ensured they FAIL before implementation (TDD)**

- [ ] T047 [P] [US6] Add selection tests to room_layout_canvas_screen_test.dart - test tap detection, selection state changes, visual feedback - ~150 lines added
- [ ] T048 [P] [US6] Add hit testing tests to room_layout_canvas_test.dart - test coordinate transformation, point-in-polygon for selection - ~100 lines added
- [ ] T049 [P] [US6] Create canvas_toolbar_test.dart in test/features/scanning/widgets/ - test button enable/disable states based on selection - ~150 lines

### Implementation for User Story 6

- [ ] T050 [US6] Implement hit testing logic in RoomLayoutCanvasScreen - convert tap coordinates to canvas space, check point-in-polygon for each room
- [ ] T051 [US6] Add _selectedRoomId field to RoomLayoutCanvasScreen state and _handleTapDown(TapDownDetails details) method
- [ ] T052 [US6] Implement selection toggle logic in _handleTapDown - if room already selected, deselect; if different room tapped, switch selection
- [ ] T053 [US6] Update RoomLayout.isSelected field when selection changes and call setState() to trigger repaint
- [ ] T054 [US6] Implement selection layer rendering in RoomLayoutCanvas - draw glow effect and solid border for selected room
- [ ] T055 [US6] Create CanvasToolbar widget in lib/features/scanning/widgets/canvas_toolbar.dart with Select, Move, Rotate, Add Door buttons - ~120 lines
- [ ] T056 [US6] Implement button enable/disable logic in CanvasToolbar - Move, Rotate, Add Door enabled only when room selected
- [ ] T057 [US6] Add CanvasToolbar to RoomLayoutCanvasScreen bottom area, connected to selection state
- [ ] T058 [US6] Add Semantics labels to all toolbar buttons for accessibility (VoiceOver/TalkBack support)

**Checkpoint**: User Story 6 complete - users can select/deselect rooms with visual feedback

---

## Phase 5: User Story 7 - Room Manipulation (Move and Rotate) (Priority: P1)

**Goal**: Enable drag-to-move and tap-to-rotate (45° increments) for selected rooms with real-time canvas updates

**Independent Test**: Select Kitchen room, tap Move button, drag Kitchen 100px right, release to confirm, tap Rotate button 2 times, verify Kitchen rotates 90° (2×45°), verify door symbols move with room

**Status**: ⏳ Pending

### Tests for User Story 7

> **NOTE: These tests should be written FIRST, ensured they FAIL before implementation (TDD)**

- [ ] T059 [P] [US7] Add move/rotate tests to room_layout_canvas_screen_test.dart - test drag gestures, rotation calculations, boundary constraints - ~200 lines added
- [ ] T060 [P] [US7] Add transform tests to room_layout_test.dart - test position updates, rotation angle calculations, door symbol transforms - ~100 lines added
- [ ] T061 [P] [US7] Create canvas_interaction_handler_test.dart in test/features/scanning/services/ - test state machine transitions, gesture handling - ~220 lines

### Implementation for User Story 7

- [ ] T062 [P] [US7] Create CanvasInteractionHandler service in lib/features/scanning/services/canvas_interaction_handler.dart with state machine (idle, selecting, moving, rotating, placingDoor) - ~180 lines
- [ ] T063 [US7] Implement state transition methods in CanvasInteractionHandler - enterMoveMode(), exitMoveMode(), enterRotateMode(), etc.
- [ ] T064 [US7] Add _interactionMode field to RoomLayoutCanvasScreen and integrate CanvasInteractionHandler
- [ ] T065 [US7] Implement Move button handler in RoomLayoutCanvasScreen - call CanvasInteractionHandler.enterMoveMode()
- [ ] T066 [US7] Implement onPanStart, onPanUpdate, onPanEnd gestures in RoomLayoutCanvasScreen for drag movement
- [ ] T067 [US7] Update selected room's position (Offset) during drag, applying canvas bounds constraints
- [ ] T068 [US7] Implement Rotate button handler in RoomLayoutCanvasScreen - read rotation increment from CanvasConfiguration
- [ ] T069 [US7] Increment selected room's rotationAngle by configured degrees (default 45°), normalize to 0-360°
- [ ] T070 [US7] Transform door symbols when room rotates - update door positions relative to rotated room outline
- [ ] T071 [US7] Add rotation animation using AnimationController for smooth 45° transitions (~200ms duration)
- [ ] T072 [US7] Implement canvas bounds checking - prevent room from moving outside visible canvas area
- [ ] T073 [US7] Add visual indicator during move mode - highlight selected room border with thicker line

**Checkpoint**: User Story 7 complete - users can move and rotate rooms with constraints

---

## Phase 6: User Story 8 - Door Management and Room Connections (Priority: P2)

**Goal**: Enable manual door placement on room borders, suggest connections between nearby doors, allow users to confirm connections

**Independent Test**: Select Living Room, tap Add Door, tap on right border to place door (red symbol), select Kitchen, tap left border to place second door, verify yellow dashed connection suggested, tap connection to confirm (turns green), tap Done to save

**Status**: ⏳ Pending

### Tests for User Story 8

> **NOTE: These tests should be written FIRST, ensured they FAIL before implementation (TDD)**

- [ ] T074 [P] [US8] Create door_connection_test.dart in test/features/scanning/models/ - test connection validation, distance calculations, serialization - ~120 lines
- [ ] T075 [P] [US8] Add door placement tests to room_layout_canvas_screen_test.dart - test border tap detection, door creation, connection suggestions - ~200 lines added
- [ ] T076 [P] [US8] Add connection rendering tests to room_layout_canvas_test.dart - test dashed/solid line drawing, connection colors - ~100 lines added
- [ ] T077 [P] [US8] Create door_action_menu_test.dart in test/features/scanning/widgets/ - test menu display, delete/adjust actions - ~100 lines

### Implementation for User Story 8

- [ ] T078 [P] [US8] Create DoorConnection model in lib/features/scanning/models/door_connection.dart with fields: connectionId, doorAId, doorBId, connectionType (automatic/manual), visualStyle (dashed/solid), distance - ~80 lines
- [ ] T079 [P] [US8] Add @JsonSerializable to DoorConnection and run build_runner for door_connection.g.dart
- [ ] T080 [US8] Implement Add Door button handler in RoomLayoutCanvasScreen - call CanvasInteractionHandler.enterPlacingDoorMode()
- [ ] T081 [US8] Implement door placement tap detection in RoomLayoutCanvasScreen - find nearest room border edge to tap location
- [ ] T082 [US8] Create new DoorSymbol at tap location on border, add to selected room's doors list, mark as manual type
- [ ] T083 [US8] Implement door connection suggestion logic - find all door pairs within DOOR_CONNECTION_THRESHOLD pixels
- [ ] T084 [US8] Create DoorConnection objects for suggested pairs with dashed yellow visual style
- [ ] T085 [US8] Implement connection layer rendering in RoomLayoutCanvas - draw lines between connected doors (dashed yellow = suggested, solid green = confirmed)
- [ ] T086 [US8] Implement connection confirmation tap detection - check if tap is near connection line (within 20px)
- [ ] T087 [US8] Update DoorConnection visualStyle to solid green when confirmed, update connectionType to manual
- [ ] T088 [US8] Create DoorActionMenu widget in lib/features/scanning/widgets/door_action_menu.dart with Delete/Adjust options - ~80 lines
- [ ] T089 [US8] Implement door symbol tap detection - show DoorActionMenu when user taps existing door
- [ ] T090 [US8] Implement door deletion - remove DoorSymbol from room's doors list, remove associated connections
- [ ] T091 [US8] Add corner snap prevention - ensure doors placed at least 10% of border length from corners
- [ ] T092 [US8] Create RoomInfoLabel widget in lib/features/scanning/widgets/room_info_label.dart to show room name overlay - ~60 lines
- [ ] T093 [US8] Integrate RoomInfoLabel rendering in label layer of RoomLayoutCanvas

**Checkpoint**: User Story 8 complete - manual door placement and connection management functional

---

## Phase 7: Data Persistence & Backend Integration

**Purpose**: Serialize room layout configuration and integrate with stitching workflow

**Status**: ⏳ Pending

- [ ] T094 Implement Done button handler in RoomLayoutCanvasScreen - serialize all RoomLayout objects to JSON
- [ ] T095 Create RoomLayoutConfiguration wrapper model with list of RoomLayouts, list of DoorConnections, CanvasConfiguration
- [ ] T096 Add layoutConfiguration field to RoomStitchRequest model in lib/features/scanning/models/room_stitch_request.dart
- [ ] T097 Update RoomStitchRequest.toJson() to include layoutConfiguration serialization
- [ ] T098 Store layout configuration in scan metadata before starting stitching job
- [ ] T099 Update RoomStitchingService.startStitching() to include layout metadata in backend request
- [ ] T100 Pass layout configuration to RoomStitchProgressScreen when navigating from canvas
- [ ] T101 Update backend GraphQL mutation to accept layoutConfiguration input (if backend team ready)
- [ ] T102 Add layout configuration persistence in ScanData.metadata['layoutConfig'] for retrieval

**Checkpoint**: Layout data persists and passes to backend stitching service

---

## Phase 8: Integration & End-to-End Testing

**Purpose**: Verify complete canvas workflow from scan selection through stitching

**Status**: ⏳ Pending

- [ ] T103 [P] Update room_stitching_flow_test.dart in integration_test/ to use new canvas workflow - ~200 lines added
- [ ] T104 [P] Create canvas_layout_flow_test.dart in integration_test/ - test full canvas manipulation workflow - ~400 lines
- [ ] T105 Test scenario: Guest user blocked from canvas (shows auth dialog)
- [ ] T106 Test scenario: Single scan selected - canvas button disabled
- [ ] T107 Test scenario: 2 scans selected - canvas opens with both room outlines
- [ ] T108 Test scenario: Select room, move, rotate, verify transforms persist
- [ ] T109 Test scenario: Place doors manually, connect them, verify connections save
- [ ] T110 Test scenario: Tap Done, verify layout config serialized and passed to stitching service
- [ ] T111 Test scenario: Canvas with 5 rooms renders in < 1 second (performance requirement)
- [ ] T112 Test scenario: Drag room maintains 60fps animation (no lag/jitter)

**Checkpoint**: All integration tests pass, canvas workflow verified end-to-end

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final touches, accessibility, performance optimization, documentation

**Status**: ⏳ Pending

- [ ] T113 [P] Add comprehensive code comments to RoomOutlineExtractor explaining algorithm choices
- [ ] T114 [P] Add code comments to DoorDetectionService explaining gap detection logic
- [ ] T115 [P] Add Semantics widgets to all canvas interactive elements for screen reader support
- [ ] T116 [P] Add semantic announcements for room selection state changes ("Kitchen selected", "Kitchen deselected")
- [ ] T117 [P] Add semantic announcements for door placement ("Door added to Living Room")
- [ ] T118 [P] Verify all interactive canvas elements have minimum 44x44 touch targets
- [ ] T119 [P] Test canvas with TalkBack (Android) and VoiceOver (iOS) for accessibility
- [ ] T120 Run flutter analyze - verify no warnings or errors in new canvas code
- [ ] T121 Run flutter test - verify 100% test coverage for all new canvas components
- [ ] T122 Performance profiling - verify canvas rendering maintains 60fps during interactions
- [ ] T123 Memory profiling - verify no memory leaks during extended canvas use (10+ minutes)
- [ ] T124 Profile room outline extraction performance - verify < 500ms per scan on target devices
- [ ] T125 Profile door detection performance - verify < 1 second per room
- [ ] T126 Test with large rooms (100MB+ scan files) - verify canvas remains responsive
- [ ] T127 Test canvas behavior with 10 rooms - verify performance degradation is acceptable
- [ ] T128 Add error handling for outline extraction failures - fallback to bounding box method
- [ ] T129 Add error handling for door detection failures - render room without doors
- [ ] T130 Add user-friendly error messages for all canvas failure scenarios
- [ ] T131 Update CLAUDE.md with canvas rendering patterns and CustomPainter usage
- [ ] T132 Create inline code documentation for complex algorithms (polygon simplification, hit testing)
- [ ] T133 Update feature documentation in specs/017-room-stitching/ with canvas implementation details
- [ ] T134 Code review - ensure all canvas code follows Flutter best practices
- [ ] T135 Final integration testing on physical iOS device with real LiDAR scans

**Checkpoint**: Feature complete, polished, accessible, performant, and documented

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: ⏳ No dependencies - Start here
- **Foundational (Phase 2)**: ⏳ Depends on Phase 1 (Setup)
- **User Story 5 (Phase 3)**: ⏳ Depends on Phase 2 (Foundational) - Canvas rendering infrastructure
- **User Story 6 (Phase 4)**: ⏳ Depends on US5 - Needs canvas and room outlines to exist
- **User Story 7 (Phase 5)**: ⏳ Depends on US6 - Needs selection to exist before movement
- **User Story 8 (Phase 6)**: ⏳ Depends on US5, US6 - Needs rooms rendered and selectable
- **Data Persistence (Phase 7)**: ⏳ Depends on US5-US8 - Needs all layout features complete
- **Integration Testing (Phase 8)**: ⏳ Depends on Phase 7 - Needs complete workflow
- **Polish (Phase 9)**: ⏳ Depends on Phase 8 - Final cleanup after all features working

### User Story Dependencies

All new user stories (US5-US8) are designed to be implemented sequentially:

- **User Story 5 (P1)**: ⏳ Canvas rendering - Foundation for all canvas features, NO dependencies
- **User Story 6 (P1)**: ⏳ Selection - Depends on US5 (needs canvas to select from)
- **User Story 7 (P1)**: ⏳ Move/Rotate - Depends on US6 (needs selection before manipulation)
- **User Story 8 (P2)**: ⏳ Door management - Depends on US5, US6 (needs canvas and selection)

### Within Each User Story (TDD Pattern)

1. ⏳ Tests written FIRST and confirmed to FAIL
2. ⏳ Models implemented with JSON serialization
3. ⏳ Services implemented with core algorithms
4. ⏳ Widgets implemented (CustomPainter, toolbar, etc.)
5. ⏳ Screen integration and gesture handling
6. ⏳ Tests turn GREEN, story checkpoint reached

### Parallel Opportunities

**Phase 1-2 (Setup/Foundation)**: 1 day
- Tasks T001-T005 can run in parallel (different dependencies)
- Single developer for configuration setup (T006-T007)

**Phase 3 (US5 - Canvas Rendering)**: 3-4 days with parallel development
- **Track A**: Models (T021-T027) - all parallelizable
- **Track B**: RoomOutlineExtractor service (T028-T030)
- **Track C**: DoorDetectionService (T031-T034)
- **Track D**: RoomLayoutCanvas widget (T035-T039)
- **Track E**: Tests (T013-T020) - all parallelizable
- After all tracks complete: Screen integration (T040-T046) sequential

**Phase 4 (US6 - Selection)**: 1 day
- Tests (T047-T049) parallelizable
- Implementation (T050-T058) mostly sequential (state management)

**Phase 5 (US7 - Movement)**: 1-2 days
- Tests (T059-T061) parallelizable
- Implementation (T062-T073) sequential (gesture handling complexity)

**Phase 6 (US8 - Doors)**: 1-2 days
- Tests (T074-T077) parallelizable
- Implementation (T078-T093) mostly sequential (connection logic)

**Phase 7-9**: 1-2 days
- Many polish tasks parallelizable (documentation, comments, accessibility)

**Total Development Time**: 8-12 days with TDD approach and parallel execution

---

## Parallel Example: User Story 5 (Canvas Rendering)

```bash
# After Phase 2 (Foundational) completes, all US5 test and model tasks can run in parallel:

# Developer A: Test Infrastructure
flutter test test/features/scanning/models/room_outline_test.dart  # T013
flutter test test/features/scanning/models/room_layout_test.dart  # T014
flutter test test/features/scanning/models/door_symbol_test.dart  # T015
flutter test test/features/scanning/models/canvas_configuration_test.dart  # T016

# Developer B: Models
# Implements T021-T027 (RoomOutline, DoorSymbol, RoomLayout + code generation)

# Developer C: Outline Extraction Service
# Implements T028-T030 (RoomOutlineExtractor with 3D parsing and simplification)

# Developer D: Door Detection Service
# Implements T031-T034 (DoorDetectionService with gap detection)

# Developer E: Canvas Widget
# Implements T035-T039 (RoomLayoutCanvas CustomPainter with rendering layers)

# After all complete, Developer F integrates in screen (T040-T046)
```

---

## Parallel Example: Multiple User Stories

```bash
# After Phase 2 (Foundational) completes, some work can overlap:

# Sprint 1 (Days 1-4): User Story 5 (Canvas Rendering)
# All 5 developers focus on US5 as shown above
# Deliverable: Canvas displays room outlines with doors and labels

# Sprint 2 (Day 5): User Story 6 (Selection) - Can start while US5 polish continues
# Team Member 1: US6 implementation (T050-T058)
# Team Member 2: US5 performance optimization and bug fixes from testing

# Sprint 3 (Days 6-7): User Story 7 (Movement)
# Team Member 1: US7 implementation (T062-T073)
# Team Member 2: US6 polish and integration testing

# Sprint 4 (Days 8-9): User Story 8 (Doors)
# Team Member 1: US8 implementation (T078-T093)
# Team Member 2: US7 polish and integration testing

# Sprint 5 (Days 10-12): Integration, Testing, Polish
# All team members: Phases 7-9 (many parallelizable tasks)
```

---

## Implementation Strategy

**MVP Scope (Minimum Viable Product)**:
- User Story 5 (P1) - Canvas with room outlines and automatic doors
- User Story 6 (P1) - Room selection
- User Story 7 (P1) - Basic move (rotate can be Phase 2)
- **Total**: ~4-5 days delivering functional canvas layout editing

**Incremental Delivery**:
1. ⏳ **Sprint 1**: US5 complete → Users see visual room layout on canvas (value delivered)
2. ⏳ **Sprint 2**: US6 complete → Users can select rooms interactively (enhanced UX)
3. ⏳ **Sprint 3**: US7 complete → Users can reposition and orient rooms (full layout control)
4. ⏳ **Sprint 4**: US8 complete → Users can manually refine door connections (advanced feature)

**Testing Strategy**:
- ⏳ TDD enforced: Tests written first, implementation follows
- ⏳ Unit tests for all models and services (100% coverage)
- ⏳ Widget tests for all canvas components (CustomPainter, toolbar, menus)
- ⏳ Integration test for end-to-end canvas workflow
- ⏳ Performance testing on real iOS device with LiDAR scans

**Quality Gates**:
- ⏳ All tests pass before story checkpoint
- ⏳ Code review before integration
- ⏳ No accessibility violations (VoiceOver/TalkBack tested)
- ⏳ Performance profile passes (60fps, < 500ms outline extraction, no leaks)
- ⏳ Constitution compliance verified

---

## Task Summary

**Total Tasks**: 135
**Completed (Original)**: 79 (US1-US4 from previous implementation)
**New Tasks**: 135 (Canvas enhancement)
**Pending**: 135 (100% of new tasks)

**Tasks by Phase**:
- Setup (Phase 1): 7 tasks
- Foundational (Phase 2): 5 tasks
- User Story 5 (P1): 34 tasks (8 test + 26 implementation)
- User Story 6 (P1): 12 tasks (3 test + 9 implementation)
- User Story 7 (P1): 15 tasks (3 test + 12 implementation)
- User Story 8 (P2): 20 tasks (4 test + 16 implementation)
- Data Persistence (Phase 7): 9 tasks
- Integration (Phase 8): 10 tasks
- Polish (Phase 9): 23 tasks

**Parallel Opportunities**: 58 tasks marked [P] (43% parallelizable)

**Independent Test Criteria Met**:
- ⏳ User Story 5: Canvas rendering functional with room outlines and doors
- ⏳ User Story 6: Selection functional with visual feedback
- ⏳ User Story 7: Move/rotate functional with constraints
- ⏳ User Story 8: Door placement and connections functional

**Suggested MVP Scope**: User Stories 5-7 (P1 priorities) = 61 tasks = ~5-7 days with TDD

**Format Validation**: ✅ ALL tasks follow required checklist format with checkboxes, IDs, [P] markers, [Story] labels, and file paths

---

## Notes

- Original implementation (US1-US4) is complete and merged - not included in this task breakdown
- Canvas enhancement is backward compatible - original stitching workflow still works
- Room outline extraction may require custom USDZ/GLB parsing if no suitable library exists
- Door detection accuracy depends on scan quality - 70% accuracy is target, may need tuning
- Performance testing on physical device critical - simulator won't show real canvas performance
- .env configuration allows easy customization of rotation increments and connection thresholds
- All new code follows Flutter best practices and feature-based architecture from CLAUDE.md
