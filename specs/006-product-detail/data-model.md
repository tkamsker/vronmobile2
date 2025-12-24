# Product Detail Data Model

## GraphQL API Contracts

### 1. Get Product Detail Query

**Query**: `VRonGetProduct`
**Purpose**: Fetch complete product details by ID

```graphql
query GetProduct($input: VRonGetProductInput!, $lang: Language!) {
  VRonGetProduct(input: $input) {
    id
    title {
      text(lang: $lang)
    }
    description {
      text(lang: $lang)
    }
    thumbnail
    status
    category {
      text(lang: $lang)
    }
    tags
    tracksInventory
    mediaFiles {
      id
      url
      filename
      mimeType
      size
    }
    variants {
      id
      sku
      price
      compareAtPrice
      inventoryPolicy
      inventoryQuantity
      weight
      weightUnit
    }
    createdAt
    updatedAt
  }
}
```

**Input Type**: `VRonGetProductInput`
```typescript
{
  id: String!  // Product ID
}
```

**Example Request**:
```json
{
  "input": {
    "id": "prod_abc123"
  },
  "lang": "EN"
}
```

**Example Response**:
```json
{
  "data": {
    "VRonGetProduct": {
      "id": "prod_abc123",
      "title": {
        "text": "Virtual Chair"
      },
      "description": {
        "text": "A comfortable modern chair for virtual spaces"
      },
      "thumbnail": "https://cdn.example.com/products/chair_thumb.jpg",
      "status": "ACTIVE",
      "category": {
        "text": "Furniture"
      },
      "tags": ["furniture", "seating", "modern"],
      "tracksInventory": true,
      "mediaFiles": [
        {
          "id": "media_001",
          "url": "https://cdn.example.com/products/chair_001.jpg",
          "filename": "chair_front.jpg",
          "mimeType": "image/jpeg",
          "size": 245678
        }
      ],
      "variants": [
        {
          "id": "var_001",
          "sku": "CHAIR-BLK-001",
          "price": 99.99,
          "compareAtPrice": 129.99,
          "inventoryPolicy": "DENY",
          "inventoryQuantity": 15,
          "weight": 5.5,
          "weightUnit": "kg"
        }
      ],
      "createdAt": "2025-01-15T10:30:00Z",
      "updatedAt": "2025-12-20T14:20:00Z"
    }
  }
}
```

---

## Data Models

### ProductDetail Model

Extends the existing `Product` model with additional detail fields.

```dart
class ProductDetail {
  final String id;
  final String title;
  final String description;
  final String? thumbnail;
  final ProductStatus status;
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

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as String,
      title: _extractText(json['title']),
      description: _extractText(json['description']),
      thumbnail: json['thumbnail'] as String?,
      status: ProductStatus.fromString(json['status'] as String),
      category: json['category'] != null ? _extractText(json['category']) : null,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      tracksInventory: json['tracksInventory'] as bool? ?? false,
      mediaFiles: (json['mediaFiles'] as List?)
          ?.map((m) => MediaFile.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      variants: (json['variants'] as List?)
          ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
```

### MediaFile Model

Represents a media file attached to a product.

```dart
class MediaFile {
  final String id;
  final String url;
  final String filename;
  final String? mimeType;
  final int? size;

  MediaFile({
    required this.id,
    required this.url,
    required this.filename,
    this.mimeType,
    this.size,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int?,
    );
  }

  bool get isImage => mimeType?.startsWith('image/') ?? false;
  bool get isVideo => mimeType?.startsWith('video/') ?? false;

  String get formattedSize {
    if (size == null) return 'Unknown size';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

### ProductVariant Model

Represents a product variant with pricing and inventory.

```dart
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

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((compareAtPrice! - price) / compareAtPrice!) * 100;
  }

  bool get isInStock => inventoryQuantity > 0;
  bool get isLowStock => inventoryQuantity > 0 && inventoryQuantity <= 5;
  bool get isOutOfStock => inventoryQuantity <= 0;

  String get inventoryStatusLabel {
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock) return 'Low stock';
    return 'In stock';
  }
}
```

### ProductStatus Enum

```dart
enum ProductStatus {
  active,
  draft;

  static ProductStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return ProductStatus.active;
      case 'DRAFT':
        return ProductStatus.draft;
      default:
        throw ArgumentError('Unknown product status: $status');
    }
  }

  String toGraphQL() {
    switch (this) {
      case ProductStatus.active:
        return 'ACTIVE';
      case ProductStatus.draft:
        return 'DRAFT';
    }
  }

  String get label {
    switch (this) {
      case ProductStatus.active:
        return 'Active';
      case ProductStatus.draft:
        return 'Draft';
    }
  }
}
```

---

## Service Layer

### ProductDetailService

Extends or works alongside existing `ProductService`.

```dart
class ProductDetailService {
  final GraphQLService _graphqlService;
  final String _language;

  static const String _getProductQuery = '''
    query GetProduct(\$input: VRonGetProductInput!, \$lang: Language!) {
      VRonGetProduct(input: \$input) {
        id
        title { text(lang: \$lang) }
        description { text(lang: \$lang) }
        thumbnail
        status
        category { text(lang: \$lang) }
        tags
        tracksInventory
        mediaFiles {
          id
          url
          filename
          mimeType
          size
        }
        variants {
          id
          sku
          price
          compareAtPrice
          inventoryPolicy
          inventoryQuantity
          weight
          weightUnit
        }
        createdAt
        updatedAt
      }
    }
  ''';

  Future<ProductDetail> getProductDetail(String productId) async {
    // Implementation
  }
}
```

---

## Navigation Arguments

```dart
class ProductDetailScreenArguments {
  final String productId;
  final String? productTitle; // Optional, for optimistic UI

  ProductDetailScreenArguments({
    required this.productId,
    this.productTitle,
  });
}
```

---

## State Management

### ProductDetailState

```dart
class ProductDetailState {
  final ProductDetail? product;
  final bool isLoading;
  final String? errorMessage;

  ProductDetailState({
    this.product,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasData => product != null;
  bool get hasError => errorMessage != null;
  bool get isEmpty => !hasData && !isLoading && !hasError;
}
```

---

## Constants

```dart
class ProductDetailConstants {
  // Image dimensions
  static const double thumbnailSize = 120.0;
  static const double galleryImageSize = 100.0;
  static const double fullScreenImageMaxWidth = 1024.0;

  // Inventory thresholds
  static const int lowStockThreshold = 5;
  static const int outOfStockThreshold = 0;

  // Media
  static const List<String> supportedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  ];

  // Formatting
  static const String defaultCurrency = 'EUR';
  static const int priceDecimalPlaces = 2;
}
```

---

## Error Handling

### Error Types

```dart
sealed class ProductDetailError {
  final String message;
  ProductDetailError(this.message);
}

class ProductNotFoundError extends ProductDetailError {
  ProductNotFoundError(String productId)
      : super('Product not found: $productId');
}

class ProductLoadError extends ProductDetailError {
  ProductLoadError(String message) : super(message);
}

class NetworkError extends ProductDetailError {
  NetworkError() : super('Network connection failed');
}

class UnauthorizedError extends ProductDetailError {
  UnauthorizedError() : super('Not authorized to view this product');
}
```

---

## Validation Rules

### Product Data Validation

- **Product ID**: Required, non-empty string
- **Title**: Required, 1-200 characters
- **Description**: Optional, max 5000 characters
- **Price**: Required, > 0
- **SKU**: Required, unique, 1-50 characters
- **Inventory**: Integer >= 0
- **Tags**: Each tag 1-50 characters, max 20 tags

---

## Caching Strategy

1. **Product Detail**: Cache for 5 minutes
2. **Images**: Cache indefinitely with URL-based invalidation
3. **Variants**: Cache with product detail
4. **Media Files**: Cache URLs, lazy load actual files

---

## Notes

- I18N fields require language parameter
- Timestamps are in ISO 8601 format (UTC)
- Prices are in smallest currency unit (e.g., cents for EUR/USD)
- Media URLs should be HTTPS only
- Null safety is enforced throughout
