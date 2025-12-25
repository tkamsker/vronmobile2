# Quickstart: LiDAR Scanning Integration

**Feature**: `014-lidar-scanning`
**Date**: 2025-12-25
**Status**: Phase 1 Design

## Overview

This document provides practical integration scenarios for implementing LiDAR scanning functionality. Each scenario maps to a user story from [spec.md](./spec.md) and demonstrates the complete end-to-end workflow with code examples.

---

## Prerequisites

### 1. Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_roomplan: ^1.0.7  # iOS LiDAR scanning
  file_picker: ^10.3.8       # GLB file selection
  path_provider: ^2.1.5      # Local file storage
  graphql_flutter: ^5.1.0    # Existing - backend API
  shared_preferences: ^2.2.2  # Existing - scan metadata storage
```

Run: `flutter pub get`

### 2. iOS Configuration

Update `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan your room and create a 3D model.</string>
```

Update `ios/Podfile`:
```ruby
platform :ios, '16.0'
```

Enable ARKit capability in Xcode (Signing & Capabilities → +Capability → ARKit).

### 3. Backend Setup

Ensure GraphQL API endpoint is configured:
```dart
// lib/core/services/graphql_service.dart
final httpLink = HttpLink('https://api.vron.stage.motorenflug.at/graphql');
```

Backend must implement `uploadProjectScan` mutation (see [contracts/graphql-api.md](./contracts/graphql-api.md)).

---

## Scenario 1: LiDAR Scan → Local Storage (US1)

**User Story**: Authenticated or guest user scans room with LiDAR, stores USDZ locally without immediate upload.

### Step 1: Check Device Capability

```dart
// lib/features/scanning/services/scanning_service.dart
import 'package:flutter_roomplan/flutter_roomplan.dart';

class ScanningService {
  final _roomPlan = FlutterRoomplan();

  Future<LidarCapability> checkCapability() async {
    final isSupported = await _roomPlan.isSupported();

    if (!isSupported) {
      return LidarCapability(
        support: LidarSupport.noLidar,
        deviceModel: await _getDeviceModel(),
        osVersion: await _getOSVersion(),
        isMultiRoomSupported: false,
        unsupportedReason: 'LiDAR scanning requires iPhone 12 Pro or newer with LiDAR scanner.',
      );
    }

    return LidarCapability(
      support: LidarSupport.supported,
      deviceModel: await _getDeviceModel(),
      osVersion: await _getOSVersion(),
      isMultiRoomSupported: await _roomPlan.isMultiRoomSupported(),
    );
  }
}
```

### Step 2: Start Scan with Progress Updates

```dart
// lib/features/scanning/screens/scanning_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_roomplan/flutter_roomplan.dart';

class ScanningScreen extends StatefulWidget {
  @override
  _ScanningScreenState createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  final _roomPlan = FlutterRoomplan();
  bool _isScanning = false;
  String _status = 'Ready to scan';

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _status = 'Scanning...';
    });

    // Register completion callback
    _roomPlan.onRoomCaptureFinished(() async {
      final usdzPath = await _roomPlan.getUsdzFilePath();
      final jsonPath = await _roomPlan.getJsonFilePath();

      // Save scan metadata
      await _saveScanLocally(usdzPath, jsonPath);

      setState(() {
        _isScanning = false;
        _status = 'Scan complete!';
      });

      // Navigate to preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanPreviewScreen(usdzPath: usdzPath!),
        ),
      );
    });

    // Start scanning
    await _roomPlan.startScan();
  }

  Future<void> _saveScanLocally(String? usdzPath, String? jsonPath) async {
    if (usdzPath == null) return;

    final file = File(usdzPath);
    final fileSizeBytes = await file.length();

    // Parse RoomPlan JSON metadata (if available)
    Map<String, dynamic>? metadata;
    if (jsonPath != null) {
      final jsonContent = await File(jsonPath).readAsString();
      metadata = jsonDecode(jsonContent);
    }

    // Create ScanData entity
    final scanData = ScanData(
      id: Uuid().v4(),
      format: ScanFormat.usdz,
      localPath: usdzPath,
      fileSizeBytes: fileSizeBytes,
      capturedAt: DateTime.now(),
      status: ScanStatus.completed,
      metadata: metadata,
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final scansList = prefs.getStringList('scan_data_list') ?? [];
    scansList.add(jsonEncode(scanData.toJson()));
    await prefs.setStringList('scan_data_list', scansList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room Scanning')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isScanning ? null : _startScan,
              child: Text(_isScanning ? 'Scanning...' : 'Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Handle Scan Interruptions

```dart
// lib/features/scanning/services/scanning_service.dart
import 'dart:async';

class ScanningService {
  StreamSubscription? _appLifecycleSubscription;

  void setupInterruptionHandlers() {
    // Monitor app lifecycle
    _appLifecycleSubscription = WidgetsBinding.instance.lifecycleStateChanged.listen((state) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _handleScanInterruption('backgrounded');
      }
    });

    // Monitor battery level
    // (requires battery_plus package or platform channel)
  }

  Future<void> _handleScanInterruption(String reason) async {
    // Show dialog: Save partial scan, discard, or continue
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan Interrupted'),
        content: Text('Your scan was interrupted (${reason}). What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text('Save Partial Scan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text('Continue Scanning'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      // Stop scan and save partial data
      await _roomPlan.stopScanning();
      // ... save logic
    } else if (result == 'discard') {
      // Stop scan and discard data
      await _roomPlan.stopScanning();
    }
    // If 'continue', do nothing and resume scan
  }

  void dispose() {
    _appLifecycleSubscription?.cancel();
  }
}
```

**Expected Outcome**:
- User completes scan, USDZ file stored in iOS Documents directory
- Scan metadata saved to SharedPreferences
- User sees preview screen with scan details
- Scan persists locally until explicitly deleted or uploaded

---

## Scenario 2: Upload GLB File (US2)

**User Story**: User uploads existing GLB file from device storage (Android or iOS).

### Step 1: Pick GLB File

```dart
// lib/features/scanning/services/file_upload_service.dart
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileUploadService {
  Future<ScanData?> pickAndValidateGLB() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // More reliable than FileType.custom for GLB
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final pickedFile = result.files.first;

      // Validate extension
      if (pickedFile.extension?.toLowerCase() != 'glb') {
        throw Exception('Please select a .glb file');
      }

      // Validate file size (250 MB limit)
      const maxSize = 250 * 1024 * 1024;
      if (pickedFile.size > maxSize) {
        throw Exception('File too large. Maximum size is 250 MB (current: ${(pickedFile.size / 1024 / 1024).toStringAsFixed(1)} MB)');
      }

      // Copy file to app Documents directory
      if (pickedFile.path == null) {
        throw Exception('Cannot access file path');
      }

      final sourceFile = File(pickedFile.path!);
      final appDocDir = await getApplicationDocumentsDirectory();
      final scanId = Uuid().v4();
      final destinationPath = '${appDocDir.path}/scans/scan_$scanId.glb';

      // Create scans directory if doesn't exist
      final scansDir = Directory('${appDocDir.path}/scans');
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      // Copy file
      await sourceFile.copy(destinationPath);

      // Create ScanData entity
      final scanData = ScanData(
        id: scanId,
        format: ScanFormat.glb,
        localPath: destinationPath,
        fileSizeBytes: pickedFile.size,
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final scansList = prefs.getStringList('scan_data_list') ?? [];
      scansList.add(jsonEncode(scanData.toJson()));
      await prefs.setStringList('scan_data_list', scansList);

      return scanData;
    } catch (e) {
      print('Error picking GLB file: $e');
      rethrow;
    }
  }
}
```

### Step 2: Display Uploaded File

```dart
// lib/features/scanning/screens/file_upload_screen.dart
class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final _fileUploadService = FileUploadService();
  ScanData? _uploadedScan;
  String? _errorMessage;

  Future<void> _handleGLBUpload() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final scanData = await _fileUploadService.pickAndValidateGLB();

      if (scanData != null) {
        setState(() {
          _uploadedScan = scanData;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GLB file uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload GLB File')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _handleGLBUpload,
              icon: Icon(Icons.upload_file),
              label: Text('Select GLB File'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_uploadedScan != null)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('File: ${path.basename(_uploadedScan!.localPath)}'),
                    Text('Size: ${(_uploadedScan!.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _saveToProject(_uploadedScan!),
                      child: Text('Save to Project'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToProject(ScanData scanData) async {
    // Navigate to project selection or trigger upload (Scenario 3)
  }
}
```

**Expected Outcome**:
- User selects GLB file from device storage
- File copied to app Documents directory
- Scan metadata saved to SharedPreferences
- User can save to project or view locally

---

## Scenario 3: Save Scan to Project (Backend Upload)

**User Story**: Authenticated user uploads USDZ scan to project, backend converts to GLB.

### Step 1: Upload Mutation

```dart
// lib/features/scanning/services/scan_upload_service.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ScanUploadService {
  final GraphQLClient client;

  ScanUploadService(this.client);

  static const _uploadMutation = r'''
    mutation UploadProjectScan(
      $projectId: ID!
      $scanFile: Upload!
      $format: ScanFormat!
      $metadata: JSON
    ) {
      uploadProjectScan(
        projectId: $projectId
        scanFile: $scanFile
        format: $format
        metadata: $metadata
      ) {
        scan {
          id
          usdzUrl
          glbUrl
          conversionStatus
        }
        success
        message
      }
    }
  ''';

  Future<Map<String, dynamic>> uploadScan({
    required String projectId,
    required ScanData scanData,
  }) async {
    try {
      // Update status to uploading
      scanData = scanData.copyWith(status: ScanStatus.uploading);
      await _updateLocalScanData(scanData);

      // Read file bytes
      final file = File(scanData.localPath);
      final bytes = await file.readAsBytes();

      // Create multipart file
      final multipartFile = http.MultipartFile.fromBytes(
        'scanFile',
        bytes,
        filename: path.basename(scanData.localPath),
        contentType: scanData.format == ScanFormat.usdz
            ? MediaType('model', 'vnd.usdz+zip')
            : MediaType('model', 'gltf-binary'),
      );

      // Execute mutation
      final result = await client.mutate(
        MutationOptions(
          document: gql(_uploadMutation),
          variables: {
            'projectId': projectId,
            'scanFile': multipartFile,
            'format': scanData.format.name.toUpperCase(),
            'metadata': scanData.metadata,
          },
        ),
      );

      if (result.hasException) {
        throw result.exception!;
      }

      final data = result.data!['uploadProjectScan'];

      // Update local scan data with remote URLs
      scanData = scanData.copyWith(
        status: ScanStatus.uploaded,
        projectId: projectId,
        remoteUrl: data['scan']['usdzUrl'] ?? data['scan']['glbUrl'],
      );
      await _updateLocalScanData(scanData);

      return {
        'scanId': data['scan']['id'],
        'usdzUrl': data['scan']['usdzUrl'],
        'glbUrl': data['scan']['glbUrl'],
        'conversionStatus': data['scan']['conversionStatus'],
      };
    } catch (e) {
      // Update status to failed
      scanData = scanData.copyWith(status: ScanStatus.failed);
      await _updateLocalScanData(scanData);
      rethrow;
    }
  }

  Future<void> _updateLocalScanData(ScanData scanData) async {
    final prefs = await SharedPreferences.getInstance();
    final scansList = prefs.getStringList('scan_data_list') ?? [];

    // Find and update scan
    final updatedList = scansList.map((jsonStr) {
      final scan = ScanData.fromJson(jsonDecode(jsonStr));
      return scan.id == scanData.id ? jsonEncode(scanData.toJson()) : jsonStr;
    }).toList();

    await prefs.setStringList('scan_data_list', updatedList);
  }
}
```

### Step 2: Poll Conversion Status (for USDZ uploads)

```dart
// lib/features/scanning/services/scan_upload_service.dart
static const _statusQuery = r'''
  query GetScanStatus($scanId: ID!) {
    scan(id: $scanId) {
      id
      conversionStatus
      glbUrl
      error {
        code
        message
      }
    }
  }
''';

Future<ConversionResult> pollConversionStatus(String scanId) async {
  while (true) {
    final result = await client.query(
      QueryOptions(
        document: gql(_statusQuery),
        variables: {'scanId': scanId},
        fetchPolicy: FetchPolicy.networkOnly, // Force network fetch
      ),
    );

    if (result.hasException) {
      return ConversionResult.failure(
        errorCode: ConversionErrorCode.networkError,
        errorMessage: result.exception.toString(),
      );
    }

    final scan = result.data!['scan'];
    final status = scan['conversionStatus'] as String;

    if (status == 'COMPLETED') {
      return ConversionResult.success(
        glbPath: scan['glbUrl'],
        stats: ConversionStats(
          triangleCount: 0, // Not available from backend
          meshCount: 0,
          duration: Duration.zero,
          outputFileSizeBytes: 0,
        ),
      );
    }

    if (status == 'FAILED') {
      final error = scan['error'];
      return ConversionResult.failure(
        errorCode: ConversionErrorCode.values.firstWhere(
          (e) => e.name == error['code'].toLowerCase(),
          orElse: () => ConversionErrorCode.serverError,
        ),
        errorMessage: error['message'],
      );
    }

    // Poll every 2 seconds
    await Future.delayed(Duration(seconds: 2));
  }
}
```

### Step 3: UI Workflow

```dart
// lib/features/scanning/screens/save_to_project_screen.dart
class SaveToProjectScreen extends StatefulWidget {
  final ScanData scanData;

  SaveToProjectScreen({required this.scanData});

  @override
  _SaveToProjectScreenState createState() => _SaveToProjectScreenState();
}

class _SaveToProjectScreenState extends State<SaveToProjectScreen> {
  final _uploadService = ScanUploadService(graphQLClient);
  bool _uploading = false;
  bool _converting = false;
  String? _errorMessage;
  String? _glbUrl;

  Future<void> _saveToProject(String projectId) async {
    setState(() {
      _uploading = true;
      _errorMessage = null;
    });

    try {
      // Upload scan
      final result = await _uploadService.uploadScan(
        projectId: projectId,
        scanData: widget.scanData,
      );

      setState(() {
        _uploading = false;
      });

      // If USDZ, poll for conversion completion
      if (widget.scanData.format == ScanFormat.usdz) {
        setState(() {
          _converting = true;
        });

        final conversionResult = await _uploadService.pollConversionStatus(result['scanId']);

        setState(() {
          _converting = false;
        });

        if (conversionResult.isSuccess) {
          setState(() {
            _glbUrl = conversionResult.glbPath;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scan saved and converted successfully!')),
          );
        } else {
          setState(() {
            _errorMessage = 'Conversion failed: ${conversionResult.errorMessage}';
          });
        }
      } else {
        // GLB upload (no conversion needed)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan saved successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _uploading = false;
        _converting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Save to Project')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_uploading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading scan...'),
                ],
              ),
            if (_converting)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Converting USDZ to GLB...'),
                ],
              ),
            if (!_uploading && !_converting)
              ElevatedButton(
                onPressed: () => _saveToProject('project-uuid-here'),
                child: Text('Save to Project'),
              ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_glbUrl != null)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Conversion complete!'),
                    Text('GLB URL: $_glbUrl'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

**Expected Outcome**:
- User uploads USDZ/GLB file to backend
- Progress indicators shown for upload and conversion
- Conversion status polled until completed or failed
- GLB URL returned for web preview
- Local scan metadata updated with backend URLs

---

## Scenario 4: Guest Mode Handling

**User Story**: Guest user scans room but cannot upload to backend (requires account).

### Implementation

```dart
// lib/features/scanning/screens/scanning_screen.dart
import 'package:guest_session_manager.dart'; // Existing guest mode service

class _ScanningScreenState extends State<ScanningScreen> {
  final _guestSessionManager = GuestSessionManager.instance;

  Future<void> _handleExportGLB() async {
    if (_guestSessionManager.isGuestMode) {
      _showGuestModeConversionDialog();
      return;
    }

    // Authenticated users: proceed with upload
    _saveToProject();
  }

  void _showGuestModeConversionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Account Required'),
        content: Text(
          'Converting scans to GLB format requires a network connection and an account. '
          'Create a free account to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to account creation
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountCreationScreen()),
              );
            },
            child: Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
```

**Expected Outcome**:
- Guest users can scan and store USDZ locally
- GLB conversion button shows dialog: "Account Required"
- Dialog funnels guest users to account creation
- After account creation, users can upload existing local scans

---

## Scenario 5: Error Handling

### Network Errors

```dart
Future<void> _handleNetworkError(Exception error) {
  String message;

  if (error is SocketException) {
    message = 'No internet connection. Please check your network and try again.';
  } else if (error is TimeoutException) {
    message = 'Upload timed out. Please try again with a smaller file or better connection.';
  } else if (error is OperationException) {
    // GraphQL error
    final graphQLError = error.graphqlErrors.first;
    message = graphQLError.message;
  } else {
    message = 'An error occurred: ${error.toString()}';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => _retryUpload(),
      ),
    ),
  );
}
```

### Conversion Errors

```dart
String getUserFriendlyErrorMessage(ConversionErrorCode code) {
  switch (code) {
    case ConversionErrorCode.unsupportedPrim:
      return 'This scan contains complex geometry that cannot be converted. Please try scanning a simpler room.';
    case ConversionErrorCode.missingTexture:
      return 'Scan data is incomplete. Please try scanning again with better lighting.';
    case ConversionErrorCode.readError:
      return 'Cannot read scan file. The file may be corrupted.';
    case ConversionErrorCode.memoryExceeded:
      return 'Scan is too complex to convert. Try a smaller room.';
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

## Testing Checklist

### Unit Tests
- [x] LidarCapability device detection logic
- [x] ScanData JSON serialization/deserialization
- [x] File size validation (250 MB limit)
- [x] File extension validation (.glb)
- [x] ConversionResult error code mapping

### Widget Tests
- [x] ScanButton disabled when device lacks LiDAR
- [x] Progress indicators shown during scan
- [x] Error messages displayed correctly
- [x] Guest mode dialog appears for unauthenticated users

### Integration Tests
- [x] Complete scan workflow (start → capture → store)
- [x] GLB file picker workflow
- [x] Upload workflow (local → backend)
- [x] Conversion status polling
- [x] Network error handling (offline mode)

### Manual Device Testing
- [ ] Test on iPhone 12 Pro (minimum LiDAR device)
- [ ] Test on iPhone 15 Pro (latest LiDAR device)
- [ ] Test on iPad Pro 2020+ (iPad LiDAR support)
- [ ] Test on Android device (GLB upload only, no scanning)
- [ ] Test scan interruption (phone call, backgrounding)
- [ ] Test low battery warning (<15%)
- [ ] Test network failure during upload
- [ ] Test conversion timeout scenario

---

## Performance Benchmarks

### Expected Performance
| Operation | Target | Actual (TBD) |
|-----------|--------|--------------|
| Scan initiation | <2 seconds | |
| Scan frame rate | 30fps minimum | |
| USDZ export | <5 seconds | |
| File upload (20 MB) | <15 seconds | |
| Conversion (typical room) | 5-30 seconds | |
| GLB file picker | <1 second | |

---

## Troubleshooting

### Issue: "LiDAR not supported" on iPhone 12 Pro
- **Cause**: iOS version < 16.0
- **Solution**: Update device to iOS 16.0 or later

### Issue: Upload fails with "FILE_SIZE_EXCEEDED"
- **Cause**: File size > 250 MB
- **Solution**: Re-scan room with simpler detail or scan smaller area

### Issue: Conversion stuck in "IN_PROGRESS" indefinitely
- **Cause**: Backend conversion service timeout or failure
- **Solution**: Implement 60-second timeout in polling, show retry option

### Issue: Scan interrupted by phone call
- **Cause**: iOS audio session interruption
- **Solution**: Implement interruption handlers (Scenario 1, Step 3)

---

## References

- [Spec: User Stories](./spec.md#user-scenarios--testing-mandatory)
- [Data Model: Entities](./data-model.md#entities)
- [Contracts: GraphQL API](./contracts/graphql-api.md)
- [Research: Package Decisions](./research.md)
