/// Product status enum for type-safe status filtering
enum ProductStatus {
  ACTIVE,
  DRAFT,
}

/// Extension to convert ProductStatus enum to/from String
extension ProductStatusExtension on ProductStatus {
  String get value {
    switch (this) {
      case ProductStatus.ACTIVE:
        return 'ACTIVE';
      case ProductStatus.DRAFT:
        return 'DRAFT';
    }
  }

  static ProductStatus fromString(String status) {
    switch (status) {
      case 'ACTIVE':
        return ProductStatus.ACTIVE;
      case 'DRAFT':
        return ProductStatus.DRAFT;
      default:
        throw ArgumentError('Unknown product status: $status');
    }
  }
}

/// Product model representing a virtual product in the VRon system
/// Based on VRonGetProducts GraphQL query response
class Product {
  final String id;
  final String title;
  final String? thumbnail;
  final String status; // ACTIVE or DRAFT
  final String? category;
  final bool tracksInventory;
  final int variantsCount;

  Product({
    required this.id,
    required this.title,
    this.thumbnail,
    required this.status,
    this.category,
    required this.tracksInventory,
    required this.variantsCount,
  });

  /// Create Product from GraphQL JSON response
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: _extractText(json['title']),
      thumbnail: json['thumbnail'] as String?,
      status: json['status'] as String,
      category: json['category'] != null ? _extractText(json['category']) : null,
      tracksInventory: json['tracksInventory'] as bool? ?? false,
      variantsCount: json['variantsCount'] as int? ?? 0,
    );
  }

  /// Extract text from I18NField structure
  static String _extractText(dynamic field) {
    if (field == null) return '';
    if (field is String) return field;
    if (field is Map<String, dynamic> && field['text'] != null) {
      return field['text'] as String;
    }
    return '';
  }

  /// Get status label for display
  String get statusLabel {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'DRAFT':
        return 'Draft';
      default:
        return status;
    }
  }

  /// Get status color
  bool get isActive => status == 'ACTIVE';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          thumbnail == other.thumbnail &&
          status == other.status &&
          category == other.category &&
          tracksInventory == other.tracksInventory &&
          variantsCount == other.variantsCount;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      thumbnail.hashCode ^
      status.hashCode ^
      category.hashCode ^
      tracksInventory.hashCode ^
      variantsCount.hashCode;
}
