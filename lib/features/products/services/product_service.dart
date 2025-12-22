import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/products/models/product.dart';

/// Service for managing product data via GraphQL API
/// Based on the VRon Products API specification
class ProductService {
  final GraphQLService _graphqlService;
  final String _language;

  ProductService({GraphQLService? graphqlService, String language = 'EN'})
      : _graphqlService = graphqlService ?? GraphQLService(),
        _language = language;

  /// GraphQL query to fetch products for a project
  /// Uses VRonGetProducts query from the API
  static const String _getProductsQuery = '''
    query GetProducts(\$input: VRonGetProductsInput!, \$lang: Language!) {
      VRonGetProducts(input: \$input) {
        products {
          id
          title {
            text(lang: \$lang)
          }
          thumbnail
          status
          category {
            text(lang: \$lang)
          }
          tracksInventory
          variantsCount
        }
        pagination {
          pageCount
        }
      }
    }
  ''';

  /// Fetch products with optional filtering and pagination
  /// Returns a list of Product objects or throws an exception on error
  Future<List<Product>> fetchProducts({
    List<String>? categoryIds,
    String? search,
    List<String>? status,
    bool? tracksInventory,
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    try {
      if (kDebugMode) {
        print('📦 [PRODUCTS] Fetching products (language: $_language)...');
        if (search != null) print('  - Search: $search');
        if (status != null) print('  - Status: $status');
      }

      // Build filter object
      final Map<String, dynamic> filter = {};
      if (categoryIds != null && categoryIds.isNotEmpty) {
        filter['categoryIds'] = categoryIds;
      }
      if (search != null && search.isNotEmpty) {
        filter['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        filter['status'] = status;
      }
      if (tracksInventory != null) {
        filter['tracksInventory'] = tracksInventory;
      }

      final result = await _graphqlService.query(
        _getProductsQuery,
        variables: {
          'input': {
            'filter': filter,
            'pagination': {
              'pageIndex': pageIndex,
              'pageSize': pageSize,
            },
          },
          'lang': _language,
        },
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PRODUCTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PRODUCTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to fetch products: ${error.message}');
        }

        throw Exception('Failed to fetch products: ${exception.toString()}');
      }

      if (result.data == null || result.data!['VRonGetProducts'] == null) {
        if (kDebugMode) print('⚠️ [PRODUCTS] No products data in response');
        return [];
      }

      final productsResponse = result.data!['VRonGetProducts'] as Map<String, dynamic>;
      final productsData = productsResponse['products'] as List?;

      if (productsData == null || productsData.isEmpty) {
        if (kDebugMode) print('✅ [PRODUCTS] No products found');
        return [];
      }

      final products = productsData
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('✅ [PRODUCTS] Fetched ${products.length} products');
        for (final product in products) {
          print('  - ${product.title} (${product.id}) - ${product.statusLabel}');
        }
      }

      return products;
    } catch (e) {
      if (kDebugMode) print('❌ [PRODUCTS] Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch only active products
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

  /// Search products by query string
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
}
