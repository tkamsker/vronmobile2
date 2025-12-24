import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:vronmobile2/features/guest/utils/guest_storage_helper.dart';

// NOTE: These tests require path_provider plugin with platform-specific implementations.
// They cannot run in standard unit tests but will work when run on real devices/simulators.
// Run with: flutter test --device-id=<simulator-id> or during manual testing on device.
// For CI/CD, these should be run as integration tests with flutter drive or patrol.

void main() {
  late GuestStorageHelper storageHelper;

  setUpAll(() {
    // Initialize Flutter binding for path_provider
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    storageHelper = GuestStorageHelper();
  });

  group('GuestStorageHelper', () {
    test('getGuestStoragePath creates and returns guest_scans directory', () async {
      // Act
      final storagePath = await storageHelper.getGuestStoragePath();

      // Assert
      expect(storagePath, isNotEmpty);
      expect(storagePath, contains('guest_scans'));

      // Verify directory exists
      final directory = Directory(storagePath);
      expect(await directory.exists(), true);
    });

    test('saveGuestScan saves file with timestamp name when no name provided', () async {
      // Arrange
      final scanData = List<int>.generate(100, (i) => i % 256); // 100 bytes of test data

      // Act
      final filePath = await storageHelper.saveGuestScan(scanData);

      // Assert
      expect(filePath, isNotEmpty);
      expect(filePath, contains('guest_scan_'));
      expect(filePath, endsWith('.glb'));

      // Verify file exists and has correct content
      final file = File(filePath);
      expect(await file.exists(), true);
      final fileContent = await file.readAsBytes();
      expect(fileContent.length, scanData.length);

      // Cleanup
      await file.delete();
    });

    test('saveGuestScan saves file with custom name when provided', () async {
      // Arrange
      final scanData = List<int>.generate(100, (i) => i % 256);
      final customName = 'my_custom_scan.glb';

      // Act
      final filePath = await storageHelper.saveGuestScan(scanData, fileName: customName);

      // Assert
      expect(filePath, contains(customName));

      // Verify file exists
      final file = File(filePath);
      expect(await file.exists(), true);

      // Cleanup
      await file.delete();
    });

    test('listGuestScans returns all GLB files', () async {
      // Arrange - create test files
      final scanData1 = List<int>.generate(100, (i) => i % 256);
      final scanData2 = List<int>.generate(200, (i) => (i * 2) % 256);

      final filePath1 = await storageHelper.saveGuestScan(scanData1, fileName: 'test1.glb');
      final filePath2 = await storageHelper.saveGuestScan(scanData2, fileName: 'test2.glb');

      // Act
      final files = await storageHelper.listGuestScans();

      // Assert
      expect(files.length, greaterThanOrEqualTo(2));
      expect(files, contains(filePath1));
      expect(files, contains(filePath2));

      // Cleanup
      await File(filePath1).delete();
      await File(filePath2).delete();
    });

    test('listGuestScans returns empty list when no scans exist', () async {
      // Arrange - delete all existing scans first
      await storageHelper.deleteAllGuestScans();

      // Act
      final files = await storageHelper.listGuestScans();

      // Assert
      expect(files, isEmpty);
    });

    test('deleteGuestScan removes specific file', () async {
      // Arrange
      final scanData = List<int>.generate(100, (i) => i % 256);
      final filePath = await storageHelper.saveGuestScan(scanData, fileName: 'test_delete.glb');

      // Verify file exists
      expect(await File(filePath).exists(), true);

      // Act
      final deleted = await storageHelper.deleteGuestScan(filePath);

      // Assert
      expect(deleted, true);
      expect(await File(filePath).exists(), false);
    });

    test('deleteGuestScan returns false when file does not exist', () async {
      // Arrange
      final storagePath = await storageHelper.getGuestStoragePath();
      final nonExistentPath = path.join(storagePath, 'nonexistent.glb');

      // Act
      final deleted = await storageHelper.deleteGuestScan(nonExistentPath);

      // Assert
      expect(deleted, false);
    });

    test('deleteAllGuestScans removes all guest scan files', () async {
      // Arrange - create multiple test files
      final scanData = List<int>.generate(100, (i) => i % 256);
      await storageHelper.saveGuestScan(scanData, fileName: 'test1.glb');
      await storageHelper.saveGuestScan(scanData, fileName: 'test2.glb');
      await storageHelper.saveGuestScan(scanData, fileName: 'test3.glb');

      // Verify files exist
      final filesBefore = await storageHelper.listGuestScans();
      expect(filesBefore.length, greaterThanOrEqualTo(3));

      // Act
      final deletedCount = await storageHelper.deleteAllGuestScans();

      // Assert
      expect(deletedCount, greaterThanOrEqualTo(3));

      final filesAfter = await storageHelper.listGuestScans();
      expect(filesAfter, isEmpty);
    });

    test('saveGuestScan handles large files', () async {
      // Arrange - create 1MB of test data
      final largeData = List<int>.generate(1024 * 1024, (i) => i % 256);

      // Act
      final filePath = await storageHelper.saveGuestScan(largeData, fileName: 'large_scan.glb');

      // Assert
      expect(await File(filePath).exists(), true);

      final file = File(filePath);
      final fileContent = await file.readAsBytes();
      expect(fileContent.length, largeData.length);

      // Cleanup
      await file.delete();
    });
  });
}
