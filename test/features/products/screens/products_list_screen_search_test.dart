import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/screens/products_list_screen.dart';
import 'package:vronmobile2/features/products/widgets/product_card.dart';

import '../helpers/mock_product_service.dart';

void main() {
  group('ProductsListScreen Search', () {
    late MockProductService mockProductService;

    setUp(() {
      mockProductService = MockProductService();
    });

    testWidgets('shows search field with hint text', (tester) async {
      // T009: Write widget test for search TextField - verify search field exists with hint text
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
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
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Steam Punk');
      await tester.pump();

      // Verify text was entered into the controller
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text, 'Steam Punk');
    });

    testWidgets('search triggers after 400ms debounce delay', (tester) async {
      // T011: Write widget test for debouncing - verify 400ms delay before search execution
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query
      await tester.enterText(searchField, 'Steam');
      await tester.pump();

      // Should show loading immediately (state is set to loading before debounce)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for debounce delay (400ms)
      await tester.pump(const Duration(milliseconds: 400));

      // Wait for mock service to complete
      await tester.pumpAndSettle();

      // Now search should have completed and show results
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows loading indicator during search', (tester) async {
      // T012: Write widget test for loading state - verify CircularProgressIndicator shown during search
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query
      await tester.enterText(searchField, 'Steam');
      await tester.pump();

      // Should show loading indicator immediately (before debounce completes)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state message when no matches found', (
      tester,
    ) async {
      // T013: Write widget test for empty results - verify empty state message when no matches
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
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
      expect(find.textContaining('No products found'), findsOneWidget);
    });

    testWidgets('shows clear button and clears search when clicked', (
      tester,
    ) async {
      // T014: Write widget test for clear search - verify clear button clears search query
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type search query
      await tester.enterText(searchField, 'Steam Punk');
      await tester.pump();

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Clear button should appear (usually an IconButton with Icons.clear)
      final clearButton = find.widgetWithIcon(IconButton, Icons.clear);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pump();
      await tester.pumpAndSettle();

      // Search field should be empty
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text ?? '', isEmpty);

      // Should show all products after clearing (verify by checking ProductCard count)
      expect(find.byType(ProductCard), findsAtLeastNWidgets(1));
    });

    testWidgets('search works with real-time results', (tester) async {
      // Additional test: Verify real-time search updates as user types
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type partial search query
      await tester.enterText(searchField, 'Steam');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show 1 ProductCard (Steam Punk Goggles)
      expect(find.byType(ProductCard), findsOneWidget);
      // Verify the product title is there (use findsWidgets for scrollable content)
      expect(find.text('Steam Punk Goggles'), findsWidgets);

      // Update search query to something different
      await tester.enterText(searchField, 'Victorian');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show 1 ProductCard (Victorian Hat)
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('Victorian Hat'), findsWidgets);
    });

    testWidgets('search filters products case-insensitively', (tester) async {
      // Additional test: Verify case-insensitive partial matching
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type lowercase query
      await tester.enterText(searchField, 'steam');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should still match "Steam Punk Goggles" (case-insensitive)
      // Verify by checking ProductCard count
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('Steam Punk Goggles'), findsWidgets);
    });
  });
}
