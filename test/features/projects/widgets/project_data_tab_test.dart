import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/widgets/project_data_tab.dart';

void main() {
  // Helper to create a test project
  Project createTestProject({
    String id = 'proj_123',
    String slug = 'test-project',
    String name = 'Test Project',
    String description = 'Test description',
    bool isLive = true,
  }) {
    return Project(
      id: id,
      slug: slug,
      name: name,
      description: description,
      imageUrl: 'https://example.com/image.jpg',
      isLive: isLive,
      liveDate: DateTime.parse('2025-12-20T10:30:00Z'),
      subscription: ProjectSubscription(
        isActive: true,
        isTrial: false,
        status: 'ACTIVE',
        canChoosePlan: false,
        hasExpired: false,
        currency: 'EUR',
        price: 29.99,
        renewalInterval: 'MONTHLY',
        startedAt: DateTime.parse('2025-12-20T10:30:00Z'),
        expiresAt: DateTime.parse('2026-01-20T10:30:00Z'),
        renewsAt: DateTime.parse('2026-01-20T10:30:00Z'),
        prices: const ProjectSubscriptionPrices(
          currency: 'EUR',
          monthly: 29.99,
          yearly: 299.99,
        ),
      ),
    );
  }

  group('ProjectDataTab', () {
    testWidgets('T019: displays project name and description fields', (
      WidgetTester tester,
    ) async {
      // Arrange
      final project = createTestProject(
        name: 'Marketing Analytics',
        description: 'Comprehensive analytics dashboard',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectDataTab(project: project)),
        ),
      );

      // Assert - Should show form fields with project data
      expect(find.text('Marketing Analytics'), findsOneWidget);
      expect(find.text('Comprehensive analytics dashboard'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('T019: displays slug as read-only field', (
      WidgetTester tester,
    ) async {
      // Arrange
      final project = createTestProject(slug: 'marketing-analytics');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectDataTab(project: project)),
        ),
      );

      // Assert - Slug should be displayed but not editable
      expect(find.text('marketing-analytics'), findsOneWidget);
      expect(find.text('Slug'), findsOneWidget);
      // Find the slug field and verify it's read-only (enabled: false)
      final slugField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'marketing-analytics'),
      );
      expect(slugField.enabled, false);
    });

    testWidgets('T019: name and description fields are editable', (
      WidgetTester tester,
    ) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectDataTab(project: project)),
        ),
      );

      // Assert - Name and description fields should be editable
      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Test Project'),
      );
      expect(nameField.enabled, true);

      final descField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Test description'),
      );
      expect(descField.enabled, true);
    });

    testWidgets('T019: displays save button', (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectDataTab(project: project)),
        ),
      );

      // Assert
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('T019: validates required fields', (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectDataTab(project: project)),
        ),
      );

      // Clear the name field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Project'),
        '',
      );
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('T019: calls onSave callback with updated data', (
      WidgetTester tester,
    ) async {
      // Arrange
      final project = createTestProject();
      String? savedName;
      String? savedDescription;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDataTab(
              project: project,
              onSave: (name, description) {
                savedName = name;
                savedDescription = description;
              },
            ),
          ),
        ),
      );

      // Edit the name field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Project'),
        'Updated Project Name',
      );
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      expect(savedName, 'Updated Project Name');
      expect(savedDescription, 'Test description');
    });

    testWidgets(
      'T019: shows warning dialog when navigating with unsaved changes',
      (WidgetTester tester) async {
        // Arrange
        final project = createTestProject();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ProjectDataTab(project: project)),
          ),
        );

        // Edit the name field (make form dirty)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Test Project'),
          'Modified Name',
        );
        await tester.pumpAndSettle();

        // Simulate back button press
        final NavigatorState navigator = tester.state(find.byType(Navigator));
        navigator.maybePop();
        await tester.pumpAndSettle();

        // Assert - Should show warning dialog
        expect(find.text('Discard Changes'), findsOneWidget);
        expect(find.text('Keep Editing'), findsOneWidget);
      },
    );
  });
}
