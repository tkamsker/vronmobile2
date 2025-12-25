import 'package:vronmobile2/features/products/models/product.dart';
import 'package:vronmobile2/features/products/services/product_service.dart';

/// Mock ProductService for testing
/// Provides predefined test data and simulates API behavior
class MockProductService implements ProductService {
  final List<Product> _mockProducts;
  final Duration _delay;
  final bool _shouldThrowError;
  final String? _errorMessage;

  MockProductService({
    List<Product>? mockProducts,
    Duration delay = const Duration(milliseconds: 100),
    bool shouldThrowError = false,
    String? errorMessage,
  })  : _mockProducts = mockProducts ?? _defaultMockProducts(),
        _delay = delay,
        _shouldThrowError = shouldThrowError,
        _errorMessage = errorMessage;

  @override
  Future<List<Product>> fetchProducts({
    List<String>? categoryIds,
    String? search,
    List<String>? status,
    bool? tracksInventory,
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    // Simulate network delay
    await Future.delayed(_delay);

    // Simulate error
    if (_shouldThrowError) {
      throw Exception(_errorMessage ?? 'Mock error');
    }

    // Filter products based on parameters
    var filtered = List<Product>.from(_mockProducts);

    // Filter by search query
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(search.toLowerCase());
      }).toList();
    }

    // Filter by status
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((p) {
        return status.contains(p.status);
      }).toList();
    }

    // Filter by category
    if (categoryIds != null && categoryIds.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.category != null && categoryIds.contains(p.category);
      }).toList();
    }

    return filtered;
  }

  @override
  Future<List<Product>> fetchActiveProducts({
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    return fetchProducts(
      status: ['ACTIVE'],
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<Product>> searchProducts(
    String query, {
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    return fetchProducts(
      search: query,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  /// Default mock products for testing
  static List<Product> _defaultMockProducts() {
    return [
      Product(
        id: '1',
        title: 'Steam Punk Goggles',
        status: 'ACTIVE',
        thumbnail: 'https://example.com/steam-punk.jpg',
        category: 'Accessories',
        tracksInventory: true,
        variantsCount: 3,
      ),
      Product(
        id: '2',
        title: 'Victorian Hat',
        status: 'DRAFT',
        thumbnail: 'https://example.com/victorian-hat.jpg',
        category: 'Clothing',
        tracksInventory: false,
        variantsCount: 1,
      ),
      Product(
        id: '3',
        title: 'Clockwork Mechanism',
        status: 'ACTIVE',
        thumbnail: 'https://example.com/clockwork.jpg',
        category: 'Accessories',
        tracksInventory: true,
        variantsCount: 5,
      ),
      Product(
        id: '4',
        title: 'Leather Jacket',
        status: 'ACTIVE',
        thumbnail: 'https://example.com/leather-jacket.jpg',
        category: 'Clothing',
        tracksInventory: true,
        variantsCount: 2,
      ),
      Product(
        id: '5',
        title: 'Brass Compass',
        status: 'DRAFT',
        thumbnail: 'https://example.com/brass-compass.jpg',
        category: 'Accessories',
        tracksInventory: false,
        variantsCount: 1,
      ),
    ];
  }
}
