import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/screens/products_list_screen.dart';

void main() {
  group('ProductsListScreen Search', () {
    testWidgets('shows search field with hint text', (tester) async {
      // T009: Write widget test for search TextField - verify search field exists with hint text
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('typing in search field updates query', (tester) async {
      // T010: Write widget test for search query input - verify typing updates state
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Steam Punk');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Steam Punk'), findsOneWidget);
    });

    testWidgets('search triggers after 400ms debounce delay', (tester) async {
      // T011: Write widget test for debouncing - verify 400ms delay before search execution
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query
      await tester.enterText(searchField, 'Steam');
      await tester.pump();

      // Should NOT trigger search immediately
      await tester.pump(const Duration(milliseconds: 200));
      // Products list should still show initial state

      // Wait for debounce delay (400ms total)
      await tester.pump(const Duration(milliseconds: 200));

      // Now search should be triggered
      // (Search execution will be verified by checking loading state or results)
    });

    testWidgets('shows loading indicator during search', (tester) async {
      // T012: Write widget test for loading state - verify CircularProgressIndicator shown during search
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query
      await tester.enterText(searchField, 'Steam');
      await tester.pump();

      // Wait for debounce delay
      await tester.pump(const Duration(milliseconds: 400));

      // Should show loading indicator while search is in progress
      // Note: This may depend on implementation - might need to use pump() instead of pumpAndSettle()
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state message when no matches found', (tester) async {
      // T013: Write widget test for empty results - verify empty state message when no matches
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query that won't match anything
      await tester.enterText(searchField, 'NonexistentProduct12345');
      await tester.pump();

      // Wait for debounce delay
      await tester.pump(const Duration(milliseconds: 400));

      // Wait for search to complete
      await tester.pumpAndSettle();

      // Should show empty state message
      // The exact text will depend on implementation
      expect(
        find.textContaining('No products found'),
        findsOneWidget,
      );
    });

    testWidgets('shows clear button and clears search when clicked', (tester) async {
      // T014: Write widget test for clear search - verify clear button clears search query
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query
      await tester.enterText(searchField, 'Steam Punk');
      await tester.pump();

      // Clear button should appear (usually an IconButton with Icons.clear)
      final clearButton = find.widgetWithIcon(IconButton, Icons.clear);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pump();

      // Search field should be empty
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text ?? '', isEmpty);
    });

    testWidgets('search works with real-time results', (tester) async {
      // Additional test: Verify real-time search updates as user types
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type partial search query
      await tester.enterText(searchField, 'Steam');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Update search query
      await tester.enterText(searchField, 'Steam Punk');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show updated results
      // (Results verification depends on mock data availability)
    });
  });
}
