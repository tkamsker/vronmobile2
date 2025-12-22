import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_variant.dart';

void main() {
  group('ProductVariant', () {
    group('fromJson', () {
      test('T004: parses complete JSON correctly', () {
        // Arrange
        final json = {
          'id': 'var_123',
          'sku': 'PROD-BLK-001',
          'price': 99.99,
          'compareAtPrice': 129.99,
          'inventoryPolicy': 'DENY',
          'inventoryQuantity': 15,
          'weight': 5.5,
          'weightUnit': 'kg',
        };

        // Act
        final variant = ProductVariant.fromJson(json);

        // Assert
        expect(variant.id, 'var_123');
        expect(variant.sku, 'PROD-BLK-001');
        expect(variant.price, 99.99);
        expect(variant.compareAtPrice, 129.99);
        expect(variant.inventoryPolicy, 'DENY');
        expect(variant.inventoryQuantity, 15);
        expect(variant.weight, 5.5);
        expect(variant.weightUnit, 'kg');
      });

      test('parses JSON with null optional fields', () {
        // Arrange
        final json = {
          'id': 'var_123',
          'sku': 'PROD-001',
          'price': 49.99,
          'inventoryQuantity': 10,
        };

        // Act
        final variant = ProductVariant.fromJson(json);

        // Assert
        expect(variant.id, 'var_123');
        expect(variant.sku, 'PROD-001');
        expect(variant.price, 49.99);
        expect(variant.compareAtPrice, isNull);
        expect(variant.inventoryPolicy, 'CONTINUE'); // Default
        expect(variant.inventoryQuantity, 10);
        expect(variant.weight, isNull);
        expect(variant.weightUnit, isNull);
      });

      test('handles integer prices as doubles', () {
        // Arrange
        final json = {
          'id': 'var_123',
          'sku': 'PROD-001',
          'price': 50, // Integer
          'compareAtPrice': 75, // Integer
          'inventoryQuantity': 5,
        };

        // Act
        final variant = ProductVariant.fromJson(json);

        // Assert
        expect(variant.price, 50.0);
        expect(variant.compareAtPrice, 75.0);
      });
    });

    group('hasDiscount', () {
      test('T005: returns true when compareAtPrice is greater than price', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 79.99,
          compareAtPrice: 99.99,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.hasDiscount, isTrue);
      });

      test('returns false when compareAtPrice is null', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 79.99,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.hasDiscount, isFalse);
      });

      test('returns false when compareAtPrice equals price', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 79.99,
          compareAtPrice: 79.99,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.hasDiscount, isFalse);
      });

      test('returns false when compareAtPrice is less than price', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 99.99,
          compareAtPrice: 79.99,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.hasDiscount, isFalse);
      });
    });

    group('discountPercentage', () {
      test('calculates discount percentage correctly', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 75.0,
          compareAtPrice: 100.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.discountPercentage, 25.0); // 25% off
      });

      test('returns 0 when no discount', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 79.99,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.discountPercentage, 0.0);
      });

      test('handles fractional discount percentages', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 66.67,
          compareAtPrice: 100.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act
        final discount = variant.discountPercentage;

        // Assert
        expect(discount, closeTo(33.33, 0.01)); // ~33.33% off
      });
    });

    group('inventory status', () {
      test('T006: isInStock returns true when inventory > 0', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.isInStock, isTrue);
      });

      test('isInStock returns false when inventory is 0', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 0,
        );

        // Act & Assert
        expect(variant.isInStock, isFalse);
      });

      test('isLowStock returns true when inventory is between 1-5', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 3,
        );

        // Act & Assert
        expect(variant.isLowStock, isTrue);
      });

      test('isLowStock returns false when inventory > 5', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 10,
        );

        // Act & Assert
        expect(variant.isLowStock, isFalse);
      });

      test('isOutOfStock returns true when inventory is 0', () {
        // Arrange
        final variant = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 0,
        );

        // Act & Assert
        expect(variant.isOutOfStock, isTrue);
      });

      test('inventoryStatusLabel returns correct labels', () {
        // Out of stock
        final outOfStock = ProductVariant(
          id: 'var_1',
          sku: 'PROD-001',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 0,
        );
        expect(outOfStock.inventoryStatusLabel, 'Out of stock');

        // Low stock
        final lowStock = ProductVariant(
          id: 'var_2',
          sku: 'PROD-002',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 3,
        );
        expect(lowStock.inventoryStatusLabel, 'Low stock');

        // In stock
        final inStock = ProductVariant(
          id: 'var_3',
          sku: 'PROD-003',
          price: 50.0,
          inventoryPolicy: 'CONTINUE',
          inventoryQuantity: 20,
        );
        expect(inStock.inventoryStatusLabel, 'In stock');
      });
    });
  });
}
