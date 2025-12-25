# Research: LiDAR Scanning

**Date**: 2025-12-25
**Feature**: `014-lidar-scanning`
**Status**: Phase 0 Complete

## Summary

This research phase resolves all NEEDS CLARIFICATION items from the Technical Context and evaluates implementation approaches for LiDAR-based room scanning with USDZ→GLB conversion. Key decisions include package selections (flutter_roomplan, file_picker, path_provider), USDZ→GLB conversion strategy (hybrid server-side first approach), and RoomPlan integration patterns (MethodChannel + EventChannel).

---

## Decision 1: Flutter RoomPlan Package

### Decision
Use **flutter_roomplan v1.0.7** for LiDAR scanning integration.

### Rationale
- **Most mature**: v1.0.7 indicates stable, production-ready API
- **Feature-complete**: Supports both single-room (iOS 16.0+) and multi-room merge (iOS 17.0+)
- **Dual export formats**: Returns both USDZ (3D model) and JSON (structured room data)
- **Simple API**: `isSupported()`, `startScan()`, `onRoomCaptureFinished()`, `getUsdzFilePath()`
- **Active maintenance**: Last updated August 2024 (3 months ago)

### Alternatives Considered
- **roomplan_flutter v0.1.4**:
  - More recently updated (November 2024)
  - Offers real-time scan updates via Stream
  - More granular error handling (20+ exception types)
  - **Rejected**: Less feature-rich (no multi-room support), lower version number suggests less maturity

- **roomplan_launcher**:
  - Launches native iOS RoomPlan scanner
  - Returns structured JSON only
  - **Rejected**: Limited control over scan workflow, no USDZ export API

- **Custom platform channel implementation**:
  - Full control over RoomPlan API integration
  - **Rejected**: Reinventing wheel, flutter_roomplan already provides solid abstraction

### Implementation Notes
- Add to pubspec.yaml: `flutter_roomplan: ^1.0.7`
- iOS 16.0+ minimum (already specified in platform constraints)
- LiDAR hardware required (iPhone 12 Pro+, iPad Pro 2020+)
- Known limitations: overheating on long scans (5+ minutes), lighting-dependent, 16 object types only

---

## Decision 2: File Handling Packages

### Decision
Use **file_picker v10.3.8** for GLB file selection and **path_provider v2.1.5** for local USDZ storage.

### Rationale

**file_picker v10.3.8**:
- **Latest stable version**: Published December 2025
- **Cross-platform**: iOS, Android, Web, Desktop (supports both iOS scanning and Android upload-only)
- **Custom format support**: GLB files via `FileType.any` with manual extension validation
- **Cloud integration**: Supports iCloud Drive, Google Drive, Dropbox
- **Manual file size validation**: Required for 250 MB limit enforcement

**path_provider v2.1.5**:
- **Latest stable version**: Published October 2024
- **Compatible with Dart 3.10+**: Matches project SDK constraints
- **iOS directories**:
  - `getApplicationDocumentsDirectory()` → persistent USDZ storage (backed up)
  - `getApplicationCacheDirectory()` → temporary GLB storage (can be cleared)
- **Platform abstraction**: Single API across iOS/Android

### Alternatives Considered
- **File system APIs directly** (dart:io):
  - **Rejected**: No cross-platform path abstractions, error-prone directory management

- **image_picker for file selection**:
  - **Rejected**: Designed for images/videos only, not general files like GLB

### Implementation Notes

**GLB File Picker Pattern**:
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.any, // More reliable than FileType.custom for GLB
);
if (result != null && result.files.first.extension?.toLowerCase() == 'glb') {
  if (result.files.first.size <= 250 * 1024 * 1024) { // 250 MB
    // Process file
  }
}
```

**USDZ Storage Pattern**:
```dart
final Directory appDocDir = await getApplicationDocumentsDirectory();
final File usdzFile = File('${appDocDir.path}/scan_${timestamp}.usdz');
await usdzFile.writeAsBytes(usdzData);
```

**Critical**: Always call `getApplicationDocumentsDirectory()` when needed rather than caching the path string (iOS may return different values on app relaunch).

---

## Decision 3: USDZ→GLB Conversion Strategy

### Decision
**Hybrid Approach - Server-Side First** for USDZ→GLB conversion:
- **Phase 1 (MVP)**: Server-side conversion via Sirv API or AWS Lambda
- **Phase 2 (Future)**: Evaluate on-device preview conversion based on user feedback
- **Phase 3 (Optional)**: Full on-device conversion only if offline capability becomes critical business requirement

### Rationale
- **Meets all decision criteria**:
  - Development time: 1-2 weeks (vs 6-8 weeks on-device)
  - Binary size: 0 MB impact (vs 50-150 MB on-device)
  - Complexity: Low (proven cloud services vs custom C++/Swift USD SDK integration)

- **Leverages existing infrastructure**: GraphQL backend at `https://api.vron.stage.motorenflug.at` already handles file uploads

- **Proven conversion quality**: Sirv API and AWS Lambda solutions tested in production environments

- **Scalable**: Easy to upgrade conversion pipeline without app updates

- **Aligns with architecture**: UC20 "Save to Project" already requires backend integration

### Alternatives Considered

**Option A: On-Device Conversion (Rejected)**
- **Architecture**: C++ USD SDK + Swift wrapper + Flutter platform channels (from PRD `/Requirements/USDZ_GLB_selfdev.prd`)
- **Binary size impact**: 50-150 MB (exceeds 20 MB threshold by 2.5-7.5x)
- **Development effort**: 6-8 weeks (exceeds 2-week target by 3-4x)
- **Complexity**: High (Pixar USD SDK not optimized for mobile, material system mismatches)
- **Advantages**: Fully offline, instant conversion for validation
- **Rejected because**: Exceeds all decision criteria thresholds, high maintenance burden, no production-ready mobile USD SDK exists

**Option B: Pure Server-Side (Partially Rejected)**
- **Architecture**: Upload USDZ → cloud conversion → return GLB URL
- **Development effort**: 1-2 weeks
- **Binary size**: 0 MB
- **Disadvantages**: Blocks offline users, no local preview capability
- **Partially rejected**: Hybrid approach preferred to provide offline preview via iOS QuickLook while deferring heavy conversion to server

### Implementation Approach

**Phase 1: Server-Side Conversion (MVP - Weeks 1-2)**

**Backend Integration**:
```graphql
mutation UploadScanFile($projectId: ID!, $usdzFile: Upload!) {
  uploadProjectScan(projectId: $projectId, usdzFile: $usdzFile) {
    scanId
    usdzUrl
    glbUrl          # Backend handles conversion
    conversionStatus
  }
}
```

**Backend Options**:
1. **Sirv API** (Recommended for MVP):
   - REST-based USDZ→GLB conversion
   - Performance: 5-30 seconds typical
   - Cost: ~$0.10-0.50 per conversion (~$100-500/month for 1000 scans)
   - Simple HTTP POST integration from GraphQL backend

2. **AWS Lambda + Docker**:
   - Deploy Python `usd2gltf` tool in container
   - Trigger on S3 upload via EventBridge
   - Store converted GLB in S3, return signed URL
   - Cost: ~$0.01-0.05 per conversion (more cost-effective at scale)

**Mobile Client Flow**:
```dart
// In ScanningScreen
Future<void> _handleExportGLB() async {
  if (guestSessionManager.isGuestMode) {
    _showGuestModeConversionDialog(); // Funnel to signup
    return;
  }

  // Authenticated users: upload + convert
  final result = await projectService.convertScan(usdzPath);
  if (result.success) {
    _showGLBPreview(result.glbUrl); // WebView + Three.js
  }
}
```

**Phase 2: On-Device Preview (Future - Week 3+)**
- Lightweight USDZ viewer using native iOS ARQuickLook
- Server-converted GLB for web preview (Three.js viewer in WebView)
- No on-device conversion initially

**Phase 3: On-Device Conversion (Optional - After User Feedback)**
- Evaluate after MVP user feedback
- Only implement if offline conversion is critical business requirement
- Consider WebAssembly USD SDK when available (future technology)

### Guest Mode Handling
- Store USDZ locally (per FR-005)
- "Export GLB" button shows: "Requires network connection"
- Show dialog: "Convert to GLB requires upload. Sign up to use this feature."
- Funnel to account creation (existing AccountCreationDialog pattern)

### Performance Expectations
- Upload time (5-50 MB USDZ): 5-30 seconds (depends on network)
- Conversion time (Sirv API): 5-30 seconds
- Total end-to-end: 10-60 seconds for typical room scans
- Acceptable latency for authenticated "Save to Project" workflow

---

## Decision 4: RoomPlan Integration Pattern

### Decision
Use **MethodChannel for control methods** and **EventChannel for progress updates** with custom Swift bridge code.

### Rationale
- **MethodChannel**: Best for request-response operations (start scan, stop scan, check capability)
- **EventChannel**: Best for streaming updates (scan progress, coaching instructions, completion)
- **Follows Flutter patterns**: Official platform integration recommendations
- **Type-safe**: Swift compiler catches errors in native code
- **Testable**: Can mock platform channels in Flutter tests

### Alternatives Considered
- **MethodChannel only with polling**:
  - **Rejected**: Inefficient for real-time progress updates, poor battery performance

- **EventChannel only**:
  - **Rejected**: Less intuitive for control methods (start/stop), requires complex state management

### Implementation Pattern

**Flutter Side** (`lib/features/scanning/services/scanning_service.dart`):
```dart
class ScanningService {
  static const methodChannel = MethodChannel('com.vron.mobile/roomplan');
  static const eventChannel = EventChannel('com.vron.mobile/roomplan_progress');

  Future<bool> isLidarSupported() async {
    return await methodChannel.invokeMethod('checkLidarCapability');
  }

  Future<void> startScan() async {
    await methodChannel.invokeMethod('startRoomScan');
  }

  Stream<Map<String, dynamic>> get scanProgressStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }
}
```

**iOS Side** (`ios/Runner/RoomPlanBridge.swift`):
- Implements `FlutterPlugin` for registration
- Implements `RoomCaptureSessionDelegate` for RoomPlan callbacks
- Implements `FlutterStreamHandler` for EventChannel
- Handles interruptions (phone calls, backgrounding, low battery)
- Exports USDZ to Documents directory

**Key Delegate Methods**:
- `didUpdate room:` → Stream progress updates (wall count, door count, object count)
- `didProvide instruction:` → Stream coaching feedback (move closer, slow down, turn on light)
- `didEndWith data:` → Process final room data, export USDZ, return file path

---

## Decision 5: iOS Configuration Requirements

### Decision
- **Minimum iOS**: 16.0 (RoomPlan framework requirement)
- **Info.plist**: `NSCameraUsageDescription` key mandatory
- **Podfile**: `platform :ios, '16.0'`
- **Capabilities**: ARKit enabled in Xcode project

### Rationale
- RoomPlan framework introduced in iOS 16.0 at WWDC 2022
- Camera permission required by iOS for capture devices
- LiDAR hardware only available on iPhone 12 Pro and newer Pro models, iPad Pro 2020+

### Implementation Checklist
- [x] Update `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>This app uses the camera to scan your room and create a 3D model.</string>
  ```
- [x] Update `ios/Podfile`:
  ```ruby
  platform :ios, '16.0'
  ```
- [x] Enable ARKit capability in Xcode (Signing & Capabilities → +Capability → ARKit)

---

## Performance Considerations

### RoomPlan Scanning Performance
- **Frame rate**: 30fps minimum (RoomPlan requirement, matches SC-002)
- **Scan initiation**: <2 seconds (matches SC-001)
- **Optimal room size**: 30 ft × 30 ft (9m × 9m)
- **Maximum scan duration**: 5 minutes (thermal management, battery drain, user fatigue)
- **Battery drain**: ~20-30% per 5-minute scan

### File Sizes
- **USDZ (typical room)**: 5-50 MB (from RoomPlan documentation)
- **USDZ (complex commercial space)**: Up to 250 MB (maximum upload limit per spec)
- **GLB after conversion**: Similar size to USDZ (depends on compression)

### Memory Management
- **RoomPlan peak memory**: ~200-300 MB during active scanning
- **USDZ→GLB conversion (on-device, if implemented later)**: <512 MB (per spec requirement)
- **Mitigation**: Properly deallocate RoomCaptureSession after scan completes

---

## Risk Assessment

### High Risks (Mitigated)
- ✅ **Binary size impact from on-device conversion**: Mitigated by choosing server-side approach (0 MB vs 50-150 MB)
- ✅ **Development effort exceeding timeline**: Mitigated by hybrid approach (1-2 weeks vs 6-8 weeks)

### Medium Risks (Acceptable)
- ⚠️ **Network dependency for GLB conversion**: Acceptable trade-off for MVP, provide USDZ preview via iOS QuickLook
- ⚠️ **Conversion cost at scale**: Mitigate with AWS Lambda (lower per-conversion cost than Sirv API)
- ⚠️ **Device overheating on long scans**: Mitigate with duration warnings, monitor thermal state

### Low Risks
- ✓ **iOS-only platform constraint**: Acceptable per spec (Android users can upload GLB files)
- ✓ **Guest mode limited functionality**: Acceptable funnel to account creation
- ✓ **LiDAR hardware requirement**: Clear capability detection and messaging (FR-002)

---

## Next Steps (Phase 1: Design & Contracts)

1. **data-model.md**: Define ScanData, LidarCapability, ConversionResult entities
2. **contracts/**: GraphQL mutations for scan upload (`uploadProjectScan`)
3. **quickstart.md**: Integration scenarios (authenticated scan, guest mode, GLB upload)
4. **Agent context update**: Add flutter_roomplan, file_picker, path_provider to CLAUDE.md

---

## Sources

### Flutter RoomPlan Research
- [flutter_roomplan v1.0.7](https://pub.dev/packages/flutter_roomplan)
- [roomplan_flutter v0.1.4](https://pub.dev/packages/roomplan_flutter)
- [roomplan_launcher](https://pub.dev/packages/roomplan_launcher)

### File Handling Research
- [file_picker v10.3.8](https://pub.dev/packages/file_picker)
- [path_provider v2.1.5](https://pub.dev/packages/path_provider)

### USDZ→GLB Conversion Research
- [PRD: USDZ_GLB_selfdev.prd](../../../Requirements/USDZ_GLB_selfdev.prd)
- [Pixar OpenUSD SDK](https://github.com/PixarAnimationStudios/OpenUSD)
- [Sirv USDZ to GLB API](https://sirv.com/help/articles/convert-usdz-to-glb-via-api/)
- [usd2gltf PyPI](https://pypi.org/project/usd2gltf/)

### Apple RoomPlan Research
- [RoomPlan Overview](https://developer.apple.com/augmented-reality/roomplan/)
- [Create parametric 3D room scans with RoomPlan (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10127/)
- [Explore enhancements to RoomPlan (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10192/)

### Platform Integration Research
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Flutter MethodChannel Examples](https://medium.com/@aakashstha/call-swift-functions-from-flutter-and-vice-versa-on-ios-using-the-methodchannel-in-flutter-8837f360d2f6)
- [Flutter EventChannel Examples](https://medium.com/@atifqamar29/event-channels-in-flutter-827ef357c2d1)
