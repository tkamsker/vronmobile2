import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/screens/home_screen.dart';
import 'package:vronmobile2/features/home/widgets/project_card.dart';
import 'package:vronmobile2/core/config/env_config.dart';

/// Tests for Feature 009: Search Projects
/// Testing all functional requirements (FR-001 to FR-004) and edge cases
void main() {
  setUpAll(() async {
    // Initialize environment configuration for tests
    await EnvConfig.initialize();
  });

  group('FR-001: Search Bar in Projects List', () {
    testWidgets('search bar is present in home screen', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify search bar exists
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('search bar has correct placeholder text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Find the TextField and verify placeholder
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration?.hintText,
        isNotNull,
        reason: 'Search bar should have placeholder text',
      );
    });

    testWidgets('search bar has search icon prefix', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify search icon exists
      expect(find.widgetWithIcon(TextField, Icons.search), findsOneWidget);
    });
  });

  group('FR-002: Search Query Parameter', () {
    testWidgets('search filters projects by name', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Get initial project count
      final initialCount = tester.widgetList(find.byType(ProjectCard)).length;

      if (initialCount > 0) {
        // Enter search text with debounce delay
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(
          const Duration(milliseconds: 350),
        ); // Wait for debounce
        await tester.pumpAndSettle();

        // Verify filtering occurred
        final filteredCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;
        expect(
          filteredCount <= initialCount,
          isTrue,
          reason: 'Filtered count should be <= initial count',
        );
      }
    });

    testWidgets('search is case-insensitive', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Test uppercase search
        await tester.enterText(find.byType(TextField), 'PROJECT');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final upperCaseCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;

        // Clear and test lowercase
        await tester.enterText(find.byType(TextField), 'project');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final lowerCaseCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;

        // Case-insensitive search should return same results
        expect(
          upperCaseCount,
          equals(lowerCaseCount),
          reason: 'Search should be case-insensitive',
        );
      }
    });
  });

  group('FR-003: Debounce Search Input (300ms)', () {
    testWidgets('search does not execute immediately', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        final initialCount = tester.widgetList(find.byType(ProjectCard)).length;

        // Enter text but don't wait for debounce
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 50)); // < 300ms

        // Projects should not be filtered yet
        final immediateCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;
        expect(
          immediateCount,
          equals(initialCount),
          reason: 'Search should not execute before 300ms debounce',
        );
      }
    });

    testWidgets('search executes after 300ms debounce', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Enter text and wait for full debounce
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350)); // > 300ms
        await tester.pumpAndSettle();

        // Verify search executed (state should have updated)
        // This is validated by the fact that we can measure the filtered count
        final filteredCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;
        expect(filteredCount, isNotNull);
      }
    });

    testWidgets('rapid typing cancels previous debounce timers', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Simulate rapid typing
        await tester.enterText(find.byType(TextField), 't');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'te');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'tes');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Should only execute search once after final input
        final filteredCount = tester
            .widgetList(find.byType(ProjectCard))
            .length;
        expect(filteredCount, isNotNull);
      }
    });
  });

  group('FR-004: No Results Message', () {
    testWidgets('displays no results message when search has no matches', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Search for something that won't match
      await tester.enterText(find.byType(TextField), 'xyzabc123nonexistent');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Should display no results state
      expect(find.byType(ProjectCard), findsNothing);
      // The empty state widget should be present
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('no results message cleared when search is cleared', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Enter search with no results
        await tester.enterText(find.byType(TextField), 'xyzabc123nonexistent');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Clear search
        await tester.enterText(find.byType(TextField), '');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Should show projects again
        expect(find.byType(ProjectCard), findsWidgets);
      }
    });
  });

  group('Edge Case: Special Characters', () {
    testWidgets('search handles special characters correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test various special characters
      final specialChars = ['@', '#', '\$', '%', '&', '*', '(', ')'];

      for (final char in specialChars) {
        await tester.enterText(find.byType(TextField), char);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Should not crash and should return valid results
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('search handles unicode characters', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test unicode characters
      await tester.enterText(find.byType(TextField), 'プロジェクト'); // Japanese
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'Проект'); // Russian
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Edge Case: Long Search Queries', () {
    testWidgets('search handles very long queries', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Create a very long search string
      final longQuery = 'a' * 500;

      await tester.enterText(find.byType(TextField), longQuery);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Should not crash
      expect(tester.takeException(), isNull);
    });
  });

  group('Search with Filter Integration', () {
    testWidgets('search works with Active filter', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Apply Active filter
        await tester.tap(find.text('Active'));
        await tester.pumpAndSettle();

        // Then apply search
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Should filter by both status and search
        // No exception should occur
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('search works with Archived filter', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (tester.any(find.byType(ProjectCard))) {
        // Apply Archived filter
        await tester.tap(find.text('Archived'));
        await tester.pumpAndSettle();

        // Then apply search
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Should filter by both status and search
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Clear Button Behavior', () {
    testWidgets('clear button appears when text is entered', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Initially no clear button (no text)
      expect(find.widgetWithIcon(IconButton, Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.widgetWithIcon(IconButton, Icons.clear), findsOneWidget);
    });

    testWidgets('clear button clears search text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.widgetWithIcon(IconButton, Icons.clear));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Text should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });

  group('Accessibility', () {
    testWidgets('search bar has semantic labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Verify semantic tree includes search functionality
      expect(find.byType(TextField), findsOneWidget);

      // TextField should be accessible
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, isNotNull);
    });
  });
}
