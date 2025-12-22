import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_detail.dart';
import 'package:vronmobile2/features/products/screens/product_detail_screen.dart';
import 'package:vronmobile2/features/products/services/product_detail_service.dart';

void main() {
  group('ProductDetailScreen', () {
    group('T027: Loading State', () {
      testWidgets('displays loading indicator while fetching product',
          (WidgetTester tester) async {
        // Arrange
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            shouldDelay: true,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pump(); // Just one pump to see initial loading state

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading product...'), findsOneWidget);

        // Complete the delayed future to avoid pending timers
        await tester.pumpAndSettle();
      });

      testWidgets('loading state has proper accessibility labels',
          (WidgetTester tester) async {
        // Arrange
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            shouldDelay: true,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pump();

        // Assert
        final semantics = tester.getSemantics(find.byType(CircularProgressIndicator));
        expect(semantics.label, contains('Loading'));

        // Complete the delayed future to avoid pending timers
        await tester.pumpAndSettle();
      });
    });

    group('T028: Error State', () {
      testWidgets('displays error message when fetch fails',
          (WidgetTester tester) async {
        // Arrange
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            shouldError: true,
            errorMessage: 'Failed to load product',
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Failed to load product'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry button reloads product data',
          (WidgetTester tester) async {
        // Arrange
        final mockService = MockProductDetailService(
          shouldError: true,
          errorMessage: 'Network error',
        );
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: mockService,
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Tap retry button
        mockService.shouldError = false; // Succeed on retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(mockService.fetchCallCount, 2);
      });

      testWidgets('error state has proper accessibility',
          (WidgetTester tester) async {
        // Arrange
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            shouldError: true,
            errorMessage: 'Failed to load product',
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert - Check retry button exists and is accessible
        final retryButton = find.text('Retry');
        expect(retryButton, findsOneWidget);
        // Verify button is tappable
        await tester.tap(retryButton);
      });
    });

    group('T029: Success State with Data', () {
      testWidgets('displays product detail when loaded successfully',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = _createMockProductDetail();
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert - Use description which is unique to body (title appears in AppBar too)
        expect(find.text('A comfortable modern chair'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Furniture'), findsOneWidget);
      });

      testWidgets('displays media gallery when media files present',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = _createMockProductDetail();
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Media'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('displays variants section when variants present',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = _createMockProductDetail();
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Variants'), findsOneWidget);
        expect(find.text('CHAIR-BLK-001'), findsOneWidget);
        expect(find.text('\$99.99'), findsOneWidget);
      });

      testWidgets('displays tags when present',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = _createMockProductDetail();
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('furniture'), findsOneWidget);
        expect(find.text('seating'), findsOneWidget);
        expect(find.text('modern'), findsOneWidget);
      });
    });

    group('T030: Empty/Minimal Data State', () {
      testWidgets('displays product with no media files',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = ProductDetail(
          id: 'prod_123',
          title: 'Test Product',
          description: 'Test description',
          status: 'DRAFT',
          tags: [],
          tracksInventory: false,
          mediaFiles: [], // No media files
          variants: [],
        );
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Test description'), findsOneWidget);
        expect(find.text('No media files'), findsOneWidget);
      });

      testWidgets('displays product with no variants',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = ProductDetail(
          id: 'prod_123',
          title: 'Test Product',
          description: 'Test description',
          status: 'DRAFT',
          tags: [],
          tracksInventory: false,
          mediaFiles: [],
          variants: [], // No variants
        );
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Test description'), findsOneWidget);
        expect(find.text('No variants'), findsOneWidget);
      });

      testWidgets('displays product with no tags',
          (WidgetTester tester) async {
        // Arrange
        final mockProduct = ProductDetail(
          id: 'prod_123',
          title: 'Test Product',
          description: 'Test description',
          status: 'DRAFT',
          tags: [], // No tags
          tracksInventory: false,
          mediaFiles: [],
          variants: [],
        );
        final screen = ProductDetailScreen(
          productId: 'prod_123',
          productDetailService: MockProductDetailService(
            mockProduct: mockProduct,
          ),
        );

        // Act
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Test description'), findsOneWidget);
        // Tags section should not be shown
        expect(find.text('Tags'), findsNothing);
      });
    });
  });
}

/// Mock ProductDetailService for testing
class MockProductDetailService extends ProductDetailService {
  final bool shouldDelay;
  bool shouldError;
  final String? errorMessage;
  final ProductDetail? mockProduct;
  int fetchCallCount = 0;

  MockProductDetailService({
    this.shouldDelay = false,
    this.shouldError = false,
    this.errorMessage,
    this.mockProduct,
  });

  @override
  Future<ProductDetail> getProductDetail(String productId) async {
    fetchCallCount++;

    if (shouldDelay) {
      await Future.delayed(const Duration(seconds: 10));
    }

    if (shouldError) {
      throw Exception(errorMessage ?? 'Failed to fetch product');
    }

    return mockProduct ?? _createMockProductDetail();
  }
}

/// Helper to create mock product detail for testing
ProductDetail _createMockProductDetail() {
  return ProductDetail.fromJson({
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
      }
    ],
    'variants': [
      {
        'id': 'var_1',
        'sku': 'CHAIR-BLK-001',
        'price': 99.99,
        'compareAtPrice': 129.99,
        'inventoryPolicy': 'DENY',
        'inventoryQuantity': 15,
      }
    ],
    'createdAt': '2025-01-15T10:30:00Z',
    'updatedAt': '2025-12-20T14:20:00Z',
  });
}
