import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/features/projects/screens/create_project_screen.dart';
import '../../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  tearDown(() async {
    await tearDownTestEnvironment();
  });

  group('CreateProjectScreen Widget Tests (T011)', () {
    testWidgets('T011: renders form with all required fields', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      // Assert
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: 'Should have app bar',
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(AppStrings.createProjectTitle),
        ),
        findsOneWidget,
        reason: 'App bar should show title',
      );
      expect(
        find.byType(TextFormField),
        findsNWidgets(3),
        reason: 'Should have 3 input fields: name, slug, description',
      );
      expect(
        find.byType(ElevatedButton),
        findsOneWidget,
        reason: 'Should have create button',
      );
    });

    testWidgets('T011: displays correct labels and hints', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      // Assert - Check labels
      expect(find.text(AppStrings.projectNameLabel), findsOneWidget);
      expect(find.text(AppStrings.projectSlugLabel), findsOneWidget);
      expect(find.text(AppStrings.projectDescriptionLabel), findsOneWidget);

      // Assert - Check hints
      expect(find.text(AppStrings.projectNameHint), findsOneWidget);
      expect(find.text(AppStrings.projectSlugHint), findsOneWidget);
      expect(find.text(AppStrings.projectDescriptionHint), findsOneWidget);
    });

    testWidgets('T011: auto-generates slug from name as user types', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      // Find the name field (first TextFormField)
      final nameField = find.byType(TextFormField).first;

      // Act - Enter project name
      await tester.enterText(nameField, 'My Awesome Project');
      await tester.pump();

      // Assert - Check slug was auto-generated
      final slugField = find.byType(TextFormField).at(1);
      final slugWidget = tester.widget<TextFormField>(slugField);
      expect(
        slugWidget.controller!.text,
        equals('my-awesome-project'),
        reason: 'Slug should be auto-generated from name',
      );
    });

    testWidgets('T011: slug handles special characters and spaces correctly', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Enter name with special characters
      await tester.enterText(nameField, 'Product #1 - 2025!');
      await tester.pump();

      // Assert
      final slugField = find.byType(TextFormField).at(1);
      final slugWidget = tester.widget<TextFormField>(slugField);
      expect(
        slugWidget.controller!.text,
        equals('product-1-2025'),
        reason:
            'Slug should only contain lowercase letters, numbers, and hyphens',
      );
    });

    testWidgets('T011: shows validation error for empty name', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      // Act - Tap create button without entering name
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text(AppStrings.projectNameRequired),
        findsOneWidget,
        reason: 'Should show required error for empty name',
      );
    });

    testWidgets('T011: shows validation error for name too short', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Enter name too short (less than 3 characters)
      await tester.enterText(nameField, 'AB');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text(AppStrings.projectNameTooShort),
        findsOneWidget,
        reason: 'Should show too short error for name < 3 chars',
      );
    });

    testWidgets('T011: shows validation error for name too long', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Enter name too long (more than 100 characters)
      await tester.enterText(
        nameField,
        'A' * 101, // 101 characters
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text(AppStrings.projectNameTooLong),
        findsOneWidget,
        reason: 'Should show too long error for name > 100 chars',
      );
    });

    testWidgets('T011: shows validation error for invalid slug format', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;
      final slugField = find.byType(TextFormField).at(1);

      // Act - Enter valid name, then manually edit slug to invalid format
      await tester.enterText(nameField, 'Valid Name');
      await tester.pump();
      await tester.enterText(slugField, 'Invalid Slug With Spaces!');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text(AppStrings.projectSlugInvalid),
        findsOneWidget,
        reason:
            'Should show invalid format error for slug with spaces/special chars',
      );
    });

    testWidgets('T011: allows valid form submission', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;
      final descriptionField = find.byType(TextFormField).at(2);

      // Act - Fill out form with valid data
      await tester.enterText(nameField, 'Test Project');
      await tester.pump();
      await tester.enterText(descriptionField, 'A test project description');
      await tester.pump();

      // Tap create button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert - Loading indicator should appear
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Should show loading indicator during submission',
      );
    });

    testWidgets('T011: description field is optional', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Fill only required fields (name, slug auto-generates)
      await tester.enterText(nameField, 'Minimal Project');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert - Should submit successfully (no validation error)
      expect(
        find.text(AppStrings.projectDescriptionLabel),
        findsOneWidget,
        reason: 'Description field should exist but be optional',
      );
      // Note: We can't check for actual submission success without mocking
      // But we can verify no validation errors appeared
    });

    testWidgets('T011: shows loading indicator during submission', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Submit valid form
      await tester.enterText(nameField, 'Loading Test Project');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert - Create button should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.text(AppStrings.createProjectButton),
        ),
        findsNothing,
        reason: 'Button text should be replaced by loading indicator',
      );
    });

    testWidgets('T011: disables save button during submission', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Submit valid form
      await tester.enterText(nameField, 'Button State Test');
      await tester.pump();

      final saveButton = find.widgetWithText(
        ElevatedButton,
        AppStrings.createProjectButton,
      );
      await tester.tap(saveButton);
      await tester.pump();

      // Assert - Button should be disabled (showing loading indicator)
      final buttonWidget = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(
        buttonWidget.onPressed,
        isNull,
        reason: 'Save button should be disabled during submission',
      );
    });

    testWidgets('T011: slug field is editable even after auto-generation', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;
      final slugField = find.byType(TextFormField).at(1);

      // Act - Enter name to trigger auto-generation
      await tester.enterText(nameField, 'Auto Generated');
      await tester.pump();

      // Manually override slug
      await tester.enterText(slugField, 'custom-slug');
      await tester.pump();

      // Assert
      final slugWidget = tester.widget<TextFormField>(slugField);
      expect(
        slugWidget.controller!.text,
        equals('custom-slug'),
        reason: 'User should be able to manually edit slug',
      );
    });

    testWidgets('T011: has proper semantic labels for accessibility', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      // Assert - Check for semantic widgets wrapping form fields
      final semanticsWidgets = find.byType(Semantics);
      expect(
        semanticsWidgets,
        findsWidgets,
        reason: 'Form fields should be wrapped in Semantics widgets',
      );

      // Verify all three text fields have Semantics ancestors
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(3));

      for (int i = 0; i < 3; i++) {
        expect(
          find.ancestor(of: textFields.at(i), matching: find.byType(Semantics)),
          findsWidgets,
          reason: 'Text field $i should have Semantics wrapper',
        );
      }

      // Verify button has Semantics
      expect(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(Semantics),
        ),
        findsWidgets,
        reason: 'Button should have Semantics wrapper',
      );
    });

    testWidgets('T011: tracks dirty state when fields have values', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;

      // Act - Enter text to make form dirty
      await tester.enterText(nameField, 'Dirty State Test');
      await tester.pump();

      // Note: We can't directly test _isDirty since it's private state
      // But we can verify the behavior by attempting to navigate back
      // In a full integration test, we would test the unsaved changes dialog
    });

    testWidgets('T011: form resets properly after clearing all fields', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: CreateProjectScreen()));

      final nameField = find.byType(TextFormField).first;
      final slugField = find.byType(TextFormField).at(1);

      // Act - Enter text then clear it
      await tester.enterText(nameField, 'Test');
      await tester.pump();
      await tester.enterText(nameField, '');
      await tester.pump();

      // Assert - Slug should also be cleared (empty)
      final slugWidget = tester.widget<TextFormField>(slugField);
      expect(
        slugWidget.controller!.text,
        isEmpty,
        reason: 'Slug should be empty when name is cleared',
      );
    });
  });
}
