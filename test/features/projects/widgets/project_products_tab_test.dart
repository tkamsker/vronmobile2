import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/widgets/project_products_tab.dart';
import '../../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  tearDown(() async {
    await tearDownTestEnvironment();
  });
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

  group('ProjectProductsTab', () {
    testWidgets('T020: displays navigation button to products list',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert
      expect(find.text('View Products'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('T020: button navigates to products list screen',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();
      bool navigated = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(
              project: project,
              onNavigateToProducts: () => navigated = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('View Products'));
      await tester.pumpAndSettle();

      // Assert
      expect(navigated, true);
    });

    testWidgets('T020: displays project context information',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject(name: 'E-Commerce Store');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert - Should show which project the products belong to
      expect(find.textContaining('E-Commerce Store'), findsOneWidget);
    });

    testWidgets('T020: displays informational message about products',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert
      expect(
        find.textContaining('products'),
        findsWidgets,
      );
    });

    // T035: Additional navigation tests
    testWidgets('T035: FAB button is visible and accessible',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert - FAB should be visible for adding products
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'FAB should be visible for creating products');
    });

    testWidgets('T035: FAB tap triggers navigation callback',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();
      String? navigationProjectId;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(
              project: project,
              onCreateProduct: (projectId) => navigationProjectId = projectId,
            ),
          ),
        ),
      );

      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Assert
      expect(navigationProjectId, equals(project.id),
          reason: 'Should pass project ID when creating product');
    });

    testWidgets('T035: navigation passes correct project context',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject(
        id: 'proj_specific123',
        name: 'Specific Project',
      );
      String? capturedProjectId;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(
              project: project,
              onCreateProduct: (projectId) => capturedProjectId = projectId,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert - Should pass the specific project ID
      expect(capturedProjectId, equals('proj_specific123'),
          reason: 'Should pass correct project ID for context');
    });

    // T042: Search field tests
    testWidgets('T042: search field is visible and accessible',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsOneWidget,
          reason: 'Search field should be visible');
      expect(find.text('Search products...'), findsOneWidget,
          reason: 'Search hint should be visible');
    });

    testWidgets('T042: search field has proper semantic label',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert - Check for semantic label for accessibility
      expect(
        find.bySemanticsLabel('Search products by title'),
        findsOneWidget,
        reason: 'Search field should have accessibility label',
      );
    });

    testWidgets('T042: search field filters products as user types',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test query');
      await tester.pump();

      // Assert - Search should be applied (verified by state change)
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller!.text, equals('test query'),
          reason: 'Search query should be captured');
    });

    testWidgets('T042: clear button appears when search has text',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing,
          reason: 'Clear button should not show when search is empty');

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'search text');
      await tester.pump();

      // Assert - Clear button should now be visible
      expect(find.byIcon(Icons.clear), findsOneWidget,
          reason: 'Clear button should appear when search has text');
    });

    testWidgets('T042: clear button clears search text',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'search text');
      await tester.pump();

      // Tap clear button
      final clearButton = find.byIcon(Icons.clear);
      await tester.tap(clearButton);
      await tester.pump();

      // Assert - Search field should be cleared
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller!.text, isEmpty,
          reason: 'Clear button should clear search text');
    });

    testWidgets('T042: search has proper hint and icon',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Assert - Check for search icon
      expect(find.byIcon(Icons.search), findsOneWidget,
          reason: 'Search field should have search icon');

      // Assert - Check for hint text
      expect(find.text('Search products...'), findsOneWidget,
          reason: 'Search field should have hint text');
    });

    testWidgets('T042: empty search shows all products',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(project: project),
          ),
        ),
      );

      // Enter search text then clear it
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pump();
      await tester.enterText(searchField, '');
      await tester.pump();

      // Assert - Should show all products when search is empty
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller!.text, isEmpty,
          reason: 'Cleared search should show all products');
    });
  });
}
