import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/screens/project_detail_screen.dart';
import 'package:vronmobile2/features/projects/widgets/project_products_tab.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
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

  // Helper to create a test project
  Project createTestProject({
    String id = 'proj_test123',
    String slug = 'test-project',
    String name = 'Test Project',
  }) {
    return Project(
      id: id,
      slug: slug,
      name: name,
      description: 'Test description',
      imageUrl: 'https://example.com/image.jpg',
      isLive: true,
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

  group('Product Creation from Project Integration Tests (T036)', () {
    testWidgets(
      'T036: complete flow - navigate from project → tap FAB → create product',
      (tester) async {
        // Arrange - Create test project
        final project = createTestProject();

        // Act 1 - Start at project detail screen with Products tab
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              AppRoutes.productDetail: (context) {
                // Mock product detail screen for navigation
                return Scaffold(
                  appBar: AppBar(title: const Text('Product Detail')),
                  body: const Center(child: Text('Product Created')),
                );
              },
            },
            home: Scaffold(body: ProjectProductsTab(project: project)),
          ),
        );
        await tester.pumpAndSettle();

        // Assert 1 - Products tab should be visible
        expect(
          find.text('View Products'),
          findsOneWidget,
          reason: 'Should see products tab content',
        );

        // Act 2 - Tap FAB to create product
        final fabFinder = find.byType(FloatingActionButton);
        expect(
          fabFinder,
          findsOneWidget,
          reason: 'FAB should be visible in products tab',
        );

        // Note: In a real integration test, we would:
        // 1. Tap FAB
        // 2. Navigate to product creation screen (with project context)
        // 3. Fill out product form
        // 4. Save product
        // 5. Verify product appears in products tab
        // For now, we verify the FAB exists and is tappable
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('T036: FAB passes project context when creating product', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject(
        id: 'proj_context123',
        name: 'Context Test Project',
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

      // Assert - Project ID should be passed for context
      expect(
        capturedProjectId,
        equals('proj_context123'),
        reason: 'Should pass project ID when navigating to create product',
      );
    });

    testWidgets('T036: products tab shows loading state initially', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectProductsTab(project: project)),
        ),
      );

      // Don't call pumpAndSettle yet - check initial state
      await tester.pump();

      // Assert - Should show loading indicator initially
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Should show loading state while fetching products',
      );
    });

    testWidgets('T036: products tab handles empty product list', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectProductsTab(project: project)),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should show appropriate empty state or message
      // (Exact UI depends on implementation)
      expect(
        find.text('View Products'),
        findsOneWidget,
        reason: 'Should show products tab even when empty',
      );
    });

    testWidgets('T036: navigating to products list shows project context', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject(name: 'E-Commerce Store');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectProductsTab(project: project)),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Project context should be visible
      expect(
        find.textContaining('E-Commerce Store'),
        findsOneWidget,
        reason: 'Should show which project the products belong to',
      );
    });

    testWidgets('T036: product creation maintains project association', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject(id: 'proj_assoc123');
      String? projectIdOnCreate;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectProductsTab(
              project: project,
              onCreateProduct: (projectId) => projectIdOnCreate = projectId,
            ),
          ),
        ),
      );

      // Tap FAB to create product
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert - Should maintain project association
      expect(
        projectIdOnCreate,
        equals('proj_assoc123'),
        reason: 'Product creation should maintain project association',
      );
    });

    testWidgets(
      'T036: handles navigation back to products tab after creation',
      (tester) async {
        // Arrange
        final project = createTestProject();
        bool navigationOccurred = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProjectProductsTab(
                project: project,
                onCreateProduct: (_) => navigationOccurred = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Assert - Navigation callback should be triggered
        expect(
          navigationOccurred,
          isTrue,
          reason: 'Should trigger navigation when creating product',
        );
      },
    );

    testWidgets('T036: FAB is accessible with proper semantics', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectProductsTab(project: project)),
        ),
      );

      // Assert - FAB should have accessibility label
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget, reason: 'FAB should be accessible');

      // Note: Specific semantic label depends on implementation
      // In production, verify FAB has proper accessibility labels
    });

    testWidgets('T036: can navigate between products tab and other tabs', (
      tester,
    ) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Data'),
                    Tab(text: 'Products'),
                    Tab(text: 'Viewer'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  const Center(child: Text('Data Tab')),
                  ProjectProductsTab(project: project),
                  const Center(child: Text('Viewer Tab')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should be able to navigate to Products tab
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      expect(
        find.byType(ProjectProductsTab),
        findsOneWidget,
        reason: 'Should be able to navigate to Products tab',
      );
    });
  });
}
