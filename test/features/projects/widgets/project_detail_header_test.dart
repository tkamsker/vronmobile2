import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/widgets/project_detail_header.dart';

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

  group('ProjectDetailHeader', () {
    testWidgets('T017: displays project name and status',
        (WidgetTester tester) async {
      // Arrange
      final testProject = createTestProject(name: 'Marketing Dashboard');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailHeader(project: testProject),
          ),
        ),
      );

      // Assert
      expect(find.text('Marketing Dashboard'), findsOneWidget);
      expect(find.text(testProject.statusLabel), findsOneWidget);
    });

    testWidgets('T017: displays back button and menu button',
        (WidgetTester tester) async {
      // Arrange
      final testProject = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailHeader(project: testProject),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('T017: back button navigates back',
        (WidgetTester tester) async {
      // Arrange
      final testProject = createTestProject();
      bool navigatedBack = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ProjectDetailHeader(
                project: testProject,
                onBackPressed: () => navigatedBack = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert
      expect(navigatedBack, true);
    });

    testWidgets('T017: displays correct status color',
        (WidgetTester tester) async {
      // Arrange
      final liveProject = createTestProject(isLive: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailHeader(project: liveProject),
          ),
        ),
      );

      // Assert
      // Status badge should be present
      expect(find.text('Live'), findsOneWidget);
    });
  });
}
