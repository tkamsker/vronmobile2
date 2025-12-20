import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/services/token_storage.dart';

/// GraphQL client service
/// Provides configured GraphQL client with authentication support
class GraphQLService {
  final TokenStorage _tokenStorage;
  GraphQLClient? _client;

  GraphQLService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  /// Gets or creates the GraphQL client
  /// Configures authentication header if token is available
  Future<GraphQLClient> getClient() async {
    if (_client != null) {
      return _client!;
    }

    // Get access token if available
    final token = await _tokenStorage.getAccessToken();

    // Configure HTTP link
    final httpLink = HttpLink(
      EnvConfig.graphqlEndpoint,
    );

    // Configure auth link if token exists
    AuthLink? authLink;
    if (token != null && token.isNotEmpty) {
      authLink = AuthLink(
        getToken: () async => 'Bearer $token',
      );
    }

    // Combine links
    final Link link = authLink != null ? authLink.concat(httpLink) : httpLink;

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
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final client = await getClient();
    return await client.query(
      QueryOptions(
        document: gql(query),
        variables: variables ?? {},
      ),
    );
  }

  /// Executes a GraphQL mutation
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    final client = await getClient();
    return await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables ?? {},
      ),
    );
  }
}
