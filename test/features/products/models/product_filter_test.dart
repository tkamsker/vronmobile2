import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_filter.dart';
import 'package:vronmobile2/features/products/models/product.dart';

void main() {
  group('ProductFilter', () {
    test('initial state has no active filters', () {
      const filter = ProductFilter();
      expect(filter.isActive, false);
      expect(filter.activeFilterCount, 0);
    });

    test('isActive returns true when search query is set', () {
      const filter = ProductFilter(searchQuery: 'test');
      expect(filter.isActive, true);
      expect(filter.activeFilterCount, 1);
    });

    test('isActive returns true when status is set', () {
      const filter = ProductFilter(selectedStatus: ProductStatus.DRAFT);
      expect(filter.isActive, true);
      expect(filter.activeFilterCount, 1);
    });

    test('isActive returns true when category is set', () {
      const filter = ProductFilter(selectedCategoryId: 'cat123');
      expect(filter.isActive, true);
      expect(filter.activeFilterCount, 1);
    });

    test('isActive returns true when tags are set', () {
      const filter = ProductFilter(selectedTags: ['tag1', 'tag2']);
      expect(filter.isActive, true);
      expect(filter.activeFilterCount, 2);
    });

    test('activeFilterCount returns correct count with multiple filters', () {
      const filter = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.DRAFT,
        selectedCategoryId: 'cat123',
      );
      expect(filter.activeFilterCount, 3);
    });

    test('activeFilterCount counts multiple tags individually', () {
      const filter = ProductFilter(
        searchQuery: 'test',
        selectedTags: ['tag1', 'tag2', 'tag3'],
      );
      expect(filter.activeFilterCount, 4); // 1 search + 3 tags
    });

    test('isActive returns false for empty search query', () {
      const filter = ProductFilter(searchQuery: '');
      expect(filter.isActive, false);
      expect(filter.activeFilterCount, 0);
    });

    test('clear returns empty filter', () {
      const filter = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.ACTIVE,
        selectedCategoryId: 'cat123',
        selectedTags: ['tag1'],
      );
      final cleared = filter.clear();
      expect(cleared.isActive, false);
      expect(cleared.searchQuery, null);
      expect(cleared.selectedStatus, null);
      expect(cleared.selectedCategoryId, null);
      expect(cleared.selectedTags, isEmpty);
    });

    test('copyWith updates only specified fields', () {
      const filter = ProductFilter(searchQuery: 'test');
      final updated = filter.copyWith(selectedStatus: ProductStatus.ACTIVE);
      expect(updated.searchQuery, 'test');
      expect(updated.selectedStatus, ProductStatus.ACTIVE);
      expect(updated.selectedCategoryId, null);
    });

    test('copyWith preserves unspecified fields', () {
      const filter = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.DRAFT,
        selectedCategoryId: 'cat123',
      );
      final updated = filter.copyWith(searchQuery: 'new query');
      expect(updated.searchQuery, 'new query');
      expect(updated.selectedStatus, ProductStatus.DRAFT);
      expect(updated.selectedCategoryId, 'cat123');
    });

    test('equality works correctly for identical filters', () {
      const filter1 = ProductFilter(searchQuery: 'test');
      const filter2 = ProductFilter(searchQuery: 'test');
      expect(filter1, filter2);
    });

    test('equality works correctly for different filters', () {
      const filter1 = ProductFilter(searchQuery: 'test');
      const filter2 = ProductFilter(searchQuery: 'other');
      expect(filter1 == filter2, false);
    });

    test('equality works correctly with multiple fields', () {
      const filter1 = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.ACTIVE,
      );
      const filter2 = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.ACTIVE,
      );
      const filter3 = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.DRAFT,
      );
      expect(filter1, filter2);
      expect(filter1 == filter3, false);
    });

    test('equality works correctly with tags', () {
      const filter1 = ProductFilter(selectedTags: ['tag1', 'tag2']);
      const filter2 = ProductFilter(selectedTags: ['tag1', 'tag2']);
      const filter3 = ProductFilter(selectedTags: ['tag1', 'tag3']);
      expect(filter1, filter2);
      expect(filter1 == filter3, false);
    });

    test('hashCode is consistent for equal filters', () {
      const filter1 = ProductFilter(searchQuery: 'test');
      const filter2 = ProductFilter(searchQuery: 'test');
      expect(filter1.hashCode, filter2.hashCode);
    });
  });
}
