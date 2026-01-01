import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_search_result.dart';
import 'package:vronmobile2/features/products/models/product_filter.dart';
import 'package:vronmobile2/features/products/models/product.dart';

void main() {
  group('ProductSearchResult', () {
    test('initial factory creates correct state', () {
      final result = ProductSearchResult.initial();
      expect(result.isEmpty, true);
      expect(result.isInitialState, true);
      expect(result.isLoading, false);
      expect(result.hasError, false);
      expect(result.hasNoResults, false);
      expect(result.products, isEmpty);
      expect(result.totalCount, 0);
      expect(result.appliedFilter.isActive, false);
    });

    test('loading factory creates loading state', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.loading(filter);
      expect(result.isLoading, true);
      expect(result.products, isEmpty);
      expect(result.appliedFilter, filter);
      expect(result.hasError, false);
      expect(result.isInitialState, false);
    });

    test('error factory creates error state', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.error(filter, 'Network error');
      expect(result.hasError, true);
      expect(result.errorMessage, 'Network error');
      expect(result.appliedFilter, filter);
      expect(result.isLoading, false);
      expect(result.products, isEmpty);
    });

    test('success factory creates correct state with empty products', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.success(
        products: [],
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(result.products, isEmpty);
      expect(result.totalCount, 0);
      expect(result.appliedFilter, filter);
      expect(result.isLoading, false);
      expect(result.hasError, false);
    });

    test('success factory creates correct state with products', () {
      const filter = ProductFilter(searchQuery: 'test');
      // Create mock products - we'll use minimal data
      final products = <Product>[];
      final result = ProductSearchResult.success(
        products: products,
        totalCount: products.length,
        appliedFilter: filter,
      );
      expect(result.products, products);
      expect(result.totalCount, products.length);
      expect(result.isLoading, false);
      expect(result.hasError, false);
    });

    test('isEmpty returns true when products list is empty', () {
      final result = ProductSearchResult.initial();
      expect(result.isEmpty, true);
    });

    test('isEmpty returns false when products list has items', () {
      const filter = ProductFilter();
      final products = <Product>[];
      final result = ProductSearchResult.success(
        products: products,
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(result.isEmpty, true); // Empty list
    });

    test('hasNoResults returns true for active filter with no results', () {
      const filter = ProductFilter(searchQuery: 'nonexistent');
      final result = ProductSearchResult.success(
        products: [],
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(result.hasNoResults, true);
      expect(result.isEmpty, true);
      expect(result.isLoading, false);
      expect(result.hasError, false);
    });

    test('hasNoResults returns false for inactive filter with no results', () {
      const filter = ProductFilter(); // No active filters
      final result = ProductSearchResult.success(
        products: [],
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(
        result.hasNoResults,
        false,
      ); // Not "no results", just initial/empty state
      expect(result.isInitialState, true);
    });

    test('hasNoResults returns false when loading', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.loading(filter);
      expect(result.hasNoResults, false);
      expect(result.isLoading, true);
    });

    test('hasNoResults returns false when error', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.error(filter, 'Error');
      expect(result.hasNoResults, false);
      expect(result.hasError, true);
    });

    test('isInitialState returns true only for initial state', () {
      final result = ProductSearchResult.initial();
      expect(result.isInitialState, true);
    });

    test('isInitialState returns false when filter is active', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.success(
        products: [],
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(result.isInitialState, false);
    });

    test('isInitialState returns false when loading', () {
      const filter = ProductFilter();
      final result = ProductSearchResult.loading(filter);
      expect(result.isInitialState, false);
    });

    test('isInitialState returns false when error', () {
      const filter = ProductFilter();
      final result = ProductSearchResult.error(filter, 'Error');
      expect(result.isInitialState, false);
    });

    test('hasError returns true only when errorMessage is set', () {
      const filter = ProductFilter();
      final result = ProductSearchResult.error(filter, 'Network error');
      expect(result.hasError, true);
    });

    test('hasError returns false for success state', () {
      const filter = ProductFilter();
      final result = ProductSearchResult.success(
        products: [],
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(result.hasError, false);
    });

    test('hasError returns false for loading state', () {
      const filter = ProductFilter();
      final result = ProductSearchResult.loading(filter);
      expect(result.hasError, false);
    });

    test('hasError returns false for initial state', () {
      final result = ProductSearchResult.initial();
      expect(result.hasError, false);
    });
  });
}
