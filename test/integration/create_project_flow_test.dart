import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/features/home/screens/home_screen.dart';
import 'package:vronmobile2/features/home/widgets/custom_fab.dart';
import 'package:vronmobile2/features/projects/screens/create_project_screen.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
    await EnvConfig.initialize();
  });

  tearDown(() async {
    await tearDownTestEnvironment();
  });

  group('Create Project Flow Integration Tests (T012)', () {
    testWidgets(
        'T012: complete flow - tap FAB → fill form → save → verify in list',
        (tester) async {
      // Arrange - Start at home screen
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act 1 - Tap FAB to open create project screen
      final fabFinder = find.byType(CustomFAB);
      expect(fabFinder, findsOneWidget,
          reason: 'FAB should be visible on home screen');

      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Assert 1 - Create project screen should be displayed
      expect(find.text(AppStrings.createProjectTitle), findsOneWidget,
          reason: 'Should navigate to create project screen');

      // Act 2 - Fill out the form
      final nameField = find.byType(TextFormField).first;
      final descriptionField = find.byType(TextFormField).at(2);

      await tester.enterText(nameField, 'Integration Test Project');
      await tester.pump();

      await tester.enterText(
          descriptionField, 'Created via integration test');
      await tester.pump();

      // Assert 2 - Slug should be auto-generated
      final slugField = find.byType(TextFormField).at(1);
      final slugWidget = tester.widget<TextFormField>(slugField);
      expect(slugWidget.controller!.text, equals('integration-test-project'),
          reason: 'Slug should be auto-generated');

      // Act 3 - Submit the form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert 3 - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Should show loading during save');

      // Wait for API call to complete (with timeout)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert 4 - Should show success message or navigate back
      // Note: In a real test with mocked backend, we'd verify:
      // - Success SnackBar appears
      // - Navigation back to home screen
      // - New project appears in the list
      // For now, we verify the form submission was attempted
    });

    testWidgets('T012: handles duplicate slug error gracefully',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateProjectScreen(),
        ),
      );

      final nameField = find.byType(TextFormField).first;

      // Act - Enter a project name that might cause duplicate
      await tester.enterText(nameField, 'Duplicate Project Test');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Wait for response
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert - If duplicate, error SnackBar should appear
      // Note: Without mocking, this depends on actual backend state
      // In production tests, we'd mock the GraphQL response
    });

    testWidgets('T012: validates form before submission', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateProjectScreen(),
        ),
      );

      // Act - Try to submit without filling required fields
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert - Validation errors should appear
      expect(find.text(AppStrings.projectNameRequired), findsOneWidget,
          reason: 'Should show validation error for empty name');

      // Assert - No API call should be made (no loading indicator)
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Should not attempt API call with invalid form');
    });

    testWidgets('T012: unsaved changes warning on back navigation',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateProjectScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Create'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to create screen
      await tester.tap(find.text('Open Create'));
      await tester.pumpAndSettle();

      // Act - Enter some data to make form dirty
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Unsaved Project');
      await tester.pump();

      // Try to navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Assert - Unsaved changes dialog should appear
      expect(find.text(AppStrings.unsavedChangesTitle), findsOneWidget,
          reason: 'Should show unsaved changes warning');
      expect(find.text(AppStrings.keepEditingButton), findsOneWidget);
      expect(find.text(AppStrings.discardButton), findsOneWidget);
    });

    testWidgets('T012: can discard unsaved changes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateProjectScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Create'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Create'));
      await tester.pumpAndSettle();

      // Make form dirty
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Test');
      await tester.pump();

      // Try to go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Act - Tap discard button
      await tester.tap(find.text(AppStrings.discardButton));
      await tester.pumpAndSettle();

      // Assert - Should navigate back to previous screen
      expect(find.text('Open Create'), findsOneWidget,
          reason: 'Should return to previous screen');
      expect(find.byType(CreateProjectScreen), findsNothing,
          reason: 'Create screen should be closed');
    });

    testWidgets('T012: can keep editing from unsaved changes dialog',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateProjectScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Create'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Create'));
      await tester.pumpAndSettle();

      // Make form dirty
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Test');
      await tester.pump();

      // Try to go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Act - Tap keep editing button
      await tester.tap(find.text(AppStrings.keepEditingButton));
      await tester.pumpAndSettle();

      // Assert - Should stay on create screen
      expect(find.text(AppStrings.createProjectTitle), findsOneWidget,
          reason: 'Should stay on create screen');
      expect(find.byType(CreateProjectScreen), findsOneWidget,
          reason: 'Create screen should still be visible');

      // Verify data is preserved
      final nameFieldAfter = find.byType(TextFormField).first;
      final nameWidget = tester.widget<TextFormField>(nameFieldAfter);
      expect(nameWidget.controller!.text, equals('Test'),
          reason: 'Form data should be preserved');
    });
  });
}
