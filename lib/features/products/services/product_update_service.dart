import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';

/// Service for updating products via GraphQL API
class ProductUpdateService {
  final GraphQLService _graphqlService;

  ProductUpdateService({GraphQLService? graphqlService})
      : _graphqlService = graphqlService ?? GraphQLService();

  /// GraphQL mutation to update product
  static const String _updateProductMutation = '''
    mutation UpdateProduct(\$input: VRonUpdateProductInput!) {
      VRonUpdateProduct(input: \$input)
    }
  ''';

  /// Update product with new data
  /// Returns true if successful, throws exception on error
  Future<bool> updateProduct({
    required String productId,
    String? title,
    String? description,
    String? status,
    List<String>? tags,
    String? categoryId,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 [PRODUCT UPDATE] Updating product $productId...');
      }

      // Build input object with only provided fields
      final Map<String, dynamic> input = {'id': productId};

      if (title != null) input['title'] = title;
      if (description != null) input['description'] = description;
      if (status != null) input['status'] = status;
      if (tags != null) input['tags'] = tags;
      if (categoryId != null) input['categoryId'] = categoryId;

      final result = await _graphqlService.mutate(
        _updateProductMutation,
        variables: {'input': input},
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PRODUCT UPDATE] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PRODUCT UPDATE] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to update product: ${error.message}');
        }

        throw Exception('Failed to update product: ${exception.toString()}');
      }

      if (result.data == null) {
        if (kDebugMode) print('⚠️ [PRODUCT UPDATE] No data in response');
        throw Exception('Failed to update product: No data returned');
      }

      if (kDebugMode) {
        print('✅ [PRODUCT UPDATE] Product updated successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ [PRODUCT UPDATE] Error: ${e.toString()}');
      rethrow;
    }
  }
}
