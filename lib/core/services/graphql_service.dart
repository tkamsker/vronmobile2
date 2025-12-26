import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/services/token_storage.dart';
import 'package:vronmobile2/main.dart';

/// GraphQL client service
/// Provides configured GraphQL client with authentication support
class GraphQLService {
  final TokenStorage _tokenStorage;
  GraphQLClient? _client;

  GraphQLService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  /// Gets or creates the GraphQL client
  /// Configures authentication header with AUTH_CODE if available
  /// Also adds X-VRon-Platform header for merchant platform
  Future<GraphQLClient> getClient() async {
    if (_client != null) {
      return _client!;
    }

    // Get AUTH_CODE if available
    final authCode = await _tokenStorage.getAuthCode();

    // Configure HTTP link with headers
    final httpLink = HttpLink(
      EnvConfig.graphqlEndpoint,
      defaultHeaders: {'X-VRon-Platform': 'merchants'},
    );

    Link link = httpLink;

    // Configure auth link if AUTH_CODE exists
    if (authCode != null && authCode.isNotEmpty) {
      final authLink = AuthLink(getToken: () async => 'Bearer $authCode');
      link = authLink.concat(httpLink);
    }

    // Create client
    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );

    return _client!;
  }

  /// Creates a new client with updated authentication
  /// Call this after login/logout to refresh the auth token
  Future<GraphQLClient> refreshClient() async {
    _client = null;
    return await getClient();
  }

  /// Executes a GraphQL query
  /// Blocks all backend calls in guest mode (FR-005, SC-003)
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    // Guest mode check - block all backend calls
    if (guestSessionManager.isGuestMode) {
      if (kDebugMode) {
        print('❌ [GUEST] Backend query blocked: $query');
        throw StateError('Backend operation not allowed in guest mode: $query');
      } else {
        print('⚠️ [GUEST] Backend query blocked silently');
      }
      return QueryResult(
        data: {},
        exception: null,
        source: QueryResultSource.cache,
        options: QueryOptions(document: gql(query), variables: variables ?? {}),
      );
    }

    final client = await getClient();
    return await client.query(
      QueryOptions(document: gql(query), variables: variables ?? {}),
    );
  }

  /// Executes a GraphQL mutation
  /// Blocks all backend calls in guest mode (FR-005, SC-003)
  /// EXCEPT authentication mutations (signIn, signInWithGoogle) which allow users to exit guest mode
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    // Check if this is an authentication mutation
    final isAuthMutation =
        mutation.contains('signIn') ||
        mutation.contains('signInWithGoogle') ||
        mutation.contains('SignIn');

    // Guest mode check - block all backend calls EXCEPT authentication
    if (guestSessionManager.isGuestMode && !isAuthMutation) {
      if (kDebugMode) {
        print('❌ [GUEST] Backend mutation blocked: $mutation');
        throw StateError(
          'Backend operation not allowed in guest mode: $mutation',
        );
      } else {
        print('⚠️ [GUEST] Backend mutation blocked silently');
      }
      return QueryResult(
        data: {},
        exception: null,
        source: QueryResultSource.cache,
        options: MutationOptions(
          document: gql(mutation),
          variables: variables ?? {},
        ),
      );
    }

    if (kDebugMode && guestSessionManager.isGuestMode && isAuthMutation) {
      print('✅ [GUEST] Allowing authentication mutation in guest mode');
    }

    final client = await getClient();
    return await client.mutate(
      MutationOptions(document: gql(mutation), variables: variables ?? {}),
    );
  }

  /// Upload file using GraphQL multipart request
  /// Implements GraphQL multipart request spec for file uploads
  ///
  /// Parameters:
  /// - mutation: GraphQL mutation string
  /// - filePath: Local filesystem path to file
  /// - fileFieldName: Field name in mutation for file (e.g., "file")
  /// - variables: Additional mutation variables
  /// - onProgress: Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns: Parsed JSON response from server
  ///
  /// Throws: Exception if upload fails or file doesn't exist
  Future<Map<String, dynamic>> uploadFile({
    required String mutation,
    required String filePath,
    required String fileFieldName,
    Map<String, dynamic>? variables,
    void Function(double progress)? onProgress,
  }) async {
    // Guest mode check - block file uploads in guest mode
    if (guestSessionManager.isGuestMode) {
      if (kDebugMode) {
        print('❌ [GUEST] File upload blocked in guest mode');
      }
      throw StateError('File upload not allowed in guest mode');
    }

    // Validate file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Get auth token
    final authCode = await _tokenStorage.getAuthCode();
    final headers = {
      'X-VRon-Platform': 'merchants',
      if (authCode != null && authCode.isNotEmpty)
        'Authorization': 'Bearer $authCode',
    };

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(EnvConfig.graphqlEndpoint));
    request.headers.addAll(headers);

    // Add GraphQL operations (per multipart spec)
    final operations = {
      'query': mutation,
      'variables': {
        ...?variables,
        fileFieldName: null, // Placeholder for file
      },
    };
    request.fields['operations'] = jsonEncode(operations);

    // Map file to variable (per multipart spec)
    request.fields['map'] = jsonEncode({
      '0': ['variables.$fileFieldName']
    });

    // Add file
    final fileBytes = await file.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      '0', // Matches the key in 'map'
      fileBytes,
      filename: file.path.split('/').last,
    );
    request.files.add(multipartFile);

    // Send request with progress tracking
    final streamedResponse = await request.send();

    // Track upload progress if callback provided
    if (onProgress != null) {
      var bytesUploaded = 0;
      final totalBytes = fileBytes.length;

      streamedResponse.stream.listen(
        (chunk) {
          bytesUploaded += chunk.length;
          final progress = bytesUploaded / totalBytes;
          onProgress(progress);
        },
        onDone: () => onProgress(1.0),
      );
    }

    // Get response
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Upload failed with status ${response.statusCode}: ${response.body}',
      );
    }

    // Parse response
    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for GraphQL errors
    if (jsonResponse.containsKey('errors')) {
      final errors = jsonResponse['errors'] as List;
      throw Exception('GraphQL errors: ${errors.map((e) => e['message']).join(', ')}');
    }

    return jsonResponse['data'] as Map<String, dynamic>;
  }
}
