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
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final client = await getClient();
    return await client.query(
      QueryOptions(document: gql(query), variables: variables ?? {}),
    );
  }

  /// Executes a GraphQL mutation
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    final client = await getClient();
    return await client.mutate(
      MutationOptions(document: gql(mutation), variables: variables ?? {}),
    );
  }
}
