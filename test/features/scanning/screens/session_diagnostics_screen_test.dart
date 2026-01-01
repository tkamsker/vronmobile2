import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/features/scanning/screens/session_diagnostics_screen.dart';
import 'package:vronmobile2/features/scanning/services/session_investigation_service.dart';
import 'package:vronmobile2/features/scanning/models/session_diagnostics.dart';

class MockSessionInvestigationService extends Mock
    implements SessionInvestigationService {}

void main() {
  late MockSessionInvestigationService mockService;

  setUp(() {
    mockService = MockSessionInvestigationService();
  });

  Widget createTestWidget({required String sessionId}) {
    return MaterialApp(
      home: SessionDiagnosticsScreen(
        sessionId: sessionId,
        investigationService: mockService,
      ),
    );
  }

  group('SessionDiagnosticsScreen - Loading State', () {
    testWidgets('should display loading indicator while fetching data', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_LOADING';
      when(() => mockService.investigate(sessionId)).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 2));
        return SessionDiagnostics(
          sessionId: sessionId,
          sessionStatus: 'completed',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(hours: 1)),
          workspaceExists: true,
          investigationTimestamp: DateTime.now(),
        );
      });

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading session diagnostics...'), findsOneWidget);
    });
  });

  group('SessionDiagnosticsScreen - Success State', () {
    testWidgets('should display session basic information', (tester) async {
      // Arrange
      const sessionId = 'sess_ABC123';
      final diagnostics = SessionDiagnostics(
        sessionId: sessionId,
        sessionStatus: 'completed',
        createdAt: DateTime.parse('2025-12-30T12:00:00Z'),
        expiresAt: DateTime.parse('2025-12-30T13:00:00Z'),
        lastAccessed: DateTime.parse('2025-12-30T12:30:00Z'),
        workspaceExists: true,
        investigationTimestamp: DateTime.parse('2025-12-30T12:30:00Z'),
      );

      when(
        () => mockService.investigate(sessionId),
      ).thenAnswer((_) async => diagnostics);

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(sessionId), findsOneWidget);
      expect(find.text('Status: completed'), findsOneWidget);
      expect(find.text(diagnostics.statusMessage), findsOneWidget);
    });

    testWidgets('should display file structure with ExpansionTile', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_FILES';
      final diagnostics = SessionDiagnostics(
        sessionId: sessionId,
        sessionStatus: 'completed',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        workspaceExists: true,
        files: WorkspaceFilesInfo(
          directories: {
            'output': DirectoryInfo(
              exists: true,
              fileCount: 1,
              files: [
                FileInfo(
                  name: 'scan.glb',
                  sizeBytes: 2345678,
                  modifiedAt: DateTime.parse('2025-12-30T12:05:00Z'),
                ),
              ],
            ),
          },
          rootFiles: [],
        ),
        investigationTimestamp: DateTime.now(),
      );

      when(
        () => mockService.investigate(sessionId),
      ).thenAnswer((_) async => diagnostics);

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ExpansionTile), findsWidgets);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('output'), findsOneWidget);

      // Expand the files section
      await tester.tap(find.text('Files'));
      await tester.pumpAndSettle();

      expect(find.text('scan.glb'), findsOneWidget);
      expect(find.text('2.2 MB'), findsOneWidget); // sizeHumanReadable
    });

    testWidgets('should display error details for failed sessions', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_FAILED';
      final diagnostics = SessionDiagnostics(
        sessionId: sessionId,
        sessionStatus: 'failed',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        workspaceExists: true,
        errorDetails: ErrorDetails(
          errorMessage: 'Failed to load USDZ',
          errorCode: 'malformed_usdz',
          processingStage: 'upload_validation',
          failedAt: DateTime.parse('2025-12-30T11:03:00Z'),
          blenderExitCode: 1,
          lastErrorLogs: [
            'ERROR: Invalid geometry data',
            'ERROR: Conversion aborted',
          ],
        ),
        investigationTimestamp: DateTime.now(),
      );

      when(
        () => mockService.investigate(sessionId),
      ).thenAnswer((_) async => diagnostics);

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error Details'), findsOneWidget);
      expect(find.text('Failed to load USDZ'), findsOneWidget);
      expect(find.text('Error Code: malformed_usdz'), findsOneWidget);

      // Expand error details
      await tester.tap(find.text('Error Details'));
      await tester.pumpAndSettle();

      expect(find.text('ERROR: Invalid geometry data'), findsOneWidget);
    });

    testWidgets('should display JSON viewer', (tester) async {
      // Arrange
      const sessionId = 'sess_JSON';
      final diagnostics = SessionDiagnostics(
        sessionId: sessionId,
        sessionStatus: 'completed',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        workspaceExists: true,
        investigationTimestamp: DateTime.now(),
      );

      when(
        () => mockService.investigate(sessionId),
      ).thenAnswer((_) async => diagnostics);

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Full Diagnostic Data'), findsOneWidget);

      // Expand JSON viewer
      await tester.tap(find.text('Full Diagnostic Data'));
      await tester.pumpAndSettle();

      // JsonView widget should be present
      expect(find.byType(ExpansionTile), findsWidgets);
    });

    testWidgets('should show expired indicator for expired sessions', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_EXPIRED';
      final diagnostics = SessionDiagnostics(
        sessionId: sessionId,
        sessionStatus: 'expired',
        createdAt: DateTime.now().subtract(Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(Duration(hours: 1)),
        workspaceExists: false,
        investigationTimestamp: DateTime.now(),
      );

      when(
        () => mockService.investigate(sessionId),
      ).thenAnswer((_) async => diagnostics);

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Status: expired'), findsOneWidget);
      expect(diagnostics.isExpired, true);
    });
  });

  group('SessionDiagnosticsScreen - Error State', () {
    testWidgets('should display error message when investigation fails', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_ERROR';
      when(() => mockService.investigate(sessionId)).thenThrow(
        SessionInvestigationException('Session not found', statusCode: 404),
      );

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Session not found'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
    });

    testWidgets('should retry investigation when retry button tapped', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_RETRY';
      var callCount = 0;

      when(() => mockService.investigate(sessionId)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw SessionInvestigationException(
            'Temporary error',
            statusCode: 503,
          );
        }
        return SessionDiagnostics(
          sessionId: sessionId,
          sessionStatus: 'completed',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(hours: 1)),
          workspaceExists: true,
          investigationTimestamp: DateTime.now(),
        );
      });

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert - error state
      expect(find.text('Temporary error'), findsOneWidget);

      // Act - tap retry
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert - success state
      expect(find.text(sessionId), findsOneWidget);
      expect(callCount, 2);
    });
  });

  group('SessionDiagnosticsScreen - Accessibility', () {
    testWidgets('should have proper semantics for screen readers', (
      tester,
    ) async {
      // Arrange
      const sessionId = 'sess_A11Y';
      final diagnostics = SessionDiagnostics(
        sessionId: sessionId,
        sessionStatus: 'completed',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        workspaceExists: true,
        investigationTimestamp: DateTime.now(),
      );

      when(
        () => mockService.investigate(sessionId),
      ).thenAnswer((_) async => diagnostics);

      // Act
      await tester.pumpWidget(createTestWidget(sessionId: sessionId));
      await tester.pumpAndSettle();

      // Assert - check for semantic labels
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Session'),
        ),
        findsWidgets,
      );
    });
  });
}
