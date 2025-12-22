import 'package:vronmobile2/features/products/models/media_file.dart';
import 'package:vronmobile2/features/products/models/product_variant.dart';

/// Product detail model with complete product information
/// Extends basic product with media files, variants, and metadata
class ProductDetail {
  final String id;
  final String title;
  final String description;
  final String? thumbnail;
  final String status;
  final String? category;
  final List<String> tags;
  final bool tracksInventory;
  final List<MediaFile> mediaFiles;
  final List<ProductVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDetail({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnail,
    required this.status,
    this.category,
    required this.tags,
    required this.tracksInventory,
    required this.mediaFiles,
    required this.variants,
    this.createdAt,
    this.updatedAt,
  });

  /// Create ProductDetail from GraphQL JSON response
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as String? ?? '',
      title: _extractText(json['title']),
      description: _extractText(json['description']),
      thumbnail: json['thumbnail'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      category: json['categoryId'] as String? ??
                (json['category'] != null ? _extractText(json['category']) : null),
      tags: _parseTags(json['tags']),
      tracksInventory: json['tracksInventory'] as bool? ?? false,
      mediaFiles: (json['mediaFiles'] as List?)
              ?.map((m) => MediaFile.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      variants: (json['variants'] as List?)
              ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
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

  /// Parse tags from API - can be either List or comma-separated String
  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return tags.cast<String>();
    if (tags is String) {
      if (tags.isEmpty) return [];
      return tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }
    return [];
  }

  /// Check if product is active
  bool get isActive => status == 'ACTIVE';

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDetail &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          thumbnail == other.thumbnail &&
          status == other.status &&
          category == other.category &&
          tracksInventory == other.tracksInventory;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      thumbnail.hashCode ^
      status.hashCode ^
      category.hashCode ^
      tracksInventory.hashCode;
}
