import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/core/services/token_storage.dart';

/// Result wrapper for authentication operations
class AuthResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory AuthResult.success(Map<String, dynamic> data) {
    return AuthResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Authentication service
/// Handles user authentication, token management, and session state
class AuthService {
  final GraphQLService _graphqlService;
  final TokenStorage _tokenStorage;

  AuthService({
    GraphQLService? graphqlService,
    TokenStorage? tokenStorage,
  })  : _graphqlService = graphqlService ?? GraphQLService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// GraphQL mutation for email/password login
  static const String _loginMutation = '''
    mutation Login(\$email: String!, \$password: String!) {
      login(email: \$email, password: \$password) {
        token
        user {
          id
          email
        }
      }
    }
  ''';

  /// Authenticates user with email and password
  /// Returns AuthResult with user data on success or error message on failure
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.isEmpty) {
      return AuthResult.failure('Email is required');
    }
    if (password.isEmpty) {
      return AuthResult.failure('Password is required');
    }

    try {
      // Execute login mutation
      final result = await _graphqlService.mutate(
        _loginMutation,
        variables: {
          'email': email,
          'password': password,
        },
      );

      // Check for GraphQL errors
      if (result.hasException) {
        final exception = result.exception;
        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          return AuthResult.failure(error.message);
        }
        return AuthResult.failure('Authentication failed: ${exception.toString()}');
      }

      // Check for data
      if (result.data == null || result.data!['login'] == null) {
        return AuthResult.failure('Invalid response from server');
      }

      final loginData = result.data!['login'] as Map<String, dynamic>;
      final token = loginData['token'] as String?;
      final user = loginData['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        return AuthResult.failure('Invalid login response format');
      }

      // Store token
      await _tokenStorage.saveAccessToken(token);

      // Refresh GraphQL client with new token
      await _graphqlService.refreshClient();

      // Return user data
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  /// Logs out the current user by clearing stored tokens
  Future<void> logout() async {
    await _tokenStorage.deleteAllTokens();
    // Refresh GraphQL client to remove auth header
    await _graphqlService.refreshClient();
  }

  /// Checks if user is currently authenticated
  /// Returns true if a valid access token exists
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasAccessToken();
  }
}
