# Quickstart Guide: Multi-Room Scanning - Feature 016

**Date**: 2026-01-01
**Feature**: `016-multi-room-options`
**Status**: Phase 1 Complete - Ready for Implementation

## Overview

This quickstart guide helps developers onboard to Feature 016 Multi-Room Scanning Options. It provides setup instructions, code patterns, testing scenarios, and integration points with existing Features 014 (LiDAR Scanning) and 015 (Backend Error Handling).

**Prerequisites:**
- Flutter 3.x, Dart 3.10+
- Feature 014 (LiDAR Scanning) completed
- Feature 015 (Backend Error Handling) completed
- iOS device with LiDAR (iOS 17.0+)
- BlenderAPI backend access

---

## Table of Contents

1. [Quick Start: 5-Minute Setup](#quick-start-5-minute-setup)
2. [Architecture Overview](#architecture-overview)
3. [Key Code Patterns](#key-code-patterns)
4. [Testing Guide](#testing-guide)
5. [Integration Points](#integration-points)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start: 5-Minute Setup

### Step 1: Verify Prerequisites

```bash
# Check Flutter version
flutter --version  # Should be 3.x+

# Check dependencies in pubspec.yaml
cat pubspec.yaml | grep -E "http:|model_viewer_plus:"
# http: ^1.1.0
# model_viewer_plus: ^1.10.0

# Verify Feature 014 is working
flutter test test/features/scanning/
```

### Step 2: Read Core Documents

1. **Specification** (`spec.md`) - Understand user stories and requirements
2. **Research** (`research.md`) - Review technical decisions (5 key areas)
3. **Data Model** (`data-model.md`) - Study 4 data entities
4. **API Contract** (`contracts/room-stitching-api.graphql`) - Review GraphQL schema

### Step 3: Run Existing Scans

```bash
# Launch app on iOS device with LiDAR
flutter run --flavor dev --target lib/main.dart

# Complete 2+ scans using existing Feature 014 UI:
# 1. Tap "Scan" button
# 2. Capture first room
# 3. View scan list (should show "Scan 1")
# 4. Tap "Scan another room"
# 5. Capture second room
# 6. View scan list (should show "Scan 1" and "Scan 2")

# Verify scan session works:
# - ScanSessionManager maintains in-memory list
# - "Scan another room" button appears
# - Scans persist in session (not across app restarts)
```

### Step 4: Explore Existing Code

```bash
# Scan session management (already implemented)
cat lib/features/scanning/services/scan_session_manager.dart

# Scan list UI (already implemented)
cat lib/features/scanning/screens/scan_list_screen.dart

# Room stitching placeholder (line 378-385)
cat lib/features/scanning/screens/scan_list_screen.dart | sed -n '378,385p'
```

### Step 5: Set Up Mock Backend (Optional for Local Testing)

```bash
# Create mock GraphQL server for stitching (using json-graphql-server or similar)
cd scripts/mock-backend/
npm install
npm start  # Starts mock server on http://localhost:4000

# Update GraphQL endpoint in lib/core/services/graphql_service.dart:
# final endpoint = 'http://localhost:4000/graphql'; // For local testing
```

---

## Architecture Overview

### Feature 016 Structure

```text
lib/features/scanning/
├── models/
│   ├── scan_data.dart                    # MODIFY: Add roomName field
│   ├── room_stitch_request.dart          # NEW: User Story 2
│   ├── room_stitch_job.dart              # NEW: User Story 2
│   └── stitched_model.dart               # NEW: User Story 2
├── services/
│   ├── scan_session_manager.dart         # EXISTS: No changes
│   ├── room_stitching_service.dart       # NEW: User Story 2
│   └── room_name_validator.dart          # NEW: User Story 3
├── screens/
│   ├── scan_list_screen.dart             # MODIFY: Multi-select mode (US4)
│   ├── room_stitching_screen.dart        # NEW: User Story 2 (scan selection)
│   ├── room_stitch_progress_screen.dart  # NEW: User Story 2 (progress tracking)
│   └── stitched_model_preview_screen.dart # NEW: User Story 2 (result preview)
└── widgets/
    ├── scan_list_card.dart               # NEW: Multi-select checkbox support
    └── batch_action_bottom_sheet.dart    # NEW: User Story 4

test/features/scanning/
├── models/
│   ├── room_stitch_request_test.dart     # NEW: TDD - write first
│   ├── room_stitch_job_test.dart         # NEW: TDD - write first
│   └── stitched_model_test.dart          # NEW: TDD - write first
├── services/
│   ├── room_stitching_service_test.dart  # NEW: TDD - write first
│   └── room_name_validator_test.dart     # NEW: TDD - write first
└── screens/
    └── room_stitching_flow_test.dart     # NEW: Integration test

specs/016-multi-room-options/
├── spec.md                               # User stories, requirements
├── plan.md                               # Implementation plan
├── research.md                           # Technical decisions
├── data-model.md                         # Entity definitions
├── quickstart.md                         # This file
├── contracts/
│   └── room-stitching-api.graphql        # GraphQL schema
└── checklists/
    └── requirements.md                   # Spec validation
```

### User Story Priority

```text
✅ User Story 1 (P1): Multiple Room Scanning Session - COMPLETE (60%)
   Foundation: Session management, scan list, "Scan another room" button

❌ User Story 2 (P2): Room Stitching for Complete Property Model - NOT IMPLEMENTED (30%)
   Core value: Merge scans into cohesive model via backend API

❌ User Story 3 (P3): Scan Organization and Naming - NOT IMPLEMENTED (5%)
   Enhancement: Assign room names for easier identification

❌ User Story 4 (P4): Batch Operations on Multiple Scans - NOT IMPLEMENTED (5%)
   Efficiency: Export/upload/delete multiple scans at once
```

**Recommended Implementation Order:**
1. User Story 2 (Stitching) - Core functionality
2. User Story 3 (Naming) - Improves US2 UX
3. User Story 4 (Batch operations) - Independent enhancement

---

## Key Code Patterns

### Pattern 1: Room Name Validation (User Story 3)

**File:** `lib/features/scanning/services/room_name_validator.dart`

```dart
class RoomNameValidator {
  static const int maxLength = 50;

  static final RegExp _namePattern = RegExp(
    r'^[a-zA-Z0-9\p{L}\p{Emoji} ]{1,50}$',
    unicode: true,
  );

  static bool isValid(String name) {
    if (name.isEmpty || name.length > maxLength) return false;
    return _namePattern.hasMatch(name.trim());
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    if (value.length > maxLength) {
      return 'Room name must be 50 characters or less';
    }
    if (!_namePattern.hasMatch(value.trim())) {
      return 'Room name can only contain letters, numbers, spaces, and emojis';
    }
    return null; // Valid
  }
}

// Usage in UI:
TextFormField(
  maxLength: 50,
  validator: RoomNameValidator.validate,
  decoration: InputDecoration(
    labelText: 'Room Name (optional)',
    hintText: 'e.g., Living Room 🛋️',
  ),
)
```

### Pattern 2: GraphQL Stitching Mutation (User Story 2)

**File:** `lib/features/scanning/services/room_stitching_service.dart`

```dart
class RoomStitchingService {
  final GraphQLService _graphQLService;
  final RetryPolicyService _retryPolicy;

  // Mutation: Initiate stitching job
  Future<RoomStitchJob> startStitching(RoomStitchRequest request) async {
    // Validate request
    if (!request.isValid()) {
      throw ArgumentError('Stitching request requires minimum 2 scans');
    }

    // GraphQL mutation
    const mutation = '''
      mutation StitchRooms(\$input: StitchRoomsInput!) {
        stitchRooms(input: \$input) {
          jobId
          status
          estimatedDurationSeconds
          createdAt
        }
      }
    ''';

    try {
      final response = await _graphQLService.mutate(
        mutation,
        variables: request.toGraphQLVariables(),
      );

      return RoomStitchJob.fromJson(
        response.data?['stitchRooms'] as Map<String, dynamic>,
      );
    } catch (e) {
      // Use ErrorMessageService to translate to user-friendly message
      final userMessage = ErrorMessageService.translate(e);
      throw Exception(userMessage);
    }
  }

  // Query: Poll job status
  Future<RoomStitchJob> pollStitchStatus({
    required String jobId,
    Duration pollingInterval = const Duration(seconds: 2),
    int maxAttempts = 60, // 2 min default
    void Function(RoomStitchJob job)? onStatusChange,
  }) async {
    RoomStitchJobStatus? lastStatus;
    int attempt = 0;

    const query = '''
      query GetStitchJobStatus(\$jobId: ID!) {
        stitchJob(jobId: \$jobId) {
          jobId
          status
          progress
          errorCode
          errorMessage
          resultUrl
          completedAt
        }
      }
    ''';

    while (attempt < maxAttempts) {
      try {
        final response = await _graphQLService.query(
          query,
          variables: {'jobId': jobId},
        );

        final job = RoomStitchJob.fromJson(
          response.data?['stitchJob'] as Map<String, dynamic>,
        );

        // Notify on status change
        if (job.status != lastStatus) {
          onStatusChange?.call(job);
          lastStatus = job.status;
        }

        // Terminal states
        if (job.isTerminal) {
          return job;
        }

        // Wait before next poll
        await Future.delayed(pollingInterval);
        attempt++;
      } catch (e) {
        // Use RetryPolicyService to decide if error is recoverable
        final isRecoverable = _retryPolicy.isRecoverableError(e);

        if (!isRecoverable) {
          rethrow; // Non-recoverable error (e.g., invalid jobId)
        }

        // Recoverable error: retry with delay
        await Future.delayed(pollingInterval);
        attempt++;
      }
    }

    // Timeout
    throw TimeoutException(
      'Stitching job did not complete within ${maxAttempts * pollingInterval.inSeconds} seconds',
    );
  }

  // Download stitched model
  Future<File> downloadStitchedModel(String resultUrl, String filename) async {
    final response = await http.get(Uri.parse(resultUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to download stitched model: ${response.statusCode}');
    }

    final scansDir = await FileStorageService().getScansDirectory();
    final stitchedFile = File('${scansDir.path}/$filename');

    await stitchedFile.writeAsBytes(response.bodyBytes);

    return stitchedFile;
  }
}
```

### Pattern 3: Multi-Select UI (User Story 4)

**File:** `lib/features/scanning/screens/scan_list_screen.dart`

```dart
class _ScanListScreenState extends State<ScanListScreen> {
  bool _multiSelectMode = false;
  final Set<String> _selectedScanIds = {};

  void _enterMultiSelectMode() {
    setState(() {
      _multiSelectMode = true;
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _multiSelectMode = false;
      _selectedScanIds.clear();
    });
  }

  void _toggleScanSelection(String scanId) {
    setState(() {
      if (_selectedScanIds.contains(scanId)) {
        _selectedScanIds.remove(scanId);
        if (_selectedScanIds.isEmpty) {
          _multiSelectMode = false;
        }
      } else {
        _selectedScanIds.add(scanId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _multiSelectMode
              ? '${_selectedScanIds.length} selected'
              : 'Scans',
        ),
        leading: _multiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
              )
            : null,
      ),
      body: ListView.builder(
        itemCount: scans.length,
        itemBuilder: (context, index) {
          final scan = scans[index];
          return GestureDetector(
            onLongPress: () {
              if (!_multiSelectMode) {
                _enterMultiSelectMode();
              }
              _toggleScanSelection(scan.id);
            },
            onTap: () {
              if (_multiSelectMode) {
                _toggleScanSelection(scan.id);
              } else {
                _previewScan(scan);
              }
            },
            child: ScanListCard(
              scan: scan,
              isSelected: _selectedScanIds.contains(scan.id),
              showCheckbox: _multiSelectMode,
            ),
          );
        },
      ),
      bottomSheet: _multiSelectMode && _selectedScanIds.isNotEmpty
          ? BatchActionBottomSheet(
              selectedCount: _selectedScanIds.length,
              onExportAll: _handleExportAll,
              onUploadAll: _handleUploadAll,
              onDeleteAll: _handleDeleteAll,
            )
          : null,
    );
  }
}
```

### Pattern 4: Progress Screen with Polling (User Story 2)

**File:** `lib/features/scanning/screens/room_stitch_progress_screen.dart`

```dart
class RoomStitchProgressScreen extends StatefulWidget {
  final String jobId;
  final RoomStitchRequest request;

  const RoomStitchProgressScreen({
    required this.jobId,
    required this.request,
  });

  @override
  State<RoomStitchProgressScreen> createState() =>
      _RoomStitchProgressScreenState();
}

class _RoomStitchProgressScreenState extends State<RoomStitchProgressScreen> {
  RoomStitchJob? _currentJob;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _startPolling() async {
    setState(() {
      _isPolling = true;
    });

    try {
      final stitchingService = context.read<RoomStitchingService>();

      final completedJob = await stitchingService.pollStitchStatus(
        jobId: widget.jobId,
        onStatusChange: (job) {
          setState(() {
            _currentJob = job;
          });
        },
      );

      // Handle completion
      if (completedJob.isSuccessful) {
        _handleSuccess(completedJob);
      } else {
        _handleFailure(completedJob);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() {
        _isPolling = false;
      });
    }
  }

  Future<void> _handleSuccess(RoomStitchJob job) async {
    final stitchingService = context.read<RoomStitchingService>();

    // Download stitched model
    final filename = widget.request.generateFilename();
    final file = await stitchingService.downloadStitchedModel(
      job.resultUrl!,
      filename,
    );

    // Create StitchedModel object
    final stitchedModel = StitchedModel.fromJob(
      job,
      file.path,
      await file.length(),
      widget.request.scanIds,
      widget.request.roomNames,
    );

    // Navigate to preview screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => StitchedModelPreviewScreen(
            model: stitchedModel,
          ),
        ),
      );
    }
  }

  void _handleFailure(RoomStitchJob job) {
    // Show error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stitching Failed'),
        content: Text(job.errorMessage ?? 'An unknown error occurred'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startPolling(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stitching Progress'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress indicator
            CircularProgressIndicator(
              value: _currentJob != null
                  ? _currentJob!.progress / 100.0
                  : null,
            ),
            const SizedBox(height: 24),

            // Status message
            Text(
              _currentJob?.statusMessage ?? 'Starting...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // Progress percentage
            if (_currentJob != null)
              Text(
                '${_currentJob!.progress}% complete',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Testing Guide

### Test-Driven Development (TDD) Approach

**Constitution Requirement:** All tests MUST be written BEFORE implementation.

#### Step 1: Write Model Tests First

```bash
# Create test file
touch test/features/scanning/models/room_stitch_request_test.dart
```

```dart
// test/features/scanning/models/room_stitch_request_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_request.dart';

void main() {
  group('RoomStitchRequest', () {
    test('isValid returns false for less than 2 scans', () {
      final request = RoomStitchRequest(
        projectId: 'proj-001',
        scanIds: ['scan-001'], // Only 1 scan
      );

      expect(request.isValid(), false);
    });

    test('isValid returns true for 2 or more scans', () {
      final request = RoomStitchRequest(
        projectId: 'proj-001',
        scanIds: ['scan-001', 'scan-002'],
      );

      expect(request.isValid(), true);
    });

    test('generateFilename includes room names', () {
      final request = RoomStitchRequest(
        projectId: 'proj-001',
        scanIds: ['scan-001', 'scan-002'],
        roomNames: {
          'scan-001': 'Living Room',
          'scan-002': 'Master Bedroom',
        },
      );

      final filename = request.generateFilename();

      expect(filename, contains('living-room'));
      expect(filename, contains('master-bedroom'));
      expect(filename, endsWith('.glb'));
    });

    test('toGraphQLVariables formats correctly', () {
      final request = RoomStitchRequest(
        projectId: 'proj-001',
        scanIds: ['scan-001', 'scan-002'],
        alignmentMode: AlignmentMode.auto,
        outputFormat: OutputFormat.glb,
      );

      final variables = request.toGraphQLVariables();

      expect(variables['input']['projectId'], 'proj-001');
      expect(variables['input']['scanIds'], ['scan-001', 'scan-002']);
      expect(variables['input']['alignmentMode'], 'AUTO');
      expect(variables['input']['outputFormat'], 'GLB');
    });
  });
}
```

**Run tests (should FAIL initially):**

```bash
flutter test test/features/scanning/models/room_stitch_request_test.dart
# Expected: All tests fail (model not yet implemented)
```

#### Step 2: Implement Model to Pass Tests

```bash
# Create model file
touch lib/features/scanning/models/room_stitch_request.dart
```

```dart
// lib/features/scanning/models/room_stitch_request.dart
// ... (implement based on data-model.md)
```

**Run tests again (should PASS):**

```bash
flutter test test/features/scanning/models/room_stitch_request_test.dart
# Expected: All tests pass
```

#### Step 3: Write Service Tests

```dart
// test/features/scanning/services/room_stitching_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vronmobile2/features/scanning/services/room_stitching_service.dart';

void main() {
  late RoomStitchingService service;
  late MockGraphQLService mockGraphQL;

  setUp(() {
    mockGraphQL = MockGraphQLService();
    service = RoomStitchingService(mockGraphQL);
  });

  group('startStitching', () {
    test('throws error for invalid request (less than 2 scans)', () async {
      final request = RoomStitchRequest(
        projectId: 'proj-001',
        scanIds: ['scan-001'],
      );

      expect(
        () => service.startStitching(request),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('calls GraphQL mutation with correct variables', () async {
      final request = RoomStitchRequest(
        projectId: 'proj-001',
        scanIds: ['scan-001', 'scan-002'],
      );

      when(mockGraphQL.mutate(any, variables: anyNamed('variables')))
          .thenAnswer((_) async => GraphQLResponse(
                data: {
                  'stitchRooms': {
                    'jobId': 'job-001',
                    'status': 'PENDING',
                    'createdAt': DateTime.now().toIso8601String(),
                  }
                },
              ));

      final job = await service.startStitching(request);

      expect(job.jobId, 'job-001');
      expect(job.status, RoomStitchJobStatus.pending);
      verify(mockGraphQL.mutate(any, variables: anyNamed('variables')))
          .called(1);
    });
  });

  group('pollStitchStatus', () {
    test('polls every 2 seconds until terminal state', () async {
      // Mock responses: pending → aligning → completed
      when(mockGraphQL.query(any, variables: anyNamed('variables')))
          .thenAnswer((_) async {
        // Return different responses on each call
        // (implementation uses mocking library's sequential answers)
      });

      final job = await service.pollStitchStatus(jobId: 'job-001');

      expect(job.isTerminal, true);
      expect(job.isSuccessful, true);
    });

    test('times out after maxAttempts', () async {
      when(mockGraphQL.query(any, variables: anyNamed('variables')))
          .thenAnswer((_) async => GraphQLResponse(
                data: {
                  'stitchJob': {
                    'jobId': 'job-001',
                    'status': 'PROCESSING',
                    'progress': 50,
                    'createdAt': DateTime.now().toIso8601String(),
                  }
                },
              ));

      expect(
        () => service.pollStitchStatus(
          jobId: 'job-001',
          maxAttempts: 3, // Timeout after 3 attempts
          pollingInterval: const Duration(milliseconds: 100), // Fast for testing
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
```

#### Step 4: Write Widget Tests

```dart
// test/features/scanning/screens/room_stitch_progress_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/screens/room_stitch_progress_screen.dart';

void main() {
  testWidgets('displays progress indicator and status message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomStitchProgressScreen(
          jobId: 'job-001',
          request: RoomStitchRequest(
            projectId: 'proj-001',
            scanIds: ['scan-001', 'scan-002'],
          ),
        ),
      ),
    );

    // Verify initial UI
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Starting...'), findsOneWidget);

    // Wait for polling to start
    await tester.pump(Duration(seconds: 1));

    // Verify progress updates
    expect(find.textContaining('% complete'), findsOneWidget);
  });

  testWidgets('navigates to preview screen on success', (tester) async {
    // Mock successful stitching completion
    // ... (implementation uses mocking)

    await tester.pumpWidget(
      MaterialApp(
        home: RoomStitchProgressScreen(
          jobId: 'job-001',
          request: RoomStitchRequest(
            projectId: 'proj-001',
            scanIds: ['scan-001', 'scan-002'],
          ),
        ),
      ),
    );

    // Wait for completion
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Verify navigation to preview screen
    expect(find.byType(StitchedModelPreviewScreen), findsOneWidget);
  });
}
```

### Integration Test Scenarios

```dart
// integration_test/multi_room_stitching_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vronmobile2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete multi-room stitching flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Complete first scan
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    // ... (simulate LiDAR scanning)

    // 2. Return to scan list
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 3. Verify "Scan another room" button
    expect(find.text('Scan another room'), findsOneWidget);

    // 4. Complete second scan
    await tester.tap(find.text('Scan another room'));
    await tester.pumpAndSettle();
    // ... (simulate second scan)

    // 5. Return to scan list
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 6. Verify both scans in list
    expect(find.text('Scan 1'), findsOneWidget);
    expect(find.text('Scan 2'), findsOneWidget);

    // 7. Initiate stitching
    await tester.tap(find.text('Room stitching'));
    await tester.pumpAndSettle();

    // 8. Select both scans
    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).last);
    await tester.tap(find.text('Start Stitching'));
    await tester.pumpAndSettle();

    // 9. Verify progress screen
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 10. Wait for completion (mock backend)
    await tester.pumpAndSettle(Duration(seconds: 10));

    // 11. Verify preview screen
    expect(find.byType(StitchedModelPreviewScreen), findsOneWidget);
  });
}
```

---

## Integration Points

### With Feature 014 (LiDAR Scanning)

**Reused Components:**
- `ScanData` model (add `roomName` field)
- `ScanSessionManager` service (no changes)
- `FileStorageService` (save stitched models to same directory)
- `GraphQLService` (same authentication and error handling)

**Modification Required:**
- Update `ScanData` to include `roomName: String?` field
- Regenerate JSON serialization: `flutter pub run build_runner build`

### With Feature 015 (Backend Error Handling)

**Reused Components:**
- `RetryPolicyService` (classify stitching errors as recoverable/non-recoverable)
- `ErrorMessageService` (translate GraphQL error codes to user-friendly messages)
- Offline queue pattern (queue stitching requests when offline)

**New Error Mappings:**
```dart
// lib/features/scanning/services/error_message_service.dart

class ErrorMessageService {
  static String translate(dynamic error) {
    final errorCode = error.extensions?['code'] as String?;

    switch (errorCode) {
      case 'INSUFFICIENT_OVERLAP':
        return 'Scans need more overlap. Try rescanning with at least 20% common area between rooms.';
      case 'ALIGNMENT_FAILURE':
        return 'Scans are incompatible. Make sure you scanned adjacent rooms in the same session.';
      case 'BACKEND_TIMEOUT':
        return 'Stitching took too long. Try stitching fewer rooms at once.';
      case 'INVALID_SCAN_ID':
        return 'One or more scans are invalid. Please verify all scans exist.';
      case 'UNAUTHORIZED':
        return 'You need to be logged in to stitch rooms. Please sign in and try again.';
      default:
        return 'An error occurred during stitching. Please try again or contact support.';
    }
  }
}
```

### With Backend (BlenderAPI)

**Authentication:**
- Use same Bearer token from Feature 014
- Guest users: Prompt account creation before stitching (FR-020)

**Endpoints:**
- Mutation: `stitchRooms` (initiate job)
- Query: `stitchJob` (poll status)
- Query: `stitchJobDiagnostics` (investigate failures)

**Error Handling:**
- Parse GraphQL extensions for error codes
- Use `ErrorMessageService` for user-friendly messages
- Queue offline requests via Feature 015 offline queue

---

## Troubleshooting

### Issue: "Room stitching" button shows "coming soon"

**Cause:** Placeholder implementation in `scan_list_screen.dart:378-385`

**Solution:**
```dart
// OLD (scan_list_screen.dart:378-385)
void _roomStitching() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Room stitching feature coming soon!')),
  );
}

// NEW (implement navigation to stitching screen)
void _roomStitching() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => RoomStitchingScreen(
        scans: _scanSessionManager.scans,
      ),
    ),
  );
}
```

### Issue: Tests fail with "MissingStubError"

**Cause:** Mocks not set up correctly

**Solution:**
```dart
// Use mockito to generate mocks
import 'package:mockito/annotations.dart';

@GenerateMocks([GraphQLService, RoomStitchingService])
void main() {
  // Run: flutter pub run build_runner build
}
```

### Issue: Polling never completes

**Cause:** Mock backend not returning terminal status

**Solution:**
```dart
// Mock sequential responses in tests
when(mockGraphQL.query(any, variables: anyNamed('variables')))
    .thenAnswer((_) async => Future.delayed(
          Duration(seconds: 2),
          () => GraphQLResponse(data: {
            'stitchJob': {
              'status': 'COMPLETED', // Return terminal status
              'progress': 100,
              'resultUrl': 'https://example.com/stitched.glb',
            }
          }),
        ));
```

### Issue: Downloaded stitched model not visible

**Cause:** File saved to wrong directory

**Solution:**
```dart
// Use FileStorageService to get correct directory
final scansDir = await FileStorageService().getScansDirectory();
// Should be: /Documents/scans/

// Verify file exists
final file = File('${scansDir.path}/stitched-*.glb');
print('File exists: ${await file.exists()}');
```

### Issue: Room names with emojis cause filename errors

**Cause:** Emoji characters not supported in filenames on some systems

**Solution:**
```dart
// Use FilenameSanitizer to convert emojis to hex codes
import 'package:vronmobile2/features/scanning/utils/filename_sanitizer.dart';

final sanitized = FilenameSanitizer.sanitizeForFilename('Living Room 🛋️');
// Output: "living-room-emoji-1f6cb"
```

---

## Next Steps

1. **Implement User Story 2 (Stitching):**
   - Write tests for `RoomStitchRequest`, `RoomStitchJob`, `StitchedModel` models
   - Implement models to pass tests
   - Write tests for `RoomStitchingService`
   - Implement service with polling logic
   - Build UI screens (stitching, progress, preview)

2. **Implement User Story 3 (Naming):**
   - Add `roomName` field to `ScanData`
   - Implement `RoomNameValidator`
   - Add name editor dialog to scan list UI

3. **Implement User Story 4 (Batch Operations):**
   - Add multi-select mode to `ScanListScreen`
   - Implement batch export/upload/delete actions

4. **Backend Coordination:**
   - Share GraphQL contract with backend team
   - Set up staging environment for testing
   - Coordinate error code mappings

5. **Documentation:**
   - Update CLAUDE.md with new patterns
   - Add API integration guide for backend team
   - Create user-facing help docs for stitching

---

## Resources

- **Feature 014 Research:** `specs/014-lidar-scanning/research.md`
- **Feature 015 Tasks:** `specs/015-backend-error-handling/tasks.md`
- **GraphQL API:** `contracts/room-stitching-api.graphql`
- **Data Model:** `data-model.md`
- **Research Decisions:** `research.md`

**Questions?** Contact the feature owner or open an issue in the project repo.
