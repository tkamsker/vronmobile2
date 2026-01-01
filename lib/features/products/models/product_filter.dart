import 'package:flutter/foundation.dart';
import 'product.dart';

/// Encapsulates all active filter criteria for product searches.
/// Manages filter state lifecycle and provides validation.
class ProductFilter {
  final String? searchQuery;
  final ProductStatus? selectedStatus;
  final String? selectedCategoryId;
  final List<String> selectedTags;

  const ProductFilter({
    this.searchQuery,
    this.selectedStatus,
    this.selectedCategoryId,
    this.selectedTags = const [],
  });

  /// Check if any filters are active
  bool get isActive =>
      searchQuery?.isNotEmpty == true ||
      selectedStatus != null ||
      selectedCategoryId != null ||
      selectedTags.isNotEmpty;

  /// Get count of active filters (for badge display)
  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty == true) count++;
    if (selectedStatus != null) count++;
    if (selectedCategoryId != null) count++;
    if (selectedTags.isNotEmpty) count += selectedTags.length;
    return count;
  }

  /// Clear all filters
  ProductFilter clear() => const ProductFilter();

  /// Create a copy with updated fields
  ProductFilter copyWith({
    String? searchQuery,
    ProductStatus? selectedStatus,
    String? selectedCategoryId,
    List<String>? selectedTags,
  }) {
    return ProductFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }

  /// Check equality (for testing and state comparison)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductFilter &&
        other.searchQuery == searchQuery &&
        other.selectedStatus == selectedStatus &&
        other.selectedCategoryId == selectedCategoryId &&
        listEquals(other.selectedTags, selectedTags);
  }

  @override
  int get hashCode => Object.hash(
    searchQuery,
    selectedStatus,
    selectedCategoryId,
    Object.hashAll(selectedTags),
  );
}
