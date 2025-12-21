import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/project_detail/widgets/project_info_section.dart';

void main() {
  group('ProjectInfoSection Widget Tests', () {
    testWidgets('displays project description when provided', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testDescription = 'This is a test project description';
      final testProject = Project(
        id: 'test-id',
        slug: 'test-slug',
        name: 'Test Project',
        description: testDescription,
        isLive: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectInfoSection(project: testProject)),
        ),
      );

      // Assert
      expect(find.text(testDescription), findsOneWidget);
    });

    testWidgets('displays "no description" message when description is null', (
      WidgetTester tester,
    ) async {
      // Arrange
      final testProject = Project(
        id: 'test-id',
        slug: 'test-slug',
        name: 'Test Project',
        description: null,
        isLive: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectInfoSection(project: testProject)),
        ),
      );

      // Assert
      expect(find.textContaining('No description'), findsOneWidget);
    });

    testWidgets('displays subscription status when subscription is active', (
      WidgetTester tester,
    ) async {
      // Arrange
      final testProject = Project(
        id: 'test-id',
        slug: 'test-slug',
        name: 'Test Project',
        isLive: false,
        subscription: ProjectSubscription(
          isActive: true,
          isTrial: false,
          status: 'ACTIVE',
          canChoosePlan: false,
          hasExpired: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectInfoSection(project: testProject)),
        ),
      );

      // Assert
      expect(find.textContaining('Subscription'), findsOneWidget);
    });

    testWidgets('displays trial badge when subscription is trial', (
      WidgetTester tester,
    ) async {
      // Arrange
      final testProject = Project(
        id: 'test-id',
        slug: 'test-slug',
        name: 'Test Project',
        isLive: false,
        subscription: ProjectSubscription(
          isActive: true,
          isTrial: true,
          status: 'TRIAL',
          canChoosePlan: false,
          hasExpired: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectInfoSection(project: testProject)),
        ),
      );

      // Assert
      expect(find.textContaining('Trial'), findsOneWidget);
    });

    testWidgets('displays live date when project is live', (
      WidgetTester tester,
    ) async {
      // Arrange
      final testLiveDate = DateTime(2025, 12, 20);
      final testProject = Project(
        id: 'test-id',
        slug: 'test-slug',
        name: 'Test Project',
        isLive: true,
        liveDate: testLiveDate,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectInfoSection(project: testProject)),
        ),
      );

      // Assert
      expect(find.textContaining('Last updated'), findsOneWidget);
    });
  });
}
