import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/screens/project_detail_screen.dart';

void main() {
  // Helper to create a test project
  Project createTestProject({
    String id = 'proj_123',
    String slug = 'test-project',
    String name = 'Test Project',
    String description = 'Test project description',
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

  group('ProjectDetailScreen', () {
    testWidgets('T016: renders project detail screen with header and tabs',
        (WidgetTester tester) async {
      // Arrange
      final testProject = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(projectId: testProject.id),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(testProject.name), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
      expect(find.text('Project data'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('T016: displays loading indicator while fetching project',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ProjectDetailScreen(projectId: 'proj_123'),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('T016: displays error message when project fetch fails',
        (WidgetTester tester) async {
      // Arrange - Mock service will be injected later
      const errorProjectId = 'invalid_id';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ProjectDetailScreen(projectId: errorProjectId),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
    });

    testWidgets('T016: navigates between tabs correctly',
        (WidgetTester tester) async {
      // Arrange
      final testProject = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(projectId: testProject.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on "Project data" tab
      await tester.tap(find.text('Project data'));
      await tester.pumpAndSettle();

      // Assert - Project data tab should be visible
      expect(find.text('Project data'), findsOneWidget);

      // Tap on "Products" tab
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      // Assert - Products tab should be visible
      expect(find.text('Products'), findsOneWidget);
    });
  });
}
