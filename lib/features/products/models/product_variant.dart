/// Product variant model representing different versions/options of a product
/// Each variant has its own SKU, pricing, and inventory
class ProductVariant {
  final String id;
  final String sku;
  final double price;
  final double? compareAtPrice;
  final String inventoryPolicy;
  final int inventoryQuantity;
  final double? weight;
  final String? weightUnit;

  ProductVariant({
    required this.id,
    required this.sku,
    required this.price,
    this.compareAtPrice,
    required this.inventoryPolicy,
    required this.inventoryQuantity,
    this.weight,
    this.weightUnit,
  });

  /// Create ProductVariant from GraphQL JSON response
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      sku: json['sku'] as String,
      price: (json['price'] as num).toDouble(),
      compareAtPrice: json['compareAtPrice'] != null
          ? (json['compareAtPrice'] as num).toDouble()
          : null,
      inventoryPolicy: json['inventoryPolicy'] as String? ?? 'CONTINUE',
      inventoryQuantity: json['inventoryQuantity'] as int? ?? 0,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      weightUnit: json['weightUnit'] as String?,
    );
  }

  /// Check if this variant has a discount (compareAtPrice > price)
  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  /// Calculate discount percentage
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((compareAtPrice! - price) / compareAtPrice!) * 100;
  }

  /// Check if variant is in stock
  bool get isInStock => inventoryQuantity > 0;

  /// Check if variant is low stock (1-5 items)
  bool get isLowStock => inventoryQuantity > 0 && inventoryQuantity <= 5;

  /// Check if variant is out of stock
  bool get isOutOfStock => inventoryQuantity <= 0;

  /// Get inventory status label for display
  String get inventoryStatusLabel {
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock) return 'Low stock';
    return 'In stock';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sku == other.sku &&
          price == other.price &&
          compareAtPrice == other.compareAtPrice &&
          inventoryPolicy == other.inventoryPolicy &&
          inventoryQuantity == other.inventoryQuantity &&
          weight == other.weight &&
          weightUnit == other.weightUnit;

  @override
  int get hashCode =>
      id.hashCode ^
      sku.hashCode ^
      price.hashCode ^
      compareAtPrice.hashCode ^
      inventoryPolicy.hashCode ^
      inventoryQuantity.hashCode ^
      weight.hashCode ^
      weightUnit.hashCode;
}
