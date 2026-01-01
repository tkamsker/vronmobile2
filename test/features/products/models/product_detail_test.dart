import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_detail.dart';

void main() {
  group('ProductDetail', () {
    group('fromJson', () {
      test('T007: parses complete JSON correctly', () {
        // Arrange
        final json = {
          'id': 'prod_123',
          'title': {'text': 'Virtual Chair'},
          'description': {'text': 'A comfortable modern chair'},
          'thumbnail': 'https://cdn.example.com/chair.jpg',
          'status': 'ACTIVE',
          'category': {'text': 'Furniture'},
          'tags': ['furniture', 'seating', 'modern'],
          'tracksInventory': true,
          'mediaFiles': [
            {
              'id': 'media_1',
              'url': 'https://cdn.example.com/image1.jpg',
              'filename': 'chair_front.jpg',
              'mimeType': 'image/jpeg',
              'size': 245678,
            },
          ],
          'variants': [
            {
              'id': 'var_1',
              'sku': 'CHAIR-BLK-001',
              'price': 99.99,
              'compareAtPrice': 129.99,
              'inventoryPolicy': 'DENY',
              'inventoryQuantity': 15,
            },
          ],
          'createdAt': '2025-01-15T10:30:00Z',
          'updatedAt': '2025-12-20T14:20:00Z',
        };

        // Act
        final product = ProductDetail.fromJson(json);

        // Assert
        expect(product.id, 'prod_123');
        expect(product.title, 'Virtual Chair');
        expect(product.description, 'A comfortable modern chair');
        expect(product.thumbnail, 'https://cdn.example.com/chair.jpg');
        expect(product.status, 'ACTIVE');
        expect(product.category, 'Furniture');
        expect(product.tags, ['furniture', 'seating', 'modern']);
        expect(product.tracksInventory, true);
        expect(product.mediaFiles.length, 1);
        expect(product.variants.length, 1);
        expect(product.createdAt, isNotNull);
        expect(product.updatedAt, isNotNull);
      });

      test('T008: parses JSON with null optional fields', () {
        // Arrange
        final json = {
          'id': 'prod_123',
          'title': {'text': 'Test Product'},
          'description': {'text': ''},
          'status': 'DRAFT',
          'tags': [],
          'tracksInventory': false,
          'mediaFiles': [],
          'variants': [],
        };

        // Act
        final product = ProductDetail.fromJson(json);

        // Assert
        expect(product.id, 'prod_123');
        expect(product.title, 'Test Product');
        expect(product.description, '');
        expect(product.thumbnail, isNull);
        expect(product.status, 'DRAFT');
        expect(product.category, isNull);
        expect(product.tags, isEmpty);
        expect(product.tracksInventory, false);
        expect(product.mediaFiles, isEmpty);
        expect(product.variants, isEmpty);
        expect(product.createdAt, isNull);
        expect(product.updatedAt, isNull);
      });

      test('parses nested I18N fields correctly', () {
        // Arrange
        final json = {
          'id': 'prod_123',
          'title': {'text': 'English Title'},
          'description': {'text': 'English Description'},
          'status': 'ACTIVE',
          'category': {'text': 'Test Category'},
          'tags': [],
          'tracksInventory': false,
          'mediaFiles': [],
          'variants': [],
        };

        // Act
        final product = ProductDetail.fromJson(json);

        // Assert
        expect(product.title, 'English Title');
        expect(product.description, 'English Description');
        expect(product.category, 'Test Category');
      });

      test('handles media files array correctly', () {
        // Arrange
        final json = {
          'id': 'prod_123',
          'title': {'text': 'Product'},
          'description': {'text': ''},
          'status': 'ACTIVE',
          'tags': [],
          'tracksInventory': false,
          'mediaFiles': [
            {
              'id': 'm1',
              'url': 'http://example.com/1.jpg',
              'filename': '1.jpg',
            },
            {
              'id': 'm2',
              'url': 'http://example.com/2.jpg',
              'filename': '2.jpg',
            },
          ],
          'variants': [],
        };

        // Act
        final product = ProductDetail.fromJson(json);

        // Assert
        expect(product.mediaFiles.length, 2);
        expect(product.mediaFiles[0].id, 'm1');
        expect(product.mediaFiles[1].id, 'm2');
      });

      test('handles variants array correctly', () {
        // Arrange
        final json = {
          'id': 'prod_123',
          'title': {'text': 'Product'},
          'description': {'text': ''},
          'status': 'ACTIVE',
          'tags': [],
          'tracksInventory': false,
          'mediaFiles': [],
          'variants': [
            {
              'id': 'v1',
              'sku': 'SKU-001',
              'price': 10.0,
              'inventoryPolicy': 'CONTINUE',
              'inventoryQuantity': 5,
            },
            {
              'id': 'v2',
              'sku': 'SKU-002',
              'price': 20.0,
              'inventoryPolicy': 'CONTINUE',
              'inventoryQuantity': 10,
            },
          ],
        };

        // Act
        final product = ProductDetail.fromJson(json);

        // Assert
        expect(product.variants.length, 2);
        expect(product.variants[0].sku, 'SKU-001');
        expect(product.variants[1].sku, 'SKU-002');
      });
    });

    group('helper methods', () {
      test('isActive returns true for ACTIVE status', () {
        // Arrange
        final product = ProductDetail(
          id: 'prod_1',
          title: 'Product',
          description: '',
          status: 'ACTIVE',
          tags: [],
          tracksInventory: false,
          mediaFiles: [],
          variants: [],
        );

        // Act & Assert
        expect(product.isActive, true);
      });

      test('isActive returns false for DRAFT status', () {
        // Arrange
        final product = ProductDetail(
          id: 'prod_1',
          title: 'Product',
          description: '',
          status: 'DRAFT',
          tags: [],
          tracksInventory: false,
          mediaFiles: [],
          variants: [],
        );

        // Act & Assert
        expect(product.isActive, false);
      });

      test('statusLabel returns correct labels', () {
        final active = ProductDetail(
          id: 'prod_1',
          title: 'Product',
          description: '',
          status: 'ACTIVE',
          tags: [],
          tracksInventory: false,
          mediaFiles: [],
          variants: [],
        );
        expect(active.statusLabel, 'Active');

        final draft = ProductDetail(
          id: 'prod_2',
          title: 'Product',
          description: '',
          status: 'DRAFT',
          tags: [],
          tracksInventory: false,
          mediaFiles: [],
          variants: [],
        );
        expect(draft.statusLabel, 'Draft');
      });
    });
  });
}
