import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/projects/widgets/project_viewer_tab.dart';

void main() {
  // Helper to create a test project
  Project createTestProject({
    String id = 'proj_123',
    String slug = 'test-project',
    String name = 'Test Project',
    String description = 'Test description',
    bool isLive = true,
    String? imageUrl,
  }) {
    return Project(
      id: id,
      slug: slug,
      name: name,
      description: description,
      imageUrl: imageUrl ?? 'https://example.com/image.jpg',
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

  group('ProjectViewerTab', () {
    testWidgets('T018: displays 3D/VR viewer placeholder for live project',
        (WidgetTester tester) async {
      // Arrange
      final liveProject = createTestProject(isLive: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectViewerTab(project: liveProject),
          ),
        ),
      );

      // Assert
      expect(find.text('Live'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('T018: displays project image if available',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject(
        imageUrl: 'https://example.com/project.jpg',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectViewerTab(project: project),
          ),
        ),
      );

      // Assert - Should attempt to load the image
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('T018: displays message for non-live project',
        (WidgetTester tester) async {
      // Arrange
      final notLiveProject = createTestProject(isLive: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectViewerTab(project: notLiveProject),
          ),
        ),
      );

      // Assert
      expect(find.text('Not Live'), findsOneWidget);
    });

    testWidgets('T018: placeholder is not interactive (read-only)',
        (WidgetTester tester) async {
      // Arrange
      final project = createTestProject();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectViewerTab(project: project),
          ),
        ),
      );

      // Assert - Should not have any interactive 3D controls
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.text('3D Viewer (Coming Soon)'), findsOneWidget);
    });
  });
}
