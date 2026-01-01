import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/screens/products_list_screen.dart';
import 'package:vronmobile2/features/products/widgets/product_card.dart';

import '../helpers/mock_product_service.dart';

void main() {
  group('ProductsListScreen Filter', () {
    late MockProductService mockProductService;

    setUp(() {
      mockProductService = MockProductService();
    });

    testWidgets('shows status filter chips (All, Draft, Active)', (
      tester,
    ) async {
      // T029: Write widget test for status filter chips - verify All, Draft, Active chips exist
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify exactly 3 ChoiceChips exist
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('selecting Draft status filters to show only draft products', (
      tester,
    ) async {
      // T030: Write widget test for status selection - verify selecting Draft shows only draft products
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Find all ChoiceChips and tap the Draft one (index 1: All=0, Draft=1, Active=2)
      final chips = find.byType(ChoiceChip);
      final chipList = tester.widgetList<ChoiceChip>(chips).toList();
      await tester.tap(find.byWidget(chipList[1]));
      await tester.pumpAndSettle();

      // Draft chip should be selected
      final updatedChips = tester.widgetList<ChoiceChip>(chips).toList();
      expect(updatedChips[1].selected, true);

      // Should show only draft products from mock data (2 draft products)
      expect(find.byType(ProductCard), findsNWidgets(2));
    });

    testWidgets('selecting All status shows all products', (tester) async {
      // Additional test: Verify All chip shows all products
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // First select Draft (index 1)
      final chips = find.byType(ChoiceChip);
      final chipList1 = tester.widgetList<ChoiceChip>(chips).toList();
      await tester.tap(find.byWidget(chipList1[1]));
      await tester.pumpAndSettle();

      // Then select All (index 0)
      final chipList2 = tester.widgetList<ChoiceChip>(chips).toList();
      await tester.tap(find.byWidget(chipList2[0]));
      await tester.pumpAndSettle();

      // All chip should be selected
      final updatedChips = tester.widgetList<ChoiceChip>(chips).toList();
      expect(updatedChips[0].selected, true);

      // Should show all products (5 total in mock data)
      expect(find.byType(ProductCard), findsNWidgets(5));
    });

    testWidgets('combining search and status filter works correctly', (
      tester,
    ) async {
      // T031: Write widget test for combined filters - verify search + status work together
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Type search query for "Steam"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Steam');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show 1 ProductCard (Steam Punk Goggles - ACTIVE)
      expect(find.byType(ProductCard), findsOneWidget);

      // Now select Draft status (index 1)
      final chips = find.byType(ChoiceChip);
      final chipList = tester.widgetList<ChoiceChip>(chips).toList();
      await tester.tap(find.byWidget(chipList[1]));
      await tester.pumpAndSettle();

      // Draft chip should be selected
      final updatedChips = tester.widgetList<ChoiceChip>(chips).toList();
      expect(updatedChips[1].selected, true);

      // Should show no results (no draft products with "Steam" in title)
      expect(find.textContaining('No products found'), findsWidgets);
    });

    testWidgets(
      'selecting Active status filters to show only active products',
      (tester) async {
        // Additional test: Verify Active filter works
        await tester.pumpWidget(
          MaterialApp(
            home: ProductsListScreen(productService: mockProductService),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the Active chip (index 2)
        final chips = find.byType(ChoiceChip);
        final chipList = tester.widgetList<ChoiceChip>(chips).toList();
        await tester.tap(find.byWidget(chipList[2]));
        await tester.pumpAndSettle();

        // Active chip should be selected
        final updatedChips = tester.widgetList<ChoiceChip>(chips).toList();
        expect(updatedChips[2].selected, true);

        // Should show only active products from mock data (3 active products)
        expect(find.byType(ProductCard), findsNWidgets(3));
      },
    );

    testWidgets('status filter has proper semantics labels', (tester) async {
      // Accessibility test: Verify semantic labels exist
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Should find semantics for filter section
      expect(find.text('Status:'), findsOneWidget);
    });

    // User Story 3: Category Filter Tests

    testWidgets('shows category dropdown with options', (tester) async {
      // T040: Write widget test for category dropdown - verify dropdown exists with category options
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Should find category dropdown button
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Should find "Category:" label
      expect(find.text('Category:'), findsOneWidget);
    });

    testWidgets('selecting a category filters products', (tester) async {
      // T041: Write widget test for category selection - verify selecting category filters products
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Find the dropdown button
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      // Tap dropdown to open menu
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Find and tap "Accessories" category in the dropdown menu
      final accessoriesOption = find.text('Accessories').last;
      await tester.tap(accessoriesOption);
      await tester.pumpAndSettle();

      // Should show only Accessories products from mock data (3 products)
      expect(find.byType(ProductCard), findsNWidgets(3));
    });

    testWidgets('combining search, status, and category filters works correctly', (
      tester,
    ) async {
      // T042: Write widget test for combined filters - verify search + status + category work together
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Type search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Clockwork');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show 1 ProductCard (Clockwork Mechanism)
      expect(find.byType(ProductCard), findsOneWidget);

      // Select Active status (index 2)
      final chips = find.byType(ChoiceChip);
      final chipList = tester.widgetList<ChoiceChip>(chips).toList();
      await tester.tap(find.byWidget(chipList[2]));
      await tester.pumpAndSettle();

      // Should still show 1 ProductCard (Clockwork Mechanism is ACTIVE)
      expect(find.byType(ProductCard), findsOneWidget);

      // Select Accessories category
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accessories').last);
      await tester.pumpAndSettle();

      // All three filter types should be available
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3)); // All, Draft, Active
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Should still show 1 ProductCard (ACTIVE + Accessories + matches "Clockwork")
      expect(find.byType(ProductCard), findsOneWidget);
    });

    testWidgets('clearing filters removes category selection', (tester) async {
      // Additional test: Verify clear all filters resets category
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Select Accessories category
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accessories').last);
      await tester.pumpAndSettle();

      // Now search for something that doesn't exist to trigger empty state
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonexistentProduct');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show "No products found"
      expect(find.textContaining('No products found'), findsWidgets);

      // Find the Clear button (ElevatedButton) and ensure it's visible
      final clearButton = find.byType(ElevatedButton);
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();

      // Tap it
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Should now show all products (5 ProductCards)
      expect(find.byType(ProductCard), findsNWidgets(5));
    });

    testWidgets('category dropdown has accessibility label', (tester) async {
      // Accessibility test for category dropdown
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(productService: mockProductService),
        ),
      );

      await tester.pumpAndSettle();

      // Should find category label for accessibility
      expect(find.text('Category:'), findsOneWidget);
    });
  });
}
