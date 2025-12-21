import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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

  /// Initialize GraphQL client with optional auth token
  void initialize({String? authToken}) {
    _authToken = authToken;

    final HttpLink httpLink = HttpLink(apiEndpoint);

    // Add auth link if token is provided
    Link link = httpLink;
    if (_authToken != null) {
      final AuthLink authLink = AuthLink(
        getToken: () async => 'Bearer $_authToken',
      );
      link = authLink.concat(httpLink);
    }

    _client = GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.networkOnly),
        mutate: Policies(fetch: FetchPolicy.networkOnly),
      ),
    );
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
    _authToken = token;
    initialize(authToken: token);
  }

  /// Clear auth token and reinitialize client
  void clearAuthToken() {
    _authToken = null;
    initialize();
  }

  /// Execute GraphQL query
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: variables ?? {},
    );

    return await client.query(options);
  }

  /// Execute GraphQL mutation
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(mutation),
      variables: variables ?? {},
    );

    return await client.mutate(options);
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
