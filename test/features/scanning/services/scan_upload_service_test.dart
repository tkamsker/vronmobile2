import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/features/scanning/models/conversion_result.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/services/scan_upload_service.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';

// Mock classes
class MockGraphQLService extends Mock implements GraphQLService {}

void main() {
  late ScanUploadService uploadService;
  late MockGraphQLService mockGraphQLService;

  setUp(() {
    mockGraphQLService = MockGraphQLService();
    uploadService = ScanUploadService(graphQLService: mockGraphQLService);
  });

  group('ScanUploadService - Upload', () {
    test('should validate scanData has localPath', () async {
      // Arrange
      final scanData = ScanData(
        id: 'test-scan',
        localPath: '', // Empty path should trigger validation error
        fileSizeBytes: 1024,
        format: ScanFormat.usdz,
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      // Act & Assert
      expect(
        () => uploadService.uploadScan(
          scanData: scanData,
          projectId: 'project-456',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate projectId is not empty', () async {
      // Arrange
      final scanData = ScanData(
        id: 'test-scan',
        localPath: '/path/to/scan.usdz',
        fileSizeBytes: 1024,
        format: ScanFormat.usdz,
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      // Act & Assert
      expect(
        () => uploadService.uploadScan(
          scanData: scanData,
          projectId: '', // Empty projectId should trigger validation error
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ScanUploadService - Polling', () {
    test('should validate scanId is not empty', () async {
      // Act & Assert
      expect(
        () => uploadService.pollConversionStatus(scanId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
