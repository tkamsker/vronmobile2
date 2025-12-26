# Data Model: LiDAR Scanning

**Feature**: `014-lidar-scanning`
**Date**: 2025-12-25
**Status**: Phase 1 Design

## Overview

This document defines the data model for LiDAR scanning feature, including local scan file management, device capability detection, and USDZ→GLB conversion results. The model integrates with the existing Project entity on the backend via GraphQL API.

---

## Entities

### 1. ScanData

Represents a 3D room scan file (USDZ or GLB) with associated metadata. Stored locally on device and optionally uploaded to backend when saved to project.

**Dart Model** (`lib/features/scanning/models/scan_data.dart`):

```dart
enum ScanFormat {
  usdz, // Apple RoomPlan native output
  glb,  // glTF binary format
}

enum ScanStatus {
  capturing,    // Scan in progress
  completed,    // Scan finished, stored locally
  uploading,    // Upload to backend in progress
  uploaded,     // Successfully uploaded to backend
  failed,       // Scan or upload failed
}

class ScanData {
  final String id;              // Unique identifier (UUID)
  final ScanFormat format;      // USDZ or GLB
  final String localPath;       // Local filesystem path
  final int fileSizeBytes;      // File size in bytes
  final DateTime capturedAt;    // Timestamp of scan completion
  final ScanStatus status;      // Current status
  final String? projectId;      // Associated project (null for guest scans)
  final String? remoteUrl;      // Backend URL after upload (null if not uploaded)
  final Map<String, dynamic>? metadata; // Additional metadata (room dimensions, object count, etc.)

  ScanData({
    required this.id,
    required this.format,
    required this.localPath,
    required this.fileSizeBytes,
    required this.capturedAt,
    required this.status,
    this.projectId,
    this.remoteUrl,
    this.metadata,
  });

  // JSON serialization for local storage (shared_preferences)
  factory ScanData.fromJson(Map<String, dynamic> json) {
    return ScanData(
      id: json['id'] as String,
      format: ScanFormat.values.byName(json['format'] as String),
      localPath: json['localPath'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      status: ScanStatus.values.byName(json['status'] as String),
      projectId: json['projectId'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format.name,
      'localPath': localPath,
      'fileSizeBytes': fileSizeBytes,
      'capturedAt': capturedAt.toIso8601String(),
      'status': status.name,
      'projectId': projectId,
      'remoteUrl': remoteUrl,
      'metadata': metadata,
    };
  }

  // Helper: Check if file exists on device
  Future<bool> existsLocally() async {
    final file = File(localPath);
    return await file.exists();
  }

  // Helper: Delete local file
  Future<void> deleteLocally() async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Helper: Get file as bytes for upload
  Future<List<int>> readBytes() async {
    final file = File(localPath);
    return await file.readAsBytes();
  }
}
```

**Validation Rules**:
- `id`: Must be unique UUID
- `format`: Only USDZ or GLB
- `localPath`: Must be absolute path to existing file
- `fileSizeBytes`: Must match actual file size, max 250 MB (262,144,000 bytes)
- `status`: State machine transitions (capturing → completed → uploading → uploaded)
- `projectId`: Required for authenticated users when uploading, null for guest mode
- `remoteUrl`: Populated only after successful backend upload

**State Transitions**:
```
capturing → completed (scan finished)
completed → uploading (user initiates save to project)
uploading → uploaded (backend confirms)
uploading → failed (network error or backend rejection)
```

**Metadata Fields** (optional, from RoomPlan):
```dart
{
  "wallCount": 4,
  "doorCount": 1,
  "windowCount": 2,
  "objectCount": 12,
  "roomDimensions": {
    "width": 5.2,
    "height": 2.8,
    "depth": 4.1
  },
  "roomType": "bedroom", // If detected by RoomPlan
  "captureDevice": "iPhone 14 Pro",
  "iosVersion": "16.5"
}
```

---

### 2. LidarCapability

Represents device LiDAR capability information for runtime checks and error messaging.

**Dart Model** (`lib/features/scanning/models/lidar_capability.dart`):

```dart
enum LidarSupport {
  supported,      // Device has LiDAR and iOS 16.0+
  noLidar,        // Device lacks LiDAR hardware
  oldIOS,         // iOS version < 16.0
  notApplicable,  // Android device
}

class LidarCapability {
  final LidarSupport support;
  final String deviceModel;
  final String osVersion;
  final bool isMultiRoomSupported; // iOS 17.0+ for multi-room merge
  final String? unsupportedReason; // Human-readable message for unsupported devices

  LidarCapability({
    required this.support,
    required this.deviceModel,
    required this.osVersion,
    required this.isMultiRoomSupported,
    this.unsupportedReason,
  });

  // Factory: Detect capability at runtime
  static Future<LidarCapability> detect() async {
    if (Platform.isAndroid) {
      return LidarCapability(
        support: LidarSupport.notApplicable,
        deviceModel: await _getDeviceModel(),
        osVersion: await _getOSVersion(),
        isMultiRoomSupported: false,
        unsupportedReason: 'LiDAR scanning is not available on Android devices. You can upload GLB files instead.',
      );
    }

    // iOS: Check via platform channel
    final isSupported = await _checkIOSLidarSupport();
    final osVersion = await _getOSVersion();
    final isMultiRoom = _isIOSVersionAtLeast(osVersion, '17.0');

    if (!isSupported) {
      return LidarCapability(
        support: LidarSupport.noLidar,
        deviceModel: await _getDeviceModel(),
        osVersion: osVersion,
        isMultiRoomSupported: false,
        unsupportedReason: 'Your device does not have a LiDAR scanner. LiDAR is available on iPhone 12 Pro and newer Pro models.',
      );
    }

    if (_isIOSVersionAtLeast(osVersion, '16.0') == false) {
      return LidarCapability(
        support: LidarSupport.oldIOS,
        deviceModel: await _getDeviceModel(),
        osVersion: osVersion,
        isMultiRoomSupported: false,
        unsupportedReason: 'LiDAR scanning requires iOS 16.0 or later. Please update your device.',
      );
    }

    return LidarCapability(
      support: LidarSupport.supported,
      deviceModel: await _getDeviceModel(),
      osVersion: osVersion,
      isMultiRoomSupported: isMultiRoom,
    );
  }

  bool get isScanningSupportpported => support == LidarSupport.supported;

  // Helper methods (implementations omitted for brevity)
  static Future<bool> _checkIOSLidarSupport() async { /* Platform channel call */ }
  static Future<String> _getDeviceModel() async { /* Device info */ }
  static Future<String> _getOSVersion() async { /* OS version */ }
  static bool _isIOSVersionAtLeast(String version, String target) { /* Version comparison */ }
}
```

**Validation Rules**:
- `support`: Determined by device hardware and OS version
- `deviceModel`: Non-empty string (e.g., "iPhone 14 Pro", "Pixel 7")
- `osVersion`: Non-empty string (e.g., "16.5", "Android 13")
- `isMultiRoomSupported`: True only if iOS 17.0+ on supported device
- `unsupportedReason`: Required if `support != supported`

**Supported Device Models** (iOS):
- iPhone 12 Pro, 12 Pro Max
- iPhone 13 Pro, 13 Pro Max
- iPhone 14 Pro, 14 Pro Max
- iPhone 15 Pro, 15 Pro Max
- iPad Pro (2020 or later with LiDAR)

---

### 3. ConversionResult

Represents the result of USDZ→GLB conversion (User Story 3). Includes success/failure status, output file path, error details, and conversion statistics.

**Dart Model** (`lib/features/scanning/models/conversion_result.dart`):

```dart
enum ConversionStatus {
  pending,      // Conversion queued
  inProgress,   // Conversion running
  completed,    // Conversion successful
  failed,       // Conversion failed
}

enum ConversionErrorCode {
  unsupportedPrim,  // USDZ contains geometry types not supported in glTF (NURBS, volumes)
  missingTexture,   // Referenced texture file not found in USDZ bundle
  readError,        // Cannot read USDZ file (corrupted, access denied)
  memoryExceeded,   // Conversion requires more than 512 MB RAM
  timeout,          // Conversion exceeds 30 second timeout
  networkError,     // Server-side conversion network failure
  serverError,      // Backend conversion service error
}

class ConversionStats {
  final int triangleCount;
  final int meshCount;
  final Duration duration;
  final int outputFileSizeBytes;

  ConversionStats({
    required this.triangleCount,
    required this.meshCount,
    required this.duration,
    required this.outputFileSizeBytes,
  });

  factory ConversionStats.fromJson(Map<String, dynamic> json) {
    return ConversionStats(
      triangleCount: json['triangleCount'] as int,
      meshCount: json['meshCount'] as int,
      duration: Duration(milliseconds: json['durationMs'] as int),
      outputFileSizeBytes: json['outputFileSizeBytes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'triangleCount': triangleCount,
      'meshCount': meshCount,
      'durationMs': duration.inMilliseconds,
      'outputFileSizeBytes': outputFileSizeBytes,
    };
  }
}

class ConversionResult {
  final ConversionStatus status;
  final String? glbPath;          // Local path to converted GLB (if on-device) or remote URL (if server-side)
  final ConversionErrorCode? errorCode;
  final String? errorMessage;     // Human-readable error description
  final ConversionStats? stats;   // Conversion statistics (null if failed)
  final DateTime timestamp;       // Conversion completion time

  ConversionResult({
    required this.status,
    this.glbPath,
    this.errorCode,
    this.errorMessage,
    this.stats,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ConversionResult.success({
    required String glbPath,
    required ConversionStats stats,
  }) {
    return ConversionResult(
      status: ConversionStatus.completed,
      glbPath: glbPath,
      stats: stats,
    );
  }

  factory ConversionResult.failure({
    required ConversionErrorCode errorCode,
    required String errorMessage,
  }) {
    return ConversionResult(
      status: ConversionStatus.failed,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  bool get isSuccess => status == ConversionStatus.completed;
  bool get isFailed => status == ConversionStatus.failed;

  factory ConversionResult.fromJson(Map<String, dynamic> json) {
    return ConversionResult(
      status: ConversionStatus.values.byName(json['status'] as String),
      glbPath: json['glbPath'] as String?,
      errorCode: json['errorCode'] != null
          ? ConversionErrorCode.values.byName(json['errorCode'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      stats: json['stats'] != null
          ? ConversionStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'glbPath': glbPath,
      'errorCode': errorCode?.name,
      'errorMessage': errorMessage,
      'stats': stats?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

**Validation Rules**:
- `status`: Required state indicator
- `glbPath`: Required if status == completed, null otherwise
- `errorCode`: Required if status == failed, null otherwise
- `errorMessage`: Required if status == failed, null otherwise
- `stats`: Required if status == completed, null otherwise
- `stats.triangleCount`: Typical room ≤200k triangles
- `stats.duration`: Target <10 seconds for on-device, 5-30 seconds for server-side
- `stats.outputFileSizeBytes`: Must be ≤250 MB (262,144,000 bytes)

**Error Handling Mapping**:
```dart
String getUserFriendlyMessage(ConversionErrorCode code) {
  switch (code) {
    case ConversionErrorCode.unsupportedPrim:
      return 'This scan contains complex geometry that cannot be converted. Please try scanning a simpler room.';
    case ConversionErrorCode.missingTexture:
      return 'Scan data is incomplete. Please try scanning again with better lighting.';
    case ConversionErrorCode.readError:
      return 'Cannot read scan file. The file may be corrupted.';
    case ConversionErrorCode.memoryExceeded:
      return 'Scan is too complex to convert on this device. Try a smaller room or restart your device.';
    case ConversionErrorCode.timeout:
      return 'Conversion timed out. The scan may be too complex.';
    case ConversionErrorCode.networkError:
      return 'Network error during conversion. Please check your connection and try again.';
    case ConversionErrorCode.serverError:
      return 'Conversion service temporarily unavailable. Please try again later.';
  }
}
```

---

## Relationships

### ScanData ↔ Project (Backend)

**Relationship**: Many-to-one (many scans can belong to one project)

**GraphQL Schema** (backend):
```graphql
type Project {
  id: ID!
  name: String!
  scans: [Scan!]!
  # ... other fields
}

type Scan {
  id: ID!
  projectId: ID!
  format: ScanFormat!
  usdzUrl: String
  glbUrl: String
  fileSizeBytes: Int!
  capturedAt: DateTime!
  metadata: JSON
  # ... other fields
}

enum ScanFormat {
  USDZ
  GLB
}
```

**Mobile App Storage**:
- ScanData stored locally in app Documents directory
- Metadata stored in shared_preferences (JSON array)
- Backend relationship established only when user saves to project (UC20)

**Synchronization**:
- Local scans persist until explicitly deleted or uploaded
- After upload, local file can be optionally retained for offline access
- Backend scans can be downloaded for offline viewing (future enhancement)

---

## Storage Strategy

### Local Storage (Mobile App)

**USDZ Files**:
- Location: `getApplicationDocumentsDirectory()/scans/`
- Naming: `scan_{uuid}.usdz`
- Persistence: Until user deletes or app uninstalled
- Backup: Included in iOS iCloud backup

**GLB Files**:
- Location: `getApplicationCacheDirectory()/glb/`
- Naming: `converted_{uuid}.glb`
- Persistence: Until cache cleared or app uninstalled
- Backup: Not included in iOS iCloud backup (cache directory)

**Metadata**:
- Location: SharedPreferences (`scan_data_list` key)
- Format: JSON array of ScanData objects
- Size limit: ~1 MB (approximately 100 scans with metadata)

### Backend Storage (PostgreSQL)

**Scans Table** (assumed schema):
```sql
CREATE TABLE scans (
  id UUID PRIMARY KEY,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  format VARCHAR(10) NOT NULL,
  usdz_url TEXT,
  glb_url TEXT,
  file_size_bytes INTEGER NOT NULL,
  captured_at TIMESTAMP NOT NULL,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_scans_project_id ON scans(project_id);
```

**File Storage**:
- S3 bucket (or equivalent cloud storage)
- USDZ files: `projects/{projectId}/scans/{scanId}.usdz`
- GLB files: `projects/{projectId}/scans/{scanId}.glb`
- Signed URLs for download (time-limited access)

---

## Data Flow Diagrams

### Flow 1: LiDAR Scan → Local Storage (US1)

```
1. User taps "Start Scanning"
2. ScanningService.startScan()
   → Platform channel → RoomPlanBridge (iOS)
3. RoomPlan captures room
   → Progress updates via EventChannel
4. Scan completes → USDZ exported to Documents directory
5. ScanData entity created with:
   - id: UUID
   - format: USDZ
   - localPath: /Documents/scans/scan_{uuid}.usdz
   - status: completed
6. ScanData saved to SharedPreferences
7. UI shows "Scan Complete" with preview option
```

### Flow 2: Save Scan to Project (Backend Upload)

```
1. User selects "Save to Project"
2. ProjectService.uploadScan(scanId, projectId)
   → Update ScanData status to 'uploading'
3. GraphQL mutation uploadProjectScan(usdzFile, projectId)
4. Backend receives USDZ file
   → Stores in S3: projects/{projectId}/scans/{scanId}.usdz
   → Triggers USDZ→GLB conversion (Sirv API or Lambda)
5. Backend returns:
   - usdzUrl: S3 signed URL
   - glbUrl: S3 signed URL (after conversion)
   - scanId: Backend UUID
6. Update local ScanData:
   - status: uploaded
   - remoteUrl: usdzUrl
   - projectId: projectId
7. UI shows "Scan saved to project" confirmation
```

### Flow 3: GLB File Upload (US2 - Android/iOS)

```
1. User taps "Upload GLB"
2. FilePicker.platform.pickFiles(type: FileType.any)
3. User selects .glb file from device storage
4. Validate:
   - Extension == 'glb'
   - File size ≤ 250 MB
5. If valid:
   - Create ScanData entity (format: GLB, status: completed)
   - Copy file to app Documents directory
   - Save ScanData to SharedPreferences
6. User can now save to project (same as Flow 2)
```

### Flow 4: USDZ→GLB Conversion (US3 - Server-Side)

```
1. User initiates save to project (Flow 2)
2. Backend receives USDZ file
3. Backend triggers conversion service:
   Option A (Sirv API):
     - POST USDZ to Sirv conversion endpoint
     - Sirv returns GLB file or error
     - Duration: 5-30 seconds
   Option B (AWS Lambda):
     - Upload USDZ to S3 input bucket
     - EventBridge triggers Lambda with usd2gltf container
     - Lambda converts and stores GLB in S3 output bucket
     - Duration: 5-30 seconds
4. Backend stores GLB URL in scans table
5. GraphQL mutation returns both usdzUrl and glbUrl
6. Mobile app updates ScanData with glbUrl for future preview
```

---

## Validation & Constraints

### File Size Constraints
- **USDZ files**: Typical 5-50 MB, max 250 MB (enforced at backend)
- **GLB files**: Similar to USDZ, max 250 MB (enforced at upload)
- **Total local storage**: Monitor device storage, warn if <500 MB free

### Performance Constraints
- **Scan duration**: Typical 1-5 minutes per room
- **USDZ export**: <5 seconds (RoomPlan native)
- **GLB conversion**: 5-30 seconds server-side, target <10 seconds on-device (if implemented)
- **File I/O**: USDZ read/write <2 seconds for typical 20 MB file

### Data Integrity
- **UUID uniqueness**: All ScanData IDs must be unique
- **File existence**: Validate local file exists before upload
- **Status consistency**: Status transitions follow state machine rules
- **Metadata accuracy**: RoomPlan metadata should match actual scan content

---

## Testing Considerations

### Unit Tests
- ScanData JSON serialization/deserialization
- LidarCapability device detection logic
- ConversionResult error code mapping
- File size validation
- Status state machine transitions

### Integration Tests
- Complete scan workflow (start → capture → store)
- GLB file picker workflow
- Upload workflow (local → backend)
- Conversion result handling (success and failure cases)

### Edge Cases
- Scan interrupted mid-capture (phone call, backgrounding)
- Device storage full during USDZ export
- Network failure during upload (retry logic)
- Backend conversion timeout (fallback messaging)
- Corrupted USDZ file (validation before upload)
- File size exceeds 250 MB (reject with clear message)

---

## Future Enhancements

1. **Offline sync**: Queue uploads when offline, sync when reconnected
2. **Scan compression**: Compress USDZ files before upload to reduce bandwidth
3. **Progressive upload**: Stream large files with progress indication
4. **Backend download**: Download backend scans for offline viewing
5. **Scan versioning**: Multiple versions of same room scan (before/after renovations)
6. **Scan merging**: Combine multiple room scans into one building model (iOS 17.0+)

---

## References

- [Spec: User Story 1 (Start Scan)](./spec.md#user-story-1---start-scan-priority-p1)
- [Spec: User Story 2 (Upload GLB)](./spec.md#user-story-2---upload-glb-priority-p2)
- [Spec: User Story 3 (On-Device Conversion)](./spec.md#user-story-3---on-device-usdzglb-conversion-priority-p2)
- [Research: USDZ→GLB Conversion Strategy](./research.md#decision-3-usdzglb-conversion-strategy)
- [Contracts: GraphQL API](./contracts/graphql-api.md)
