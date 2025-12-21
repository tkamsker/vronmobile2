import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:vronmobile2/core/config/env_config.dart';

/// GraphQL service for API communication with VRon backend
class GraphQLService {
  static final GraphQLService _instance = GraphQLService._internal();
  factory GraphQLService() => _instance;
  GraphQLService._internal();

  GraphQLClient? _client;
  String? _authToken;

  /// API endpoint for VRon GraphQL API
  static const String apiEndpoint =
      'https://api.vron.stage.motorenflug.at/graphql';

  bool get _isDebug => EnvConfig.isDebug;

  /// Initialize GraphQL client with optional auth token
  void initialize({String? authToken}) {
    _authToken = authToken;

    if (_isDebug) {
      print('🔧 [GRAPHQL] Initializing GraphQL client...');
      print('🔧 [GRAPHQL] Service instance ID: ${identityHashCode(this)}');
      print('🔧 [GRAPHQL] Endpoint: $apiEndpoint');
      if (_authToken != null) {
        final tokenPreview = _authToken!.length > 40
            ? '${_authToken!.substring(0, 40)}...'
            : _authToken;
        print('🔧 [GRAPHQL] Auth token set: $tokenPreview');
        print('🔧 [GRAPHQL] Token length: ${_authToken!.length} characters');
      } else {
        print('⚠️  [GRAPHQL] No auth token provided - client will be unauthenticated');
      }
    }

    // Create HTTP link with custom headers
    final HttpLink httpLink = HttpLink(
      apiEndpoint,
      defaultHeaders: {
        'X-VRon-Platform': 'merchants',
      },
    );

    if (_isDebug) {
      print('🔧 [GRAPHQL] HTTP headers configured:');
      print('   - X-VRon-Platform: merchants');
    }

    // Add auth link if token is provided
    Link link = httpLink;
    if (_authToken != null) {
      final AuthLink authLink = AuthLink(
        getToken: () async {
          if (_isDebug) {
            print('🔑 [GRAPHQL] AuthLink.getToken() called');
            print('🔑 [GRAPHQL] Returning: Bearer ${_authToken!.substring(0, 40)}...');
          }
          return 'Bearer $_authToken';
        },
      );
      link = authLink.concat(httpLink);
      if (_isDebug) print('✅ [GRAPHQL] AuthLink configured');
    }

    _client = GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.networkOnly),
        mutate: Policies(fetch: FetchPolicy.networkOnly),
      ),
    );

    if (_isDebug) {
      print('✅ [GRAPHQL] Client initialized successfully');
      print('✅ [GRAPHQL] Client instance ID: ${identityHashCode(_client)}');
    }
  }

  /// Get GraphQL client instance
  GraphQLClient get client {
    if (_client == null) {
      initialize();
    }
    return _client!;
  }

  /// Update auth token and reinitialize client
  void setAuthToken(String token) {
    if (_isDebug) {
      print('🔐 [GRAPHQL] setAuthToken() called');
      print('🔐 [GRAPHQL] Token length: ${token.length} characters');
      final tokenPreview = token.length > 40
          ? '${token.substring(0, 40)}...'
          : token;
      print('🔐 [GRAPHQL] Token preview: $tokenPreview');
    }
    _authToken = token;
    initialize(authToken: token);
  }

  /// Clear auth token and reinitialize client
  void clearAuthToken() {
    if (_isDebug) print('🔓 [GRAPHQL] clearAuthToken() called');
    _authToken = null;
    initialize();
  }

  /// Refresh client (reinitialize with current auth token)
  Future<void> refreshClient() async {
    if (_isDebug) {
      print('🔄 [GRAPHQL] refreshClient() called');
      print('🔄 [GRAPHQL] Current token: ${_authToken != null ? "SET" : "NULL"}');
    }
    initialize(authToken: _authToken);
  }

  /// Execute GraphQL query
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    if (_isDebug) {
      print('📤 [GRAPHQL] Executing query...');
      print('📤 [GRAPHQL] Query: ${query.split('\n').first}...');
      print('📤 [GRAPHQL] Full query:\n$query');
      print('📤 [GRAPHQL] Variables: $variables');
      print('📤 [GRAPHQL] Client instance ID: ${identityHashCode(client)}');
      print('📤 [GRAPHQL] Has auth token: ${_authToken != null}');
    }

    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: variables ?? {},
    );

    final result = await client.query(options);

    if (_isDebug) {
      print('📥 [GRAPHQL] Query result received');
      print('📥 [GRAPHQL] Has exception: ${result.hasException}');
      print('📥 [GRAPHQL] Has data: ${result.data != null}');
      if (result.hasException) {
        print('❌ [GRAPHQL] Exception: ${result.exception}');
      }
    }

    return result;
  }

  /// Execute GraphQL mutation
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    if (_isDebug) {
      print('📤 [GRAPHQL] Executing mutation...');
      print('📤 [GRAPHQL] Mutation: ${mutation.split('\n').first}...');
      print('📤 [GRAPHQL] Variables: $variables');
      print('📤 [GRAPHQL] Has auth token: ${_authToken != null}');
    }

    final MutationOptions options = MutationOptions(
      document: gql(mutation),
      variables: variables ?? {},
    );

    final result = await client.mutate(options);

    if (_isDebug) {
      print('📥 [GRAPHQL] Mutation result received');
      print('📥 [GRAPHQL] Has exception: ${result.hasException}');
      print('📥 [GRAPHQL] Has data: ${result.data != null}');
    }

    return result;
  }

  /// Handle query/mutation result and extract data or throw error
  T handleResult<T>(
    QueryResult result,
    T Function(Map<String, dynamic> data) onSuccess,
  ) {
    if (result.hasException) {
      debugPrint('GraphQL Error: ${result.exception.toString()}');
      throw Exception(_parseError(result.exception!));
    }

    if (result.data == null) {
      throw Exception('No data returned from GraphQL query');
    }

    return onSuccess(result.data!);
  }

  /// Parse GraphQL exception to user-friendly error message
  String _parseError(OperationException exception) {
    if (exception.linkException != null) {
      final linkException = exception.linkException;
      if (linkException is NetworkException) {
        return 'Network error. Please check your internet connection.';
      } else if (linkException is ServerException) {
        return 'Server error. Please try again later.';
      }
      return 'Connection error. Please try again.';
    }

    if (exception.graphqlErrors.isNotEmpty) {
      final error = exception.graphqlErrors.first;
      return error.message;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
