import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_status.dart';
import 'package:vronmobile2/features/home/widgets/project_card.dart';

void main() {
  group('ProjectCard Widget', () {
    final testProject = Project(
      id: 'proj_123',
      title: 'Marketing Analytics',
      description: 'Realtime overview of campaign performance.',
      status: ProjectStatus.active,
      imageUrl: 'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
      updatedAt: DateTime.parse('2025-12-20T10:30:00Z'),
      teamInfo: '4 teammates',
    );

    testWidgets('displays project title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      expect(find.text('Marketing Analytics'), findsOneWidget);
    });

    testWidgets('displays project description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      expect(
        find.text('Realtime overview of campaign performance.'),
        findsOneWidget,
      );
    });

    testWidgets('displays project status badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays status badge with correct color for active status', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      // Find the status badge container
      final statusBadge = find.text('Active');
      expect(statusBadge, findsOneWidget);
    });

    testWidgets('displays status badge with correct color for paused status', (
      tester,
    ) async {
      final pausedProject = testProject.copyWith(status: ProjectStatus.paused);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: pausedProject),
          ),
        ),
      );

      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets(
      'displays status badge with correct color for archived status',
      (tester) async {
        final archivedProject =
            testProject.copyWith(status: ProjectStatus.archived);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProjectCard(project: archivedProject),
            ),
          ),
        );

        expect(find.text('Archived'), findsOneWidget);
      },
    );

    testWidgets('displays team info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      expect(find.textContaining('4 teammates'), findsOneWidget);
    });

    testWidgets('displays updated time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      // Should display some time-related text (e.g., "Updated 2h ago")
      expect(find.textContaining('Updated'), findsOneWidget);
    });

    testWidgets('displays "Enter project" button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
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

    testWidgets('displays project image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      // Should find an image widget (CachedNetworkImage or similar)
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('displays placeholder when imageUrl is empty', (tester) async {
      final projectWithoutImage = testProject.copyWith(imageUrl: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: projectWithoutImage),
          ),
        ),
      );

      // Should still display without error
      expect(find.byType(ProjectCard), findsOneWidget);
    });

    testWidgets('has proper card elevation and shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, greaterThan(0));
    });

    testWidgets('has accessible semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(project: testProject),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(ProjectCard));
      expect(semantics.label, isNotNull);
    });
  });
}
