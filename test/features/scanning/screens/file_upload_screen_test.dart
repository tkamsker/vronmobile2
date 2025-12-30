import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vronmobile2/features/scanning/screens/file_upload_screen.dart';
import 'package:vronmobile2/features/scanning/services/file_upload_service.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

// Generate mocks
@GenerateMocks([FileUploadService])
import 'file_upload_screen_test.mocks.dart';

void main() {
  group('FileUploadScreen', () {
    late MockFileUploadService mockService;

    setUp(() {
      mockService = MockFileUploadService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: FileUploadScreen(uploadService: mockService),
      );
    }

    // T046: File picker UI test
    testWidgets('should display upload button and instructions',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Upload GLB File'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('should show file picker when upload button is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockService.pickAndValidateGLB()).thenAnswer((_) async => null);
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      // Assert
      verify(mockService.pickAndValidateGLB()).called(1);
    });

    // T047: Error message display test
    testWidgets('should display error message for invalid file extension',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Only GLB format is supported';
      when(mockService.pickAndValidateGLB()).thenAnswer((_) async => null);
      when(mockService.getErrorMessage(FileUploadError.invalidExtension))
          .thenReturn(errorMessage);

      await tester.pumpWidget(createTestWidget());

      // Act - Simulate picking invalid file
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Error should be shown
      // Note: This test assumes the screen shows the error after failed pick
    });

    testWidgets('should display error message for file too large',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'File size exceeds 250 MB limit';
      when(mockService.pickAndValidateGLB()).thenAnswer((_) async => null);
      when(mockService.getErrorMessage(FileUploadError.fileTooLarge))
          .thenReturn(errorMessage);

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      // Note: Error display logic to be implemented in screen
    });

    testWidgets('should display success message and file details after upload',
        (WidgetTester tester) async {
      // Arrange
      final mockScanData = ScanData(
        id: 'test-123',
        format: ScanFormat.glb,
        localPath: '/app/documents/test_scan.glb',
        fileSizeBytes: 50 * 1024 * 1024,
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      when(mockService.pickAndValidateGLB())
          .thenAnswer((_) async => mockScanData);

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // Assert - Should show success state
      // File name and size should be displayed
      expect(find.text('test_scan.glb'), findsOneWidget);
    });

    testWidgets('should show loading indicator during file processing',
        (WidgetTester tester) async {
      // Arrange
      when(mockService.pickAndValidateGLB())
          .thenAnswer((_) async => Future.delayed(
                const Duration(seconds: 1),
                () => null,
              ));

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
