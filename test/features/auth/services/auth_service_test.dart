import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:vronmobile2/features/auth/services/auth_service.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/core/services/token_storage.dart';

// Mock classes for testing
class MockGraphQLService extends GraphQLService {
  QueryResult? mockResult;
  Exception? mockException;

  @override
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }
    return mockResult!;
  }

  @override
  Future<GraphQLClient> refreshClient() async {
    // Mock implementation - do nothing
    return GraphQLClient(
      link: HttpLink('http://localhost'),
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}

class MockTokenStorage extends TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> deleteAllTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasAccessToken() async {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }
}

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    late MockGraphQLService mockGraphQLService;
    late MockTokenStorage mockTokenStorage;
    late AuthService authService;

    // Valid GraphQL document for mocking
    final mockDocument = gql('''
      mutation Login(\$email: String!, \$password: String!) {
        login(email: \$email, password: \$password) {
          token
          user {
            id
            email
          }
        }
      }
    ''');

    setUp(() {
      mockGraphQLService = MockGraphQLService();
      mockTokenStorage = MockTokenStorage();
      authService = AuthService(
        graphqlService: mockGraphQLService,
        tokenStorage: mockTokenStorage,
      );
    });

    group('login', () {
      test('successful login stores token and returns user data', () async {
        // Arrange
        final mockData = {
          'login': {
            'token': 'test-access-token',
            'user': {
              'id': '123',
              'email': 'user@example.com',
            },
          },
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final result = await authService.login(
          email: 'user@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?['id'], '123');
        expect(result.data?['email'], 'user@example.com');

        // Verify token was stored
        final storedToken = await mockTokenStorage.getAccessToken();
        expect(storedToken, 'test-access-token');
      });

      test('login with invalid credentials returns error', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message: 'Invalid credentials',
                extensions: {'code': 'INVALID_CREDENTIALS'},
              ),
            ],
          ),
        );

        // Act
        final result = await authService.login(
          email: 'user@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Invalid credentials'));

        // Verify no token was stored
        final storedToken = await mockTokenStorage.getAccessToken();
        expect(storedToken, isNull);
      });

      test('login with network error returns error', () async {
        // Arrange
        mockGraphQLService.mockException = Exception('Network error');

        // Act
        final result = await authService.login(
          email: 'user@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Network error'));
      });

      test('login with empty email returns validation error', () async {
        // Act
        final result = await authService.login(
          email: '',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Email'));
      });

      test('login with empty password returns validation error', () async {
        // Act
        final result = await authService.login(
          email: 'user@example.com',
          password: '',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Password'));
      });
    });

    group('logout', () {
      test('logout clears stored tokens', () async {
        // Arrange - store a token first
        await mockTokenStorage.saveAccessToken('test-token');
        expect(await mockTokenStorage.hasAccessToken(), true);

        // Act
        await authService.logout();

        // Assert
        expect(await mockTokenStorage.hasAccessToken(), false);
      });
    });

    group('isAuthenticated', () {
      test('returns true when token exists', () async {
        // Arrange
        await mockTokenStorage.saveAccessToken('test-token');

        // Act
        final isAuthenticated = await authService.isAuthenticated();

        // Assert
        expect(isAuthenticated, true);
      });

      test('returns false when no token exists', () async {
        // Act
        final isAuthenticated = await authService.isAuthenticated();

        // Assert
        expect(isAuthenticated, false);
      });
    });
  });
}
