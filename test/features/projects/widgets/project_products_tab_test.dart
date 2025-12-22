import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/widgets/project_products_tab.dart';

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
  });
}
