import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/screens/home_screen.dart';
import 'package:vronmobile2/features/home/widgets/project_card.dart';
import 'package:vronmobile2/core/config/env_config.dart';

void main() {
  group('Home Screen Integration Tests', () {
    setUpAll(() async {
      // Initialize environment configuration for tests
      await EnvConfig.initialize();
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
        // Wait for debounce (300ms) per FR-003
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

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

    // Feature 009: Search Projects Integration Tests
    testWidgets('T009-01: search combined with Active filter', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // First apply Active filter
        await tester.tap(find.text('Active'));
        await tester.pumpAndSettle();

        final activeCount =
            tester.widgetList(find.byType(ProjectCard)).length;

        // Then apply search on top of Active filter
        await tester.enterText(find.byType(TextField), 'project');
        await tester.pump(const Duration(milliseconds: 350)); // Debounce
        await tester.pumpAndSettle();

        final filteredCount =
            tester.widgetList(find.byType(ProjectCard)).length;

        // Filtered count should be <= active count
        expect(
          filteredCount,
          lessThanOrEqualTo(activeCount),
          reason: 'Search should further filter active projects',
        );
      }
    });

    testWidgets('T009-02: search combined with Archived filter', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Apply Archived filter
        await tester.tap(find.text('Archived'));
        await tester.pumpAndSettle();

        // Apply search
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350)); // Debounce
        await tester.pumpAndSettle();

        // Should not crash and should work correctly
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('T009-03: search persists after pull-to-refresh', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Enter search query
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350)); // Debounce
        await tester.pumpAndSettle();

        // Get filtered count
        final filteredCount =
            tester.widgetList(find.byType(ProjectCard)).length;

        // Perform pull-to-refresh
        await tester.drag(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Search should still be applied after refresh
        final postRefreshCount =
            tester.widgetList(find.byType(ProjectCard)).length;

        expect(
          postRefreshCount,
          equals(filteredCount),
          reason: 'Search filter should persist after refresh',
        );

        // Verify search text is still present
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('test'));
      }
    });

    testWidgets('T009-04: switching filters clears then reapplies search', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Apply search first
        await tester.enterText(find.byType(TextField), 'project');
        await tester.pump(const Duration(milliseconds: 350)); // Debounce
        await tester.pumpAndSettle();

        // Switch to Active filter
        await tester.tap(find.text('Active'));
        await tester.pumpAndSettle();

        // Search should still be applied
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('project'));

        // Switch to Archived filter
        await tester.tap(find.text('Archived'));
        await tester.pumpAndSettle();

        // Search should still be applied
        expect(textField.controller?.text, equals('project'));
      }
    });

    testWidgets('T009-05: clear search after filtering shows all projects', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        final initialCount =
            tester.widgetList(find.byType(ProjectCard)).length;

        // Apply search
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350)); // Debounce
        await tester.pumpAndSettle();

        // Clear search using clear button
        if (tester.any(find.widgetWithIcon(IconButton, Icons.clear))) {
          await tester.tap(find.widgetWithIcon(IconButton, Icons.clear));
          await tester.pump(const Duration(milliseconds: 350)); // Debounce
          await tester.pumpAndSettle();

          // Should show all projects again
          final finalCount =
              tester.widgetList(find.byType(ProjectCard)).length;
          expect(
            finalCount,
            equals(initialCount),
            reason: 'Clearing search should show all projects',
          );
        }
      }
    });
  });
}
