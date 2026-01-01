# Data Model: Multi-Room Scanning - Feature 016

**Date**: 2026-01-01
**Feature**: `016-multi-room-options`
**Status**: Phase 1 Complete

## Overview

This document defines the data models for Feature 016 Multi-Room Scanning Options. It extends existing Feature 014 models (ScanData, ScanSessionManager) and introduces 3 new entities for room stitching functionality. All models follow Flutter/Dart conventions with JSON serialization for API integration and local storage.

---

## Entity Relationship Diagram

```text
┌────────────────────┐
│  ScanSessionManager│  (Existing - Feature 014)
│  ─────────────────│
│  - scans: List     │  1:N relationship
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│     ScanData       │  (Modified - Add roomName field)
│  ─────────────────│
│  - id: String      │  Used by RoomStitchRequest
│  - roomName: String│  NEW FIELD (Feature 016)
│  - localPath: String│
│  - format: enum    │
│  - fileSizeBytes   │
│  - capturedAt      │
└────────────────────┘
          │
          │ Selected for stitching
          ▼
┌────────────────────┐
│ RoomStitchRequest  │  (NEW - User Story 2)
│  ─────────────────│
│  - projectId: String│
│  - scanIds: List   │  2+ scans minimum
│  - alignmentMode   │
│  - outputFormat    │
│  - roomNames: Map  │  scanId → room name
└─────────┬──────────┘
          │
          │ Initiates stitching job
          ▼
┌────────────────────┐
│  RoomStitchJob     │  (NEW - User Story 2)
│  ─────────────────│
│  - jobId: String   │  Backend-assigned UUID
│  - status: enum    │  PENDING → ... → COMPLETED
│  - progress: int   │  0-100 percentage
│  - resultUrl: String│ If COMPLETED
│  - errorMessage    │  If FAILED
└─────────┬──────────┘
          │
          │ Downloads stitched model
          ▼
┌────────────────────┐
│  StitchedModel     │  (NEW - User Story 2)
│  ─────────────────│
│  - jobId: String   │  Links to RoomStitchJob
│  - localPath: String│ GLB file in Documents/scans/
│  - originalScanIds │  Source scans
│  - roomNames: Map  │  Preserved from request
│  - fileSizeBytes   │
│  - createdAt       │
└────────────────────┘
```

---

## Model Definitions

### 1. ScanData (Modified)

**Purpose**: Represents individual room scan captured via LiDAR (Feature 014) with optional room name (Feature 016).

**Location**: `lib/features/scanning/models/scan_data.dart` (EXISTING - modify)

**Changes for Feature 016**:
- Add `roomName` field (nullable String)
- Add `roomNameOrDefault` getter for UI display

**Dart Model**:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'scan_data.g.dart';

enum ScanFormat { usdz, glb }

enum ScanStatus {
  captured,   // Scan captured locally
  uploading,  // Uploading to backend
  uploaded,   // Successfully uploaded
  failed,     // Upload/conversion failed
}

@JsonSerializable()
class ScanData {
  /// Unique identifier for this scan (UUID v4)
  final String id;

  /// Local file path (absolute path to USDZ or GLB file)
  final String localPath;

  /// Format of the scan file (USDZ from LiDAR, GLB from conversion)
  final ScanFormat format;

  /// File size in bytes
  final int fileSizeBytes;

  /// Timestamp when scan was captured
  final DateTime capturedAt;

  /// Current status (captured, uploading, uploaded, failed)
  final ScanStatus status;

  /// Optional metadata (JSON-serializable map)
  final Map<String, dynamic>? metadata;

  /// Local path to GLB file (if converted from USDZ)
  final String? glbLocalPath;

  /// User-assigned room name (Feature 016 - User Story 3)
  /// Nullable - if null, UI displays "Scan {sequenceNumber}"
  final String? roomName;

  const ScanData({
    required this.id,
    required this.localPath,
    required this.format,
    required this.fileSizeBytes,
    required this.capturedAt,
    required this.status,
    this.metadata,
    this.glbLocalPath,
    this.roomName, // NEW for Feature 016
  });

  /// Display name for UI (room name or default "Scan N")
  /// Used in scan_list_screen and stitching UI
  String roomNameOrDefault(int sequenceNumber) {
    return roomName ?? 'Scan $sequenceNumber';
  }

  /// Create copy with updated fields
  ScanData copyWith({
    String? id,
    String? localPath,
    ScanFormat? format,
    int? fileSizeBytes,
    DateTime? capturedAt,
    ScanStatus? status,
    Map<String, dynamic>? metadata,
    String? glbLocalPath,
    String? roomName, // NEW
  }) {
    return ScanData(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      format: format ?? this.format,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      glbLocalPath: glbLocalPath ?? this.glbLocalPath,
      roomName: roomName ?? this.roomName, // NEW
    );
  }

  // JSON serialization
  factory ScanData.fromJson(Map<String, dynamic> json) =>
      _$ScanDataFromJson(json);
  Map<String, dynamic> toJson() => _$ScanDataToJson(this);
}
```

**Validation Rules**:
- `roomName`: Max 50 characters, alphanumeric + spaces + emojis (validated in UI via RoomNameValidator)
- `roomName`: Nullable (not required for scanning workflow)

**Example Usage**:

```dart
// Existing scan without room name
final scan1 = ScanData(
  id: 'scan-001',
  localPath: '/Documents/scans/scan-001.usdz',
  format: ScanFormat.usdz,
  fileSizeBytes: 15_000_000,
  capturedAt: DateTime.now(),
  status: ScanStatus.captured,
);

// User assigns room name (Feature 016 - US3)
final scan1Named = scan1.copyWith(roomName: 'Living Room 🛋️');

// Display in UI
print(scan1.roomNameOrDefault(1));      // "Scan 1"
print(scan1Named.roomNameOrDefault(1)); // "Living Room 🛋️"
```

---

### 2. RoomStitchRequest (NEW)

**Purpose**: Request payload for initiating room stitching job via GraphQL mutation.

**Location**: `lib/features/scanning/models/room_stitch_request.dart` (NEW)

**Dependencies**: None (plain Dart model)

**Dart Model**:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'room_stitch_request.g.dart';

enum AlignmentMode {
  auto,   // System determines alignment (MVP)
  manual, // User-provided hints (future)
}

enum OutputFormat {
  glb,  // Default for stitched models
  usdz, // iOS native format (optional)
}

@JsonSerializable()
class RoomStitchRequest {
  /// Target project ID (UUID) - required for backend association
  final String projectId;

  /// List of scan IDs to stitch together (minimum 2)
  final List<String> scanIds;

  /// Alignment mode (auto or manual)
  @JsonKey(defaultValue: AlignmentMode.auto)
  final AlignmentMode alignmentMode;

  /// Output format (GLB or USDZ)
  @JsonKey(defaultValue: OutputFormat.glb)
  final OutputFormat outputFormat;

  /// Optional room names (scanId → room name)
  /// Used for metadata and filename generation
  final Map<String, String>? roomNames;

  const RoomStitchRequest({
    required this.projectId,
    required this.scanIds,
    this.alignmentMode = AlignmentMode.auto,
    this.outputFormat = OutputFormat.glb,
    this.roomNames,
  });

  /// Validation: Ensure minimum 2 scans (FR-007)
  bool isValid() {
    return scanIds.length >= 2 && projectId.isNotEmpty;
  }

  /// Generate filename for stitched model
  /// Example: "stitched-living-room-master-bedroom-2025-01-01.glb"
  String generateFilename() {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];

    if (roomNames != null && roomNames!.isNotEmpty) {
      // Join room names with hyphens
      final names = roomNames!.values
          .map((name) => _sanitizeFilename(name))
          .join('-');
      return 'stitched-$names-$timestamp.${_formatExtension()}';
    } else {
      // Fallback: use scan count
      return 'stitched-${scanIds.length}-rooms-$timestamp.${_formatExtension()}';
    }
  }

  String _formatExtension() {
    return outputFormat == OutputFormat.glb ? 'glb' : 'usdz';
  }

  String _sanitizeFilename(String name) {
    // Replace spaces with hyphens, lowercase, remove special chars
    return name
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-');
  }

  // JSON serialization
  factory RoomStitchRequest.fromJson(Map<String, dynamic> json) =>
      _$RoomStitchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RoomStitchRequestToJson(this);

  /// Convert to GraphQL variables
  Map<String, dynamic> toGraphQLVariables() {
    return {
      'input': {
        'projectId': projectId,
        'scanIds': scanIds,
        'alignmentMode': alignmentMode.name.toUpperCase(),
        'outputFormat': outputFormat.name.toUpperCase(),
        if (roomNames != null && roomNames!.isNotEmpty)
          'roomNames': roomNames!.entries
              .map((e) => {'scanId': e.key, 'name': e.value})
              .toList(),
      },
    };
  }
}
```

**Validation Rules**:
- `scanIds`: Minimum 2 scans required (enforced in isValid())
- `projectId`: Must be valid UUID (validated by GraphQL schema)
- `roomNames`: Optional map (scanId → room name); each name max 50 chars

**Example Usage**:

```dart
// Create stitching request for 3 rooms
final request = RoomStitchRequest(
  projectId: 'proj-001',
  scanIds: ['scan-001', 'scan-002', 'scan-003'],
  alignmentMode: AlignmentMode.auto,
  outputFormat: OutputFormat.glb,
  roomNames: {
    'scan-001': 'Living Room',
    'scan-002': 'Master Bedroom',
    'scan-003': 'Kitchen',
  },
);

// Validate before sending
assert(request.isValid()); // true (3 scans >= 2)

// Convert to GraphQL variables
final variables = request.toGraphQLVariables();
// {
//   'input': {
//     'projectId': 'proj-001',
//     'scanIds': ['scan-001', 'scan-002', 'scan-003'],
//     'alignmentMode': 'AUTO',
//     'outputFormat': 'GLB',
//     'roomNames': [
//       {'scanId': 'scan-001', 'name': 'Living Room'},
//       {'scanId': 'scan-002', 'name': 'Master Bedroom'},
//       {'scanId': 'scan-003', 'name': 'Kitchen'},
//     ],
//   }
// }

// Generate filename
print(request.generateFilename());
// "stitched-living-room-master-bedroom-kitchen-2025-01-01.glb"
```

---

### 3. RoomStitchJob (NEW)

**Purpose**: Tracks active stitching operation progress via polling.

**Location**: `lib/features/scanning/models/room_stitch_job.dart` (NEW)

**Dependencies**: None

**Dart Model**:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'room_stitch_job.g.dart';

enum RoomStitchJobStatus {
  pending,     // Job queued
  uploading,   // Uploading scans to backend
  processing,  // Backend processing initiated
  aligning,    // Aligning coordinate systems
  merging,     // Merging geometry
  completed,   // Success - resultUrl available
  failed,      // Error - errorMessage available
}

@JsonSerializable()
class RoomStitchJob {
  /// Unique job identifier (UUID from backend)
  final String jobId;

  /// Current status
  final RoomStitchJobStatus status;

  /// Progress percentage (0-100)
  final int progress;

  /// Error message (if status == failed)
  final String? errorMessage;

  /// Signed URL to download stitched GLB (if status == completed)
  final String? resultUrl;

  /// Timestamp when job was created
  final DateTime createdAt;

  /// Timestamp when job completed (success or failure)
  final DateTime? completedAt;

  /// Estimated duration in seconds (from mutation response)
  final int? estimatedDurationSeconds;

  const RoomStitchJob({
    required this.jobId,
    required this.status,
    required this.progress,
    this.errorMessage,
    this.resultUrl,
    required this.createdAt,
    this.completedAt,
    this.estimatedDurationSeconds,
  });

  /// Check if job is in terminal state (completed or failed)
  bool get isTerminal {
    return status == RoomStitchJobStatus.completed ||
        status == RoomStitchJobStatus.failed;
  }

  /// Check if job is successful
  bool get isSuccessful {
    return status == RoomStitchJobStatus.completed && resultUrl != null;
  }

  /// Duration since job started (in seconds)
  int get elapsedSeconds {
    final end = completedAt ?? DateTime.now();
    return end.difference(createdAt).inSeconds;
  }

  /// User-friendly status message for UI
  String get statusMessage {
    switch (status) {
      case RoomStitchJobStatus.pending:
        return 'Waiting to start...';
      case RoomStitchJobStatus.uploading:
        return 'Uploading scans...';
      case RoomStitchJobStatus.processing:
        return 'Processing...';
      case RoomStitchJobStatus.aligning:
        return 'Aligning rooms...';
      case RoomStitchJobStatus.merging:
        return 'Merging geometry...';
      case RoomStitchJobStatus.completed:
        return 'Stitching complete!';
      case RoomStitchJobStatus.failed:
        return errorMessage ?? 'Stitching failed';
    }
  }

  // JSON serialization
  factory RoomStitchJob.fromJson(Map<String, dynamic> json) =>
      _$RoomStitchJobFromJson(json);
  Map<String, dynamic> toJson() => _$RoomStitchJobToJson(this);

  /// Create copy with updated fields (for polling updates)
  RoomStitchJob copyWith({
    String? jobId,
    RoomStitchJobStatus? status,
    int? progress,
    String? errorMessage,
    String? resultUrl,
    DateTime? createdAt,
    DateTime? completedAt,
    int? estimatedDurationSeconds,
  }) {
    return RoomStitchJob(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      resultUrl: resultUrl ?? this.resultUrl,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
    );
  }
}
```

**State Transitions**:

```text
PENDING → UPLOADING → PROCESSING → ALIGNING → MERGING → COMPLETED
                                                         ↘
                                                          FAILED
```

**Validation Rules**:
- `progress`: 0-100 range (enforced by backend)
- `resultUrl`: Required if status == COMPLETED
- `errorMessage`: Required if status == FAILED

**Example Usage**:

```dart
// Initial job from mutation response
final job = RoomStitchJob(
  jobId: 'job-001',
  status: RoomStitchJobStatus.pending,
  progress: 0,
  createdAt: DateTime.now(),
  estimatedDurationSeconds: 120,
);

// Poll update: uploading
final job2 = job.copyWith(
  status: RoomStitchJobStatus.uploading,
  progress: 10,
);

// Poll update: processing
final job3 = job2.copyWith(
  status: RoomStitchJobStatus.processing,
  progress: 40,
);

// Poll update: completed
final job4 = job3.copyWith(
  status: RoomStitchJobStatus.completed,
  progress: 100,
  resultUrl: 'https://s3.amazonaws.com/bucket/stitched-001.glb?signature=...',
  completedAt: DateTime.now(),
);

// Check terminal state
assert(job4.isTerminal); // true
assert(job4.isSuccessful); // true

// Display in UI
print(job4.statusMessage); // "Stitching complete!"
print('Elapsed: ${job4.elapsedSeconds} seconds'); // e.g., "Elapsed: 115 seconds"
```

---

### 4. StitchedModel (NEW)

**Purpose**: Represents downloaded and locally stored stitched 3D model.

**Location**: `lib/features/scanning/models/stitched_model.dart` (NEW)

**Dependencies**: ScanData (for originalScanIds)

**Dart Model**:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'stitched_model.g.dart';

@JsonSerializable()
class StitchedModel {
  /// Unique identifier (same as RoomStitchJob.jobId)
  final String id;

  /// Local file path to downloaded GLB file
  /// Example: "/Documents/scans/stitched-living-room-master-bedroom-2025-01-01.glb"
  final String localPath;

  /// List of original scan IDs that were stitched together
  final List<String> originalScanIds;

  /// Room names from stitching request (scanId → room name)
  final Map<String, String>? roomNames;

  /// File size in bytes (of stitched GLB file)
  final int fileSizeBytes;

  /// Timestamp when stitched model was created
  final DateTime createdAt;

  /// Output format (GLB or USDZ)
  final String format; // "glb" or "usdz"

  /// Optional metadata (backend may include polygon count, texture info, etc.)
  final Map<String, dynamic>? metadata;

  const StitchedModel({
    required this.id,
    required this.localPath,
    required this.originalScanIds,
    this.roomNames,
    required this.fileSizeBytes,
    required this.createdAt,
    this.format = 'glb',
    this.metadata,
  });

  /// Display name for UI (based on room names or scan count)
  String get displayName {
    if (roomNames != null && roomNames!.isNotEmpty) {
      final names = roomNames!.values.take(2).join(' + ');
      final remaining = roomNames!.length - 2;
      if (remaining > 0) {
        return '$names + $remaining more';
      }
      return names;
    }
    return '${originalScanIds.length} rooms stitched';
  }

  /// Generate thumbnail path (optional - for UI list view)
  String? get thumbnailPath {
    // Placeholder for thumbnail generation (future enhancement)
    return null;
  }

  // JSON serialization
  factory StitchedModel.fromJson(Map<String, dynamic> json) =>
      _$StitchedModelFromJson(json);
  Map<String, dynamic> toJson() => _$StitchedModelToJson(this);

  /// Create from RoomStitchJob and local file info
  factory StitchedModel.fromJob(
    RoomStitchJob job,
    String localPath,
    int fileSizeBytes,
    List<String> originalScanIds,
    Map<String, String>? roomNames,
  ) {
    return StitchedModel(
      id: job.jobId,
      localPath: localPath,
      originalScanIds: originalScanIds,
      roomNames: roomNames,
      fileSizeBytes: fileSizeBytes,
      createdAt: job.completedAt ?? DateTime.now(),
      format: 'glb',
    );
  }
}
```

**Validation Rules**:
- `localPath`: Must exist on filesystem (verified before instantiation)
- `originalScanIds`: Minimum 2 scans (inherited from RoomStitchRequest)
- `fileSizeBytes`: Typically 20-100 MB (2-5 rooms)

**Example Usage**:

```dart
// Create stitched model after successful job
final stitchedModel = StitchedModel.fromJob(
  completedJob,
  '/Documents/scans/stitched-living-room-master-bedroom-2025-01-01.glb',
  45_000_000, // 45 MB
  ['scan-001', 'scan-002'],
  {'scan-001': 'Living Room', 'scan-002': 'Master Bedroom'},
);

// Display in UI
print(stitchedModel.displayName); // "Living Room + Master Bedroom"

// With 4+ rooms
final largeModel = StitchedModel(
  id: 'job-002',
  localPath: '/Documents/scans/stitched-4-rooms-2025-01-01.glb',
  originalScanIds: ['scan-001', 'scan-002', 'scan-003', 'scan-004'],
  roomNames: {
    'scan-001': 'Living Room',
    'scan-002': 'Master Bedroom',
    'scan-003': 'Kitchen',
    'scan-004': 'Bathroom',
  },
  fileSizeBytes: 75_000_000,
  createdAt: DateTime.now(),
);

print(largeModel.displayName); // "Living Room + Master Bedroom + 2 more"
```

---

## Data Flow

### User Story 2: Room Stitching Flow

```text
1. USER INITIATES STITCHING
   ↓
   ScanListScreen: User selects 2+ scans from ScanSessionManager
   ↓
   RoomStitchingScreen: User confirms scan selection
   ↓
   Create RoomStitchRequest(projectId, scanIds, roomNames)
   ↓
   Validate: request.isValid() == true (minimum 2 scans)

2. INITIATE STITCHING JOB (GraphQL Mutation)
   ↓
   RoomStitchingService.startStitching(request)
   ↓
   GraphQL: mutation StitchRooms($input: StitchRoomsInput!)
   ↓
   Backend returns: RoomStitchJob(jobId, status=PENDING, estimatedDuration)
   ↓
   Navigate to RoomStitchProgressScreen(jobId)

3. POLL JOB STATUS (GraphQL Query)
   ↓
   RoomStitchingService.pollStitchStatus(jobId)
   ↓
   Loop every 2 seconds:
     GraphQL: query GetStitchJobStatus($jobId)
     Backend returns: RoomStitchJob(status, progress, resultUrl, errorMessage)
     ↓
     Update UI: Progress bar, status message
     ↓
     Check if terminal: isTerminal == true
     ↓
     Exit loop if terminal

4A. SUCCESS PATH (status == COMPLETED)
   ↓
   RoomStitchJob.resultUrl available (signed S3 URL)
   ↓
   Download GLB file: http.get(resultUrl)
   ↓
   Save to local storage: Documents/scans/stitched-*.glb
   ↓
   Create StitchedModel(jobId, localPath, originalScanIds, roomNames)
   ↓
   Navigate to StitchedModelPreviewScreen(stitchedModel)
   ↓
   USER ACTIONS: View in AR, Export, Save to Project

4B. FAILURE PATH (status == FAILED)
   ↓
   RoomStitchJob.errorMessage available
   ↓
   Display error dialog with user-friendly message:
     - INSUFFICIENT_OVERLAP → "Scan with more overlap between rooms"
     - ALIGNMENT_FAILURE → "Scans incompatible, try rescanning"
     - BACKEND_TIMEOUT → "Processing took too long, retry or split scans"
   ↓
   USER ACTIONS: Retry, Contact Support, Cancel
```

---

## Storage & Persistence

### In-Memory (Session-Only)

**ScanSessionManager** (existing):
- Manages `List<ScanData>` for current session
- Cleared on app restart or explicit session end
- No persistence to disk (architecture decision)

**New for Feature 016**:
- Room names stored in `ScanData.roomName` (in-memory only)
- Active `RoomStitchJob` tracked in RoomStitchingService state
- Cleared on navigation away from progress screen

### Local Filesystem

**Individual Scans** (existing):
- Path: `${appDocumentsDir}/scans/scan-{id}.{format}`
- Format: USDZ (from LiDAR) or GLB (from conversion)

**Stitched Models** (new):
- Path: `${appDocumentsDir}/scans/stitched-{roomNames}-{timestamp}.glb`
- Format: GLB only (USDZ optional future enhancement)
- Example: `/Documents/scans/stitched-living-room-master-bedroom-2025-01-01.glb`

**Lifecycle**:
- Files persist until manually deleted by user
- No automatic cleanup (user controls storage via Files app)

---

## Validation Summary

| Model | Validation Rules | Enforced By |
|-------|------------------|-------------|
| ScanData.roomName | Max 50 chars, alphanumeric + spaces + emojis | RoomNameValidator (UI) |
| RoomStitchRequest.scanIds | Minimum 2 scans | isValid() method |
| RoomStitchRequest.projectId | Valid UUID | GraphQL schema |
| RoomStitchJob.progress | 0-100 range | Backend |
| RoomStitchJob.resultUrl | Required if status == COMPLETED | Backend |
| RoomStitchJob.errorMessage | Required if status == FAILED | Backend |
| StitchedModel.originalScanIds | Minimum 2 scans | Inherited from request |
| StitchedModel.localPath | File exists on filesystem | Service layer |

---

## Testing Considerations

### Unit Tests

```dart
// test/models/room_stitch_request_test.dart
test('RoomStitchRequest validation requires minimum 2 scans', () {
  final request = RoomStitchRequest(
    projectId: 'proj-001',
    scanIds: ['scan-001'], // Only 1 scan
  );
  expect(request.isValid(), false);
});

test('RoomStitchRequest generates filename with room names', () {
  final request = RoomStitchRequest(
    projectId: 'proj-001',
    scanIds: ['scan-001', 'scan-002'],
    roomNames: {'scan-001': 'Living Room', 'scan-002': 'Kitchen'},
  );
  expect(request.generateFilename(), contains('living-room'));
  expect(request.generateFilename(), contains('kitchen'));
});

// test/models/room_stitch_job_test.dart
test('RoomStitchJob isTerminal returns true for completed status', () {
  final job = RoomStitchJob(
    jobId: 'job-001',
    status: RoomStitchJobStatus.completed,
    progress: 100,
    createdAt: DateTime.now(),
  );
  expect(job.isTerminal, true);
  expect(job.isSuccessful, true);
});

test('RoomStitchJob statusMessage returns user-friendly text', () {
  final job = RoomStitchJob(
    jobId: 'job-001',
    status: RoomStitchJobStatus.aligning,
    progress: 60,
    createdAt: DateTime.now(),
  );
  expect(job.statusMessage, 'Aligning rooms...');
});

// test/models/stitched_model_test.dart
test('StitchedModel displayName shows room names', () {
  final model = StitchedModel(
    id: 'job-001',
    localPath: '/path/to/stitched.glb',
    originalScanIds: ['scan-001', 'scan-002'],
    roomNames: {'scan-001': 'Living Room', 'scan-002': 'Kitchen'},
    fileSizeBytes: 45_000_000,
    createdAt: DateTime.now(),
  );
  expect(model.displayName, 'Living Room + Kitchen');
});
```

### Integration Tests

```dart
// integration_test/stitching_flow_test.dart
testWidgets('Complete stitching flow from scan selection to preview', (tester) async {
  // 1. Setup: Create 2 scans in session
  final sessionManager = ScanSessionManager();
  sessionManager.addScan(scan1);
  sessionManager.addScan(scan2);

  // 2. Navigate to scan list
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Scans'));
  await tester.pumpAndSettle();

  // 3. Initiate stitching (mock GraphQL response)
  await tester.tap(find.text('Room stitching'));
  await tester.pumpAndSettle();

  // 4. Select scans
  await tester.tap(find.byType(Checkbox).first);
  await tester.tap(find.byType(Checkbox).last);
  await tester.tap(find.text('Start Stitching'));
  await tester.pumpAndSettle();

  // 5. Verify progress screen appears
  expect(find.byType(RoomStitchProgressScreen), findsOneWidget);

  // 6. Wait for completion (mock polling)
  await tester.pumpAndSettle(Duration(seconds: 3));

  // 7. Verify preview screen
  expect(find.byType(StitchedModelPreviewScreen), findsOneWidget);
});
```

---

## Migration Notes

### Existing Code Changes

**ScanData Model** (lib/features/scanning/models/scan_data.dart):
1. Add `roomName` field to class definition
2. Add `roomName` parameter to constructor
3. Add `roomName` parameter to copyWith() method
4. Add `roomNameOrDefault()` getter method
5. Regenerate JSON serialization: `flutter pub run build_runner build`

**ScanSessionManager** (lib/features/scanning/services/scan_session_manager.dart):
- No changes required (List<ScanData> already supports extended ScanData)

### New Files to Create

1. `lib/features/scanning/models/room_stitch_request.dart`
2. `lib/features/scanning/models/room_stitch_job.dart`
3. `lib/features/scanning/models/stitched_model.dart`
4. `lib/features/scanning/utils/room_name_validator.dart`
5. `lib/features/scanning/utils/filename_sanitizer.dart`

---

## Next Steps

1. Generate JSON serialization for new models: `flutter pub run build_runner build`
2. Create GraphQL queries/mutations in `contracts/room-stitching-api.graphql`
3. Implement RoomStitchingService with polling logic
4. Build UI screens: RoomStitchingScreen, RoomStitchProgressScreen, StitchedModelPreviewScreen
5. Write unit tests for all models (TDD - tests before implementation)
