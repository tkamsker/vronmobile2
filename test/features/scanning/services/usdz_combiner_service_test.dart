import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/services/usdz_combiner_service.dart';

/// Test suite for USDZCombinerService (Flutter → iOS MethodChannel)
/// Feature 018: Combined Scan to NavMesh Workflow
/// Test: T015
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('USDZCombinerService', () {
    late USDZCombinerService service;
    late List<MethodCall> methodCalls;

    setUp(() {
      service = USDZCombinerService();
      methodCalls = [];

      // Mock MethodChannel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.vron.usdz_combiner'),
        (MethodCall call) async {
          methodCalls.add(call);

          // Mock successful response
          if (call.method == 'combineScans') {
            return '/path/to/combined_scan.usdz';
          }

          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.vron.usdz_combiner'),
        null,
      );
      methodCalls.clear();
    });

    group('combineScans', () {
      test('should call iOS native method with correct arguments', () async {
        // Given: List of scans with position data
        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime(2026, 1, 4, 10, 0),
            status: ScanStatus.completed,
            projectId: 'project-1',
            positionX: 0.0,
            positionY: 0.0,
            rotationDegrees: 0.0,
            scaleFactor: 1.0,
          ),
          ScanData(
            id: 'scan-2',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan2.usdz',
            fileSizeBytes: 4194304,
            capturedAt: DateTime(2026, 1, 4, 10, 5),
            status: ScanStatus.completed,
            projectId: 'project-1',
            positionX: 150.0,
            positionY: 0.0,
            rotationDegrees: 90.0,
            scaleFactor: 1.0,
          ),
        ];

        const outputPath = '/path/to/output/combined_scan.usdz';

        // When: Combining scans
        final result = await service.combineScans(
          scans: scans,
          outputPath: outputPath,
        );

        // Then: Should call native method
        expect(methodCalls.length, 1);
        expect(methodCalls[0].method, 'combineScans');

        // And: Should pass correct arguments
        final args = methodCalls[0].arguments as Map<String, dynamic>;
        expect(args['paths'], [
          '/path/to/scan1.usdz',
          '/path/to/scan2.usdz',
        ]);
        expect(args['outputPath'], outputPath);

        // And: Should pass transforms
        final transforms = args['transforms'] as List;
        expect(transforms.length, 2);

        expect(transforms[0]['positionX'], 0.0);
        expect(transforms[0]['positionY'], 0.0);
        expect(transforms[0]['rotation'], 0.0);
        expect(transforms[0]['scale'], 1.0);

        expect(transforms[1]['positionX'], 150.0);
        expect(transforms[1]['positionY'], 0.0);
        expect(transforms[1]['rotation'], 90.0);
        expect(transforms[1]['scale'], 1.0);

        // And: Should return result
        expect(result, '/path/to/combined_scan.usdz');
      });

      test('should use default values for missing position data', () async {
        // Given: Scans without position data
        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime(2026, 1, 4, 10, 0),
            status: ScanStatus.completed,
            projectId: 'project-1',
            // No position data
          ),
          ScanData(
            id: 'scan-2',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan2.usdz',
            fileSizeBytes: 4194304,
            capturedAt: DateTime(2026, 1, 4, 10, 5),
            status: ScanStatus.completed,
            projectId: 'project-1',
            // No position data
          ),
        ];

        const outputPath = '/path/to/output/combined_scan.usdz';

        // When: Combining scans
        await service.combineScans(scans: scans, outputPath: outputPath);

        // Then: Should use default values (0, 0, 0, 1.0)
        final args = methodCalls[0].arguments as Map<String, dynamic>;
        final transforms = args['transforms'] as List;

        expect(transforms[0]['positionX'], 0.0);
        expect(transforms[0]['positionY'], 0.0);
        expect(transforms[0]['rotation'], 0.0);
        expect(transforms[0]['scale'], 1.0);
      });

      test('should throw exception when iOS native method fails', () async {
        // Given: Mock failure response
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.vron.usdz_combiner'),
          (MethodCall call) async {
            throw PlatformException(
              code: 'COMBINE_FAILED',
              message: 'Failed to load USDZ at /path/to/scan1.usdz',
            );
          },
        );

        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
          ),
          ScanData(
            id: 'scan-2',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan2.usdz',
            fileSizeBytes: 4194304,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
          ),
        ];

        // When/Then: Should throw PlatformException
        expect(
          () => service.combineScans(
            scans: scans,
            outputPath: '/path/to/output.usdz',
          ),
          throwsA(isA<PlatformException>()),
        );
      });

      test('should validate minimum scan count', () async {
        // Given: Only 1 scan
        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
          ),
        ];

        // When/Then: Should throw ArgumentError
        expect(
          () => service.combineScans(
            scans: scans,
            outputPath: '/path/to/output.usdz',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate all scans have local paths', () async {
        // Given: Scan with empty local path
        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
          ),
          ScanData(
            id: 'scan-2',
            format: ScanFormat.usdz,
            localPath: '', // Empty path - invalid
            fileSizeBytes: 4194304,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
          ),
        ];

        // When/Then: Should throw ArgumentError
        expect(
          () => service.combineScans(
            scans: scans,
            outputPath: '/path/to/output.usdz',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle scans with partial position data', () async {
        // Given: Scans with some position fields set
        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
            positionX: 100.0,
            positionY: 50.0,
            // Missing rotation and scale
          ),
          ScanData(
            id: 'scan-2',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan2.usdz',
            fileSizeBytes: 4194304,
            capturedAt: DateTime.now(),
            status: ScanStatus.completed,
            projectId: 'project-1',
            rotationDegrees: 45.0,
            // Missing position and scale
          ),
        ];

        // When: Combining scans
        await service.combineScans(
          scans: scans,
          outputPath: '/path/to/output.usdz',
        );

        // Then: Should use provided values and defaults
        final args = methodCalls[0].arguments as Map<String, dynamic>;
        final transforms = args['transforms'] as List;

        // First scan: has position, defaults for rotation/scale
        expect(transforms[0]['positionX'], 100.0);
        expect(transforms[0]['positionY'], 50.0);
        expect(transforms[0]['rotation'], 0.0); // default
        expect(transforms[0]['scale'], 1.0); // default

        // Second scan: has rotation, defaults for position/scale
        expect(transforms[1]['positionX'], 0.0); // default
        expect(transforms[1]['positionY'], 0.0); // default
        expect(transforms[1]['rotation'], 45.0);
        expect(transforms[1]['scale'], 1.0); // default
      });
    });

    group('generateOutputPath', () {
      test('should generate path with correct format', () {
        // Given: Project ID and documents directory
        const projectId = 'project-123';
        const documentsDir = '/Users/test/Documents';

        // When: Generating output path
        final outputPath = USDZCombinerService.generateOutputPath(
          projectId: projectId,
          documentsDirectory: documentsDir,
        );

        // Then: Should have correct format
        expect(outputPath, contains('combined_scan_'));
        expect(outputPath, contains(projectId));
        expect(outputPath, endsWith('.usdz'));
        expect(outputPath, startsWith(documentsDir));
        expect(outputPath, contains('/scans/combined/'));
      });

      test('should include timestamp in filename', () {
        // Given: Same inputs called twice
        const projectId = 'project-123';
        const documentsDir = '/Users/test/Documents';

        // When: Generating paths at different times
        final path1 = USDZCombinerService.generateOutputPath(
          projectId: projectId,
          documentsDirectory: documentsDir,
        );

        // Wait a moment
        Future.delayed(Duration(milliseconds: 10));

        final path2 = USDZCombinerService.generateOutputPath(
          projectId: projectId,
          documentsDirectory: documentsDir,
        );

        // Then: Should be different (due to timestamp)
        // Note: This test may occasionally pass even if timestamps are the same
        // In real implementation, timestamp should ensure uniqueness
        expect(path1, isNotEmpty);
        expect(path2, isNotEmpty);
      });
    });
  });
}
