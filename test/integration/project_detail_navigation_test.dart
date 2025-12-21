import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/project_detail/screens/project_detail_screen.dart';

void main() {
  group('Project Detail Navigation Integration Tests', () {
    testWidgets('can navigate to project detail screen', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testProjectId = 'test-project-123';

      // Act - Simulate navigation to detail screen
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProjectDetailScreen(projectId: testProjectId),
                    ),
                  );
                },
                child: const Text('Go to Detail'),
              ),
            ),
          ),
        ),
      );

      // Tap the navigation button
      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      // Assert - Detail screen should be displayed
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('can navigate back from project detail screen', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testProjectId = 'test-project-123';

      // Act - Navigate to detail screen
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Home')),
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProjectDetailScreen(projectId: testProjectId),
                    ),
                  );
                },
                child: const Text('Go to Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.byType(ProjectDetailScreen), findsOneWidget);

      // Act - Navigate back using back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Assert - Should be back at home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(ProjectDetailScreen), findsNothing);
    });

    testWidgets('passes project ID correctly through navigation', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testProjectId = 'test-project-456';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProjectDetailScreen(projectId: testProjectId),
                    ),
                  );
                },
                child: const Text('Go to Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      // Assert - ProjectDetailScreen widget should be present with correct ID
      final detailScreen = tester.widget<ProjectDetailScreen>(
        find.byType(ProjectDetailScreen),
      );
      expect(detailScreen.projectId, equals(testProjectId));
    });
  });
}
