import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/products/models/product_detail.dart';

/// Service for fetching detailed product information via GraphQL API
class ProductDetailService {
  final GraphQLService _graphqlService;
  final String _language;

  ProductDetailService({GraphQLService? graphqlService, String language = 'EN'})
    : _graphqlService = graphqlService ?? GraphQLService(),
      _language = language;

  /// GraphQL query to fetch single product detail
  static const String _getProductQuery = '''
    query GetProduct(\$input: VRonGetProductInput!, \$lang: Language!) {
      VRonGetProduct(input: \$input) {
        title {
          text(lang: \$lang)
        }
        description {
          text(lang: \$lang)
        }
        status
        tags
        mediaFiles {
          id
          url
          filename
        }
        variants {
          id
          sku
          price
        }
      }
    }
  ''';

  /// Fetch product detail by ID
  /// Returns ProductDetail object or throws an exception on error
  Future<ProductDetail> getProductDetail(String productId) async {
    try {
      if (kDebugMode) {
        print(
          '📦 [PRODUCT DETAIL] Fetching product $productId (language: $_language)...',
        );
      }

      final result = await _graphqlService.query(
        _getProductQuery,
        variables: {
          'input': {'id': productId},
          'lang': _language,
        },
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print(
            '❌ [PRODUCT DETAIL] GraphQL exception: ${exception.toString()}',
          );
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PRODUCT DETAIL] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to fetch product detail: ${error.message}');
        }

        throw Exception(
          'Failed to fetch product detail: ${exception.toString()}',
        );
      }

      if (result.data == null || result.data!['VRonGetProduct'] == null) {
        if (kDebugMode)
          print('⚠️ [PRODUCT DETAIL] No product data in response');
        throw Exception('Product not found: $productId');
      }

      final productData =
          result.data!['VRonGetProduct'] as Map<String, dynamic>;
      final product = ProductDetail.fromJson(productData);

      if (kDebugMode) {
        print(
          '✅ [PRODUCT DETAIL] Fetched product: ${product.title} (${product.id})',
        );
        print('  - Status: ${product.statusLabel}');
        print('  - Media files: ${product.mediaFiles.length}');
        print('  - Variants: ${product.variants.length}');
      }

      return product;
    } catch (e) {
      if (kDebugMode) print('❌ [PRODUCT DETAIL] Error: ${e.toString()}');
      rethrow;
    }
  }
}
