# Research: Combined Scan to NavMesh Workflow

**Feature**: 018-combined-scan-navmesh
**Date**: 2026-01-04
**Status**: Complete

## Overview

This document consolidates research findings and architectural decisions for the Combined Scan to NavMesh feature. All technical decisions have been made based on the comprehensive feature specification and existing codebase analysis.

## Key Decisions

### Decision 1: Single Combined File Architecture

**Decision**: Create ONE combined USDZ file on-device containing all positioned scans, rather than sending multiple files to the backend.

**Rationale**:
- **Simplicity**: Single file upload simplifies the entire workflow
- **Privacy**: All scan combination happens on-device, no cloud processing of individual scans
- **Reuse**: Can use existing `uploadProjectScan` mutation without modification
- **Performance**: Single upload is more efficient than multiple sequential uploads
- **Backend Simplicity**: Backend receives one file and processes it normally

**Alternatives Considered**:
1. **Upload multiple files separately**: Rejected because it would require new backend endpoints, more complex state management, and slower overall process
2. **Cloud-based combination**: Rejected due to privacy concerns and increased backend complexity
3. **Real-time stitching**: Rejected because it would require WebSocket connection and streaming protocols

**Technical Approach**:
- Use iOS SceneKit to load multiple USDZ files
- Apply saved transforms (position, rotation, scale) to each scan's scene graph
- Merge all transformed scenes into single unified scene
- Export as single USDZ file for upload

---

### Decision 2: Reuse Existing Upload Infrastructure

**Decision**: Leverage existing `ScanUploadService` and `uploadProjectScan` GraphQL mutation instead of creating new upload mechanisms.

**Rationale**:
- **YAGNI Principle**: Existing service already handles multipart upload, progress tracking, and error handling
- **Consistency**: Same upload behavior as individual scans
- **Maintenance**: Single code path for all scan uploads reduces bugs
- **Testing**: Existing upload flow already tested and proven
- **Backend Ready**: No backend changes required for upload/conversion

**Alternatives Considered**:
1. **New dedicated upload service**: Rejected because it would duplicate existing functionality
2. **REST API endpoint**: Rejected because GraphQL mutation already exists and works well
3. **Direct S3 upload**: Rejected because it bypasses existing auth and tracking mechanisms

**Implementation**:
```dart
// Reuse existing service
final result = await ScanUploadService().uploadScan(
  scanData: combinedScanData,
  projectId: projectId,
  onProgress: (progress) => updateUI(progress),
);
```

---

### Decision 3: iOS SceneKit for USDZ Combination

**Decision**: Use Apple's SceneKit framework (native Swift code) for combining USDZ files rather than third-party libraries or custom parsers.

**Rationale**:
- **Platform Native**: SceneKit is Apple's official framework for 3D scene manipulation
- **Performance**: Optimized native code, hardware-accelerated
- **Reliability**: Handles USDZ format correctly, including all metadata
- **Maintained**: Apple maintains SceneKit, guaranteed iOS compatibility
- **Zero Dependencies**: Built into iOS, no external packages needed
- **Transform Support**: Built-in support for affine transformations (position, rotation, scale)

**Alternatives Considered**:
1. **Third-party USDZ library**: Rejected because no mature Flutter package exists for USDZ manipulation
2. **Manual USD file parsing**: Rejected due to complexity and error-prone implementation
3. **WebAssembly USD tools**: Rejected due to performance concerns and bundle size

**Technical Implementation**:
```swift
// Load USDZ scenes
let scene1 = SCNScene(named: path1)
let scene2 = SCNScene(named: path2)

// Apply transforms
scene1.rootNode.position = SCNVector3(x: posX, y: 0, z: posY)
scene1.rootNode.eulerAngles.y = rotationRadians
scene1.rootNode.scale = SCNVector3(scale, scale, scale)

// Combine scenes
let combinedScene = SCNScene()
combinedScene.rootNode.addChildNode(scene1.rootNode)
combinedScene.rootNode.addChildNode(scene2.rootNode)

// Export as USDZ
combinedScene.write(to: outputURL, format: .usdz)
```

---

### Decision 4: Reuse Existing BlenderAPI REST Service

**Decision**: Use the existing BlenderAPI microservice for navmesh generation instead of adding new GraphQL mutations. BlenderAPI already provides a complete session-based workflow for GLB processing and navmesh generation.

**Rationale**:
- **Already Exists**: BlenderAPI microservice already implements navmesh generation with full workflow
- **Zero Backend Changes**: No new mutations, no new database tables, no new code
- **Battle-Tested**: Already deployed and tested (stage: `https://blenderapi.stage.motorenflug.at`)
- **Session-Based**: Temporary processing with automatic cleanup (5-minute TTL)
- **Production Ready**: Includes health checks, error handling, progress tracking, file download
- **Performance**: Optimized for GLB processing with Blender/Unity NavMesh baker

**Alternatives Considered**:
1. **New GraphQL mutations**: Rejected because blenderapi already exists and works perfectly
2. **WebSocket streaming**: Not needed - blenderapi already supports polling
3. **Embed in scan service**: Rejected because navmesh is separate concern, better as microservice

**BlenderAPI Workflow** (existing REST endpoints):
```bash
# 1. Create session
POST /sessions
  Headers: X-API-Key, X-Device-ID, X-Platform, X-OS-Version, X-App-Version, X-Device-Model
  Response: { "session_id": "sess_xxx..." }

# 2. Upload GLB file
POST /sessions/{session_id}/upload
  Headers: X-API-Key, X-Asset-Type: model/gltf-binary, X-Filename, Content-Type: application/octet-stream
  Body: <binary GLB data>
  Response: { "upload_status": "success" }

# 3. Start navmesh generation
POST /sessions/{session_id}/navmesh
  Headers: X-API-Key, Content-Type: application/json
  Body: {
    "job_type": "navmesh_generation",
    "input_filename": "combined.glb",
    "output_filename": "navmesh_combined.glb",
    "navmesh_params": {
      "cell_size": 0.3,
      "cell_height": 0.2,
      "agent_height": 2.0,
      "agent_radius": 0.6,
      "agent_max_climb": 0.9,
      "agent_max_slope": 45.0
    }
  }
  Response: { "status": "processing" }

# 4. Poll status (every 2 seconds)
GET /sessions/{session_id}/status
  Headers: X-API-Key
  Response: {
    "session_status": "completed|processing|failed",
    "progress": 85,
    "result": {
      "filename": "navmesh_combined.glb",
      "size_bytes": 1234567,
      "polygon_count": 5000
    }
  }

# 5. Download result
GET /sessions/{session_id}/download/{filename}
  Headers: X-API-Key
  Response: <binary GLB file>

# 6. Delete session (cleanup)
DELETE /sessions/{session_id}
  Headers: X-API-Key
  Response: 202 Accepted (cleanup within 5 minutes)
```

**Integration Point**:
- Mobile app will call blenderapi directly (not through main GraphQL API)
- API Key: Use existing device authentication headers
- Base URL: `https://blenderapi.stage.motorenflug.at` (stage) or production URL
- Session management: Create → Process → Download → Delete
- Error handling: Existing error codes and messages from blenderapi

---

### Decision 5: SharedPreferences for Metadata Persistence

**Decision**: Use SharedPreferences for storing `CombinedScan` metadata rather than SQLite or other databases.

**Rationale**:
- **Consistency**: Existing `ScanData` already uses SharedPreferences
- **Simplicity**: JSON serialization is straightforward for this data model
- **Performance**: Fast read/write for small amounts of metadata
- **No Migration Needed**: Avoids database schema complexity
- **Sufficient Scale**: Expected max 10-20 combined scans per user

**Alternatives Considered**:
1. **SQLite/sqflite**: Rejected as over-engineered for simple metadata storage
2. **Hive**: Rejected because SharedPreferences already used throughout app
3. **Backend-only storage**: Rejected because offline support required

**Data Model**:
```dart
class CombinedScan {
  final String id;
  final String projectId;
  final List<String> scanIds;
  final String localCombinedPath;
  final String? combinedGlbUrl;
  final String? navmeshUrl;
  final String? localNavmeshPath;
  final CombinedScanStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  // JSON serialization
  Map<String, dynamic> toJson() => {...};
  factory CombinedScan.fromJson(Map<String, dynamic> json) => {...};
}
```

---

### Decision 6: Flutter MethodChannel for Native Bridge

**Decision**: Use Flutter's MethodChannel to communicate between Dart and iOS native code for USDZ combination.

**Rationale**:
- **Standard Pattern**: MethodChannel is Flutter's official platform integration mechanism
- **Async Support**: Handles async operations correctly with Future-based API
- **Error Handling**: Proper exception propagation from native to Dart
- **Type Safety**: Can pass structured data (Maps) with defined types
- **Debugging**: Well-supported in Flutter DevTools

**Alternatives Considered**:
1. **EventChannel**: Rejected because we don't need streaming updates during combination
2. **FFI (Foreign Function Interface)**: Rejected because MethodChannel is simpler for this use case
3. **Platform Views**: Not applicable (no UI component, just data processing)

**Implementation**:
```dart
// Dart side
class USDZCombinerService {
  static const platform = MethodChannel('com.vron.usdz_combiner');

  Future<String> combineScans(List<ScanData> scans) async {
    final result = await platform.invokeMethod('combineScans', {
      'paths': scans.map((s) => s.localPath).toList(),
      'transforms': scans.map((s) => {
        'positionX': s.positionX ?? 0.0,
        'positionY': s.positionY ?? 0.0,
        'rotation': s.rotationDegrees ?? 0.0,
        'scale': s.scaleFactor ?? 1.0,
      }).toList(),
    });
    return result as String;
  }
}

// Swift side
class USDZCombinerPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.vron.usdz_combiner",
      binaryMessenger: registrar.messenger()
    )
    let instance = USDZCombinerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "combineScans":
      handleCombineScans(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

---

### Decision 7: State Management via Service Layer

**Decision**: Use service layer pattern with direct state updates in UI (StatefulWidget) rather than Provider/Bloc.

**Rationale**:
- **Consistency**: Matches existing scanning feature architecture
- **Simplicity**: No global state needed - combine operation is screen-scoped
- **YAGNI**: Avoid state management complexity for single-screen feature
- **Sufficient**: Service layer provides clear separation of concerns

**Alternatives Considered**:
1. **Provider**: Rejected as over-engineered for localized state
2. **Bloc**: Rejected because it adds unnecessary complexity
3. **Riverpod**: Not used elsewhere in codebase, would be inconsistent

**Architecture**:
```
UI Layer (StatefulWidget)
    ↓ calls
Service Layer (CombinedScanService)
    ↓ orchestrates
- USDZCombinerService (native bridge)
- ScanUploadService (existing)
- CombinedScanApiClient (GraphQL)
```

---

## Performance Considerations

### USDZ Combination Performance
- **Expected Time**: 5-10 seconds for 3 scans (~5MB each)
- **Bottleneck**: SceneKit scene graph operations (CPU-bound)
- **Optimization**: Process on background thread to keep UI responsive
- **Memory**: Load scenes sequentially if memory constrained

### Upload Performance
- **File Size**: 10-50MB typical (2-10 rooms combined)
- **Upload Time**: 20-30 seconds on WiFi, 60-90 seconds on cellular
- **Optimization**: Use existing multipart upload with chunking
- **Progress**: Real-time progress updates every 1% increment

### Backend Processing
- **GLB Conversion**: 30-60 seconds (existing pipeline)
- **NavMesh Generation**: 60-90 seconds (Unity NavMesh baker)
- **Polling Interval**: 2 seconds (matches existing pattern)

---

## Security Considerations

### Data Privacy
- ✅ All scan combination happens on-device
- ✅ No intermediate uploads of individual scans
- ✅ Combined USDZ treated same as individual scan (existing security)
- ✅ HTTPS for all API communication (existing)
- ✅ Secure token management (existing)

### File Storage
- ✅ Combined USDZ stored in app documents directory (sandboxed)
- ✅ Temporary files cleaned up after successful upload
- ✅ Local files deleted when user deletes combined scan

---

## Testing Strategy

### Unit Tests
- `USDZCombinerService`: Mock MethodChannel, verify transforms passed correctly
- `CombinedScanService`: Mock dependencies, test state transitions
- `CombinedScan` model: Test JSON serialization/deserialization
- iOS `USDZCombiner`: XCTest for scene combination logic

### Widget Tests
- `CombineProgressDialog`: Test all status states display correctly
- `ExportCombinedDialog`: Test file size display and button states
- Combine button: Test enabled/disabled states based on scan count

### Integration Tests
- Full flow: Arrange → Combine → Upload → GLB ready → Generate NavMesh → Download
- Error scenarios: Network failure, backend error, insufficient storage
- Cancellation: User cancels during upload, verify cleanup

---

## Open Questions

**None**. All technical decisions have been made and documented in the specification.

---

## References

- Feature Specification: `specs/018-combined-scan-navmesh/spec.md`
- Apple SceneKit Documentation: https://developer.apple.com/documentation/scenekit
- USD (Universal Scene Description) Format: https://openusd.org/
- Existing ScanUploadService: `lib/features/scanning/services/scan_upload_service.dart`
- Flutter MethodChannel: https://docs.flutter.dev/platform-integration/platform-channels
