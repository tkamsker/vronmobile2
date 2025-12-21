import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/core/services/token_storage.dart';

/// Result wrapper for authentication operations
class AuthResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  AuthResult._({required this.isSuccess, this.data, this.error});

  factory AuthResult.success(Map<String, dynamic> data) {
    return AuthResult._(isSuccess: true, data: data);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}

/// Authentication service
/// Handles user authentication, token management, and session state
class AuthService {
  final GraphQLService _graphqlService;
  final TokenStorage _tokenStorage;

  AuthService({GraphQLService? graphqlService, TokenStorage? tokenStorage})
    : _graphqlService = graphqlService ?? GraphQLService(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  /// GraphQL mutation for email/password login
  static const String _loginMutation = '''
    mutation SignIn(\$input: SignInInput!) {
      signIn(input: \$input) {
        accessToken
      }
    }
  ''';

  /// Creates AUTH_CODE in the required format for VRON API
  /// Encodes the access token with merchant role information
  String _createAuthCode(String accessToken) {
    final authPayload = {
      'MERCHANT': {'accessToken': accessToken},
      'activeRoles': {'merchants': 'MERCHANT'},
    };

    final jsonString = jsonEncode(authPayload);
    final bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }

  /// Authenticates user with email and password
  /// Returns AuthResult with success status on success or error message on failure
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
      if (kDebugMode) print('🔐 [AUTH] Starting login for: $email');

      // Execute login mutation with correct input structure
      final result = await _graphqlService.mutate(
        _loginMutation,
        variables: {
          'input': {'email': email, 'password': password},
        },
      );

      if (kDebugMode) print('🔐 [AUTH] GraphQL mutation completed');

      // Check for GraphQL errors
      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [AUTH] GraphQL exception: ${exception.toString()}');
        }
        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode)
            print('❌ [AUTH] GraphQL error message: ${error.message}');
          return AuthResult.failure(error.message);
        }
        return AuthResult.failure(
          'Authentication failed: ${exception.toString()}',
        );
      }

      // Check for data
      if (result.data == null || result.data!['signIn'] == null) {
        if (kDebugMode) print('❌ [AUTH] Invalid response structure');
        return AuthResult.failure('Invalid response from server');
      }

      final loginData = result.data!['signIn'] as Map<String, dynamic>;
      final accessToken = loginData['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) print('❌ [AUTH] Missing access token in response');
        return AuthResult.failure(
          'Invalid login response: missing access token',
        );
      }

      final tokenPreview = accessToken.length > 20
          ? '${accessToken.substring(0, 20)}...'
          : accessToken;
      if (kDebugMode) print('✅ [AUTH] Received access token: $tokenPreview');

      // Create AUTH_CODE in required format
      final authCode = _createAuthCode(accessToken);
      final authCodePreview = authCode.length > 40
          ? '${authCode.substring(0, 40)}...'
          : authCode;
      if (kDebugMode) print('✅ [AUTH] Created AUTH_CODE: $authCodePreview');

      // Store both access token and AUTH_CODE
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveAuthCode(authCode);
      if (kDebugMode) print('✅ [AUTH] Tokens stored securely');

      // Refresh GraphQL client with new auth code
      await _graphqlService.refreshClient();
      if (kDebugMode) print('✅ [AUTH] GraphQL client refreshed with new auth');

      // Return success with email as user identifier
      if (kDebugMode) print('✅ [AUTH] Login successful for: $email');
      return AuthResult.success({'email': email});
    } catch (e) {
      if (kDebugMode) print('❌ [AUTH] Network error: ${e.toString()}');
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
