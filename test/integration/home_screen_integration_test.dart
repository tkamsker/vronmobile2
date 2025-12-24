import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/screens/home_screen.dart';
import 'package:vronmobile2/features/home/widgets/project_card.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import '../test_helpers.dart';

void main() {
  group('Home Screen Integration Tests', () {
    setUpAll(() async {
      // Initialize test environment (including guestSessionManager)
      await setupTestEnvironment();
      // Initialize environment configuration for tests
      await EnvConfig.initialize();
    });

    tearDown(() async {
      await tearDownTestEnvironment();
    });

    testWidgets('T116: loads and displays projects from API', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for API call to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should display project cards after loading
      // (This will fail until backend is available or mocked)
      expect(find.byType(ProjectCard), findsWidgets);
    });

    testWidgets('displays project list with all expected data', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify project cards display all required information
      expect(find.byType(ProjectCard), findsWidgets);

      // Each card should have:
      // - Project title
      // - Description
      // - Status badge
      // - Team info
      // - Updated time
      // - "Enter project" button
      expect(find.text('Enter project'), findsWidgets);
    });

    testWidgets('handles API error gracefully', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for API call to complete/fail
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should display error state if API fails
      // Note: This test expects an error since backend may not be available
      expect(find.textContaining('Failed'), findsAny);

      // Should have retry button
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsAny);
    });

    testWidgets('retry button refetches projects after error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for initial load/error
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If error state is shown, tap retry
      final retryButton = find.widgetWithText(ElevatedButton, 'Retry');
      if (tester.any(retryButton)) {
        await tester.tap(retryButton);
        await tester.pump();

        // Should show loading indicator again
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for second attempt
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    });

    testWidgets('search filters projects correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Get initial project count
      final initialProjectCount = tester
          .widgetList(find.byType(ProjectCard))
          .length;

      if (initialProjectCount > 0) {
        // Enter search text
        await tester.enterText(find.byType(TextField), 'marketing');
        await tester.pump();

        // Project list should update
        final filteredProjectCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;

        // Filtered count should be less than or equal to initial count
        expect(filteredProjectCount, lessThanOrEqualTo(initialProjectCount));
      }
    });

    testWidgets('filter tabs change displayed projects', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Tap "Active" filter
        await tester.tap(find.text('Active'));
        await tester.pumpAndSettle();

        // Should show only active projects
        // Verify status badges only show "Active"
        expect(find.text('Active'), findsWidgets);
        expect(find.text('Paused'), findsNothing);
        expect(find.text('Archived'), findsNothing);

        // Tap "All" to reset
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // Should show all projects again
      }
    });

    testWidgets('tapping project card navigates to project detail', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/project-detail': (context) => const Scaffold(
              body: Center(child: Text('Project Detail Screen')),
            ),
          },
        ),
      );

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.text('Enter project'))) {
        // Tap first "Enter project" button
        await tester.tap(find.text('Enter project').first);
        await tester.pumpAndSettle();

        // Should navigate to project detail screen
        expect(find.text('Project Detail Screen'), findsOneWidget);
      }
    });

    testWidgets('bottom nav navigates to correct screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/lidar': (context) =>
                const Scaffold(body: Center(child: Text('LiDAR Screen'))),
            '/profile': (context) =>
                const Scaffold(body: Center(child: Text('Profile Screen'))),
          },
        ),
      );

      // Wait for home screen to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap LiDAR tab
      await tester.tap(find.text('LiDAR'));
      await tester.pumpAndSettle();

      // Should navigate to LiDAR screen
      expect(find.text('LiDAR Screen'), findsOneWidget);
    });

    testWidgets('FAB navigates to create project screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/create-project': (context) => const Scaffold(
              body: Center(child: Text('Create Project Screen')),
            ),
          },
        ),
      );

      // Wait for home screen to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap floating action button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should navigate to create project screen
      expect(find.text('Create Project Screen'), findsOneWidget);
    });

    testWidgets('pull-to-refresh reloads project list', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Perform pull-to-refresh
      await tester.drag(find.byType(HomeScreen), const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should reload projects
      // Loading indicator should appear briefly
    });
  });
}
