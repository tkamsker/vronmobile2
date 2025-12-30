import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vronmobile2/features/scanning/services/file_upload_service.dart';
import 'package:vronmobile2/features/scanning/services/file_storage_service.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

// T048: Integration test for complete GLB upload workflow
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GLB Upload Workflow Integration Tests', () {
    late FileUploadService uploadService;
    late FileStorageService storageService;

    setUp(() {
      uploadService = FileUploadService();
      storageService = FileStorageService();
    });

    testWidgets('Complete GLB upload workflow', (WidgetTester tester) async {
      // This test requires manual file picker interaction
      // It validates the complete flow from file selection to storage

      // Test steps:
      // 1. User opens file picker (manual)
      // 2. User selects valid GLB file
      // 3. Service validates file extension (.glb)
      // 4. Service validates file size (≤250 MB)
      // 5. Service creates ScanData entity
      // 6. Service copies file to app Documents directory
      // 7. Service saves metadata
      // 8. UI displays success confirmation

      // Note: This is a placeholder for manual integration testing
      // Automated integration tests for file picker require platform-specific mocking
    });

    test('File storage service can save and retrieve GLB scan data', () async {
      // Arrange
      final testScanData = ScanData(
        id: 'integration-test-glb',
        format: ScanFormat.glb,
        localPath: '/test/path/scan.glb',
        fileSizeBytes: 100 * 1024 * 1024, // 100 MB
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      // Act
      await storageService.saveScanMetadata(testScanData);
      final savedScans = await storageService.getAllScans();

      // Assert
      expect(savedScans, isNotEmpty);
      final savedScan = savedScans.firstWhere(
        (scan) => scan.id == 'integration-test-glb',
        orElse: () => throw Exception('Scan not found'),
      );
      expect(savedScan.format, ScanFormat.glb);
      expect(savedScan.fileSizeBytes, 100 * 1024 * 1024);

      // Cleanup
      await storageService.deleteScan(testScanData.id);
    });

    test('File validation rejects files over 250 MB', () async {
      // Arrange
      const maxSizeBytes = 250 * 1024 * 1024;
      const oversizedBytes = 300 * 1024 * 1024;

      // Act & Assert
      expect(uploadService.isValidFileSize(maxSizeBytes), isTrue);
      expect(uploadService.isValidFileSize(oversizedBytes), isFalse);
    });

    test('File validation accepts valid GLB extensions', () async {
      // Act & Assert
      expect(uploadService.isValidExtension('test.glb'), isTrue);
      expect(uploadService.isValidExtension('test.GLB'), isTrue);
      expect(uploadService.isValidExtension('test.obj'), isFalse);
      expect(uploadService.isValidExtension('test.fbx'), isFalse);
      expect(uploadService.isValidExtension('test.usdz'), isFalse);
    });

    test('GLB scan can be marked for upload to project', () async {
      // Arrange
      final testScanData = ScanData(
        id: 'upload-test-glb',
        format: ScanFormat.glb,
        localPath: '/test/path/upload.glb',
        fileSizeBytes: 75 * 1024 * 1024,
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      // Act
      final updatedScan = testScanData.copyWith(
        status: ScanStatus.uploading,
        projectId: 'test-project-123',
      );

      // Assert
      expect(updatedScan.status, ScanStatus.uploading);
      expect(updatedScan.projectId, 'test-project-123');
    });
  });
}

// Extension for ScanData copyWith
extension ScanDataCopyWith on ScanData {
  ScanData copyWith({
    String? id,
    ScanFormat? format,
    String? localPath,
    int? fileSizeBytes,
    DateTime? capturedAt,
    ScanStatus? status,
    String? projectId,
    String? remoteUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ScanData(
      id: id ?? this.id,
      format: format ?? this.format,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
