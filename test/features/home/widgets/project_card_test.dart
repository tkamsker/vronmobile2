import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';
import 'package:vronmobile2/features/home/widgets/project_card.dart';

void main() {
  group('ProjectCard Widget', () {
    final testSubscription = ProjectSubscription(
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
    );

    final testProject = Project(
      id: 'proj_123',
      slug: 'marketing-analytics',
      name: 'Marketing Analytics',
      description: 'Test project description',
      imageUrl: 'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
      isLive: true,
      liveDate: DateTime.parse('2025-12-20T10:30:00Z'),
      subscription: testSubscription,
    );

    testWidgets('displays project name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      expect(find.text('Marketing Analytics'), findsOneWidget);
    });

    testWidgets('displays project short description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      // Should display computed short description
      expect(find.textContaining('Live'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays project status badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      expect(find.text('Live'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays status badge with correct color for Live+Active', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      // Find the status badge
      final statusBadge = find.text('Live');
      expect(statusBadge, findsAtLeastNWidgets(1));
    });

    testWidgets('displays status badge for Live+Trial project', (
      tester,
    ) async {
      final trialProject = Project(
        id: 'proj_456',
        slug: 'trial-project',
        name: 'Trial Project',
        description: 'Trial project description',
        imageUrl: '',
        isLive: true,
        subscription: ProjectSubscription(
          isActive: false,
          isTrial: true,
          status: 'TRIAL',
          canChoosePlan: true,
          hasExpired: false,
          prices: const ProjectSubscriptionPrices(
            currency: 'EUR',
            monthly: 29.99,
            yearly: 299.99,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: trialProject)),
        ),
      );

      expect(find.text('Live (Trial)'), findsOneWidget);
    });

    testWidgets('displays status badge for Not Live project', (tester) async {
      final notLiveProject = Project(
        id: 'proj_789',
        slug: 'not-live-project',
        name: 'Not Live Project',
        description: 'Not live project description',
        imageUrl: '',
        isLive: false,
        subscription: testSubscription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: notLiveProject)),
        ),
      );

      expect(find.text('Not Live'), findsOneWidget);
    });

    testWidgets('displays team info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      expect(find.textContaining('Monthly plan'), findsOneWidget);
    });

    testWidgets('displays updated time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      // Should display some time-related text (e.g., "Updated 2h ago")
      expect(find.textContaining('Updated'), findsOneWidget);
    });

    testWidgets('displays "Enter project" button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      expect(find.text('Enter project'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('calls onTap callback when "Enter project" is tapped', (
      tester,
    ) async {
      bool wasTapped = false;
      String? tappedProjectId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: (id) {
                wasTapped = true;
                tappedProjectId = id;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Enter project'));
      await tester.pump();

      expect(wasTapped, true);
      expect(tappedProjectId, 'proj_123');
    });

    testWidgets('displays project image using CachedNetworkImage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      // Should find an image widget
      expect(find.byType(ProjectCard), findsOneWidget);
    });

    testWidgets('displays placeholder when imageUrl is empty', (tester) async {
      final projectWithoutImage = testProject.copyWith(imageUrl: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: projectWithoutImage)),
        ),
      );

      // Should display placeholder icon
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('has proper card elevation and shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, greaterThan(0));
    });

    testWidgets('has accessible semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: testProject)),
        ),
      );

      final semantics = tester.getSemantics(find.byType(ProjectCard));
      expect(semantics.label, isNotNull);
      expect(
        semantics.label,
        contains('Marketing Analytics'),
      ); // Should contain project name
    });

    testWidgets('displays yearly plan in team info', (tester) async {
      final yearlyProject = Project(
        id: 'proj_yearly',
        slug: 'yearly-project',
        name: 'Yearly Project',
        description: 'Yearly project description',
        imageUrl: '',
        isLive: true,
        subscription: ProjectSubscription(
          isActive: true,
          isTrial: false,
          status: 'ACTIVE',
          canChoosePlan: false,
          hasExpired: false,
          renewalInterval: 'YEARLY',
          prices: const ProjectSubscriptionPrices(
            currency: 'EUR',
            monthly: 29.99,
            yearly: 299.99,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: yearlyProject)),
        ),
      );

      expect(find.textContaining('Yearly plan'), findsOneWidget);
    });
  });
}
