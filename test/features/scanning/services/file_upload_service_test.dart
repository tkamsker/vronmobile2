import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vronmobile2/features/scanning/services/file_upload_service.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

// Manual mock for FilePicker using mocktail
class MockFilePicker extends Mock implements FilePicker {}

void main() {
  group('FileUploadService', () {
    late FileUploadService service;
    late MockFilePicker mockFilePicker;

    setUp(() {
      mockFilePicker = MockFilePicker();
      service = FileUploadService(filePicker: mockFilePicker);
    });

    group('pickAndValidateGLB', () {
      // T043: Success case
      test('should return ScanData when valid GLB file is picked', () async {
        // Arrange
        final mockFile = PlatformFile(
          name: 'test_scan.glb',
          size: 50 * 1024 * 1024, // 50 MB
          path: '/mock/path/test_scan.glb',
        );
        final mockResult = FilePickerResult([mockFile]);

        when(
          mockFilePicker.pickFiles(type: FileType.any),
        ).thenAnswer((_) async => mockResult);

        // Act
        final result = await service.pickAndValidateGLB();

        // Assert
        expect(result, isNotNull);
        expect(result!.format, ScanFormat.glb);
        expect(result.localPath, contains('test_scan.glb'));
        expect(result.fileSizeBytes, 50 * 1024 * 1024);
        expect(result.status, ScanStatus.completed);
      });

      // T044: Extension validation (reject non-GLB)
      test('should return null when file extension is not .glb', () async {
        // Arrange
        final mockFile = PlatformFile(
          name: 'test_model.obj',
          size: 10 * 1024 * 1024,
          path: '/mock/path/test_model.obj',
        );
        final mockResult = FilePickerResult([mockFile]);

        when(
          mockFilePicker.pickFiles(type: FileType.any),
        ).thenAnswer((_) async => mockResult);

        // Act
        final result = await service.pickAndValidateGLB();

        // Assert
        expect(result, isNull);
      });

      // T045: File size validation (reject >250 MB)
      test('should return null when file size exceeds 250 MB', () async {
        // Arrange
        final mockFile = PlatformFile(
          name: 'large_scan.glb',
          size: 300 * 1024 * 1024, // 300 MB
          path: '/mock/path/large_scan.glb',
        );
        final mockResult = FilePickerResult([mockFile]);

        when(
          mockFilePicker.pickFiles(type: FileType.any),
        ).thenAnswer((_) async => mockResult);

        // Act
        final result = await service.pickAndValidateGLB();

        // Assert
        expect(result, isNull);
      });

      test('should accept file exactly at 250 MB limit', () async {
        // Arrange
        final mockFile = PlatformFile(
          name: 'limit_scan.glb',
          size: 250 * 1024 * 1024, // Exactly 250 MB
          path: '/mock/path/limit_scan.glb',
        );
        final mockResult = FilePickerResult([mockFile]);

        when(
          mockFilePicker.pickFiles(type: FileType.any),
        ).thenAnswer((_) async => mockResult);

        // Act
        final result = await service.pickAndValidateGLB();

        // Assert
        expect(result, isNotNull);
        expect(result!.fileSizeBytes, 250 * 1024 * 1024);
      });

      test('should return null when user cancels file picker', () async {
        // Arrange
        when(
          mockFilePicker.pickFiles(type: FileType.any),
        ).thenAnswer((_) async => null);

        // Act
        final result = await service.pickAndValidateGLB();

        // Assert
        expect(result, isNull);
      });

      test('should handle file with no path', () async {
        // Arrange
        final mockFile = PlatformFile(
          name: 'test_scan.glb',
          size: 50 * 1024 * 1024,
          path: null, // No path
        );
        final mockResult = FilePickerResult([mockFile]);

        when(
          mockFilePicker.pickFiles(type: FileType.any),
        ).thenAnswer((_) async => mockResult);

        // Act
        final result = await service.pickAndValidateGLB();

        // Assert
        expect(result, isNull);
      });
    });

    group('getErrorMessage', () {
      test('should return appropriate message for invalid extension', () {
        // Act
        final message = service.getErrorMessage(
          FileUploadError.invalidExtension,
        );

        // Assert
        expect(message, contains('GLB'));
        expect(message, contains('format'));
      });

      test('should return appropriate message for file too large', () {
        // Act
        final message = service.getErrorMessage(FileUploadError.fileTooLarge);

        // Assert
        expect(message, contains('250 MB'));
        expect(message, contains('size'));
      });

      test('should return appropriate message for no file selected', () {
        // Act
        final message = service.getErrorMessage(FileUploadError.noFileSelected);

        // Assert
        expect(message, contains('No file'));
      });
    });
  });
}
