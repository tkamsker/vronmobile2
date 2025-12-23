import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/core/services/token_storage.dart';
import 'package:vronmobile2/features/auth/utils/oauth_error_mapper.dart';

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
  final GoogleSignIn _googleSignIn;

  AuthService({
    GraphQLService? graphqlService,
    TokenStorage? tokenStorage,
    GoogleSignIn? googleSignIn,
  })  : _graphqlService = graphqlService ?? GraphQLService(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// OAuth scopes required for Google Sign-In (T012)
  static const List<String> _googleScopes = [
    'email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  /// GraphQL mutation for email/password login
  static const String _loginMutation = '''
    mutation SignIn(\$input: SignInInput!) {
      signIn(input: \$input) {
        accessToken
      }
    }
  ''';

  /// GraphQL mutation for Google OAuth login (T011)
  /// Enhanced for T044: Backend returns authProviders to show account linking status
  static const String _signInWithGoogleMutation = '''
    mutation SignInWithGoogle(\$input: SignInWithGoogleInput!) {
      signInWithGoogle(input: \$input) {
        accessToken
        user {
          id
          email
          name
          picture
          authProviders {
            provider
            enabled
          }
        }
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
          if (kDebugMode) {
            print('❌ [AUTH] GraphQL error message: ${error.message}');
          }
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

  /// Signs out from Google (T049)
  /// Disconnects the Google account and clears local session
  /// Call this when user explicitly signs out from the app
  Future<void> signOutFromGoogle() async {
    try {
      // Disconnect from Google Sign-In
      await _googleSignIn.disconnect();
      if (kDebugMode) print('✅ [AUTH] Disconnected from Google');
    } catch (e) {
      // Ignore errors during sign-out (user may not be signed in)
      if (kDebugMode) print('⚠️ [AUTH] Google disconnect error: $e');
    }

    // Clear all stored tokens
    await _tokenStorage.deleteAllTokens();

    // Refresh GraphQL client to remove auth header
    await _graphqlService.refreshClient();

    if (kDebugMode) print('✅ [AUTH] Google sign-out complete');
  }

  /// Checks if user is currently authenticated
  /// Returns true if a valid access token exists
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasAccessToken();
  }

  /// Attempts silent sign-in on app startup (T050)
  /// Uses lightweight authentication to restore previous Google session
  /// Returns AuthResult with success if silently signed in, failure otherwise
  Future<AuthResult> attemptSilentSignIn() async {
    try {
      if (kDebugMode) print('🔐 [AUTH] Attempting silent Google sign-in');

      // Initialize Google Sign-In
      await _googleSignIn.initialize();

      // Attempt lightweight authentication (silent sign-in)
      final GoogleSignInAccount? googleAccount =
          await _googleSignIn.attemptLightweightAuthentication();

      if (googleAccount == null) {
        // No previous session found
        if (kDebugMode) print('ℹ️ [AUTH] No previous Google session found');
        return AuthResult.failure('No previous session');
      }

      if (kDebugMode) {
        print('✅ [AUTH] Silent sign-in successful: ${googleAccount.email}');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          googleAccount.authentication;

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        if (kDebugMode) print('❌ [AUTH] Failed to obtain idToken silently');
        return AuthResult.failure('Failed to obtain credentials');
      }

      // Exchange Google token for backend JWT (same as regular sign-in)
      final result = await _graphqlService.mutate(
        _signInWithGoogleMutation,
        variables: {
          'input': {'idToken': googleAuth.idToken},
        },
      );

      // Handle errors
      if (result.hasException || result.data == null) {
        if (kDebugMode) print('❌ [AUTH] Silent sign-in backend error');
        return AuthResult.failure('Backend authentication failed');
      }

      // Extract and store tokens
      final loginData =
          result.data!['signInWithGoogle'] as Map<String, dynamic>;
      final accessToken = loginData['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        return AuthResult.failure('Invalid backend response');
      }

      // Store tokens
      final authCode = _createAuthCode(accessToken);
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveAuthCode(authCode);

      // Refresh GraphQL client
      await _graphqlService.refreshClient();

      // Return success with user data
      final user = loginData['user'] as Map<String, dynamic>;
      if (kDebugMode) {
        print('✅ [AUTH] Silent sign-in complete for: ${user['email']}');
      }

      return AuthResult.success({
        'email': user['email'],
        'name': user['name'],
        'picture': user['picture'],
      });
    } catch (e) {
      // Silent failures are normal - just means no previous session
      if (kDebugMode) print('ℹ️ [AUTH] Silent sign-in not available: $e');
      return AuthResult.failure('Silent sign-in failed');
    }
  }

  /// Authenticates user with Google OAuth (T019)
  /// Returns AuthResult with success status on success or error message on failure
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('🔐 [AUTH] Starting Google sign-in');
        print('🔐 [AUTH] Google Sign-In instance: ${_googleSignIn.toString()}');
        print('🔐 [AUTH] Scopes: $_googleScopes');
      }

      // Initialize Google Sign-In (v7.0+ requirement)
      if (kDebugMode) print('🔐 [AUTH] Initializing Google Sign-In...');
      await _googleSignIn.initialize();
      if (kDebugMode) print('✅ [AUTH] Google Sign-In initialized');

      // Trigger Google OAuth flow (v7.0 API)
      if (kDebugMode) print('🔐 [AUTH] Calling authenticate() with scopes: $_googleScopes');
      final GoogleSignInAccount googleAccount = await _googleSignIn.authenticate(
        scopeHint: _googleScopes,
      );

      if (kDebugMode) {
        print('✅ [AUTH] Google account obtained: ${googleAccount.email}');
        print('✅ [AUTH] Display name: ${googleAccount.displayName}');
        print('✅ [AUTH] Photo URL: ${googleAccount.photoUrl}');
      }

      // Get authentication tokens (v7.0: authentication is a getter, not async)
      final GoogleSignInAuthentication googleAuth = googleAccount.authentication;

      // T039: Handle null idToken scenario
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        if (kDebugMode) print('❌ [AUTH] Failed to obtain Google idToken');
        return AuthResult.failure(
          OAuthErrorMapper.getUserMessage(OAuthErrorCode.invalidCredentials),
        );
      }

      if (kDebugMode) print('✅ [AUTH] Google idToken obtained');

      // Exchange Google token for backend JWT (T019-T021)
      final result = await _graphqlService.mutate(
        _signInWithGoogleMutation,
        variables: {
          'input': {'idToken': googleAuth.idToken},
        },
      );

      if (kDebugMode) print('🔐 [AUTH] GraphQL mutation completed');

      // Handle GraphQL errors (T037 - enhanced)
      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [AUTH] GraphQL exception: ${exception.toString()}');
        }

        // Check for network errors
        if (exception?.linkException != null) {
          if (kDebugMode) print('❌ [AUTH] Network/link error detected');
          return AuthResult.failure(
            OAuthErrorMapper.getUserMessage(OAuthErrorCode.networkError),
          );
        }

        // Check for GraphQL errors (backend validation, auth failures, etc.)
        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) print('❌ [AUTH] GraphQL error: ${error.message}');

          // Return user-friendly backend error message
          return AuthResult.failure(
            OAuthErrorMapper.getUserMessage(OAuthErrorCode.backendError),
          );
        }

        // Fallback for unknown GraphQL exceptions
        return AuthResult.failure(
          OAuthErrorMapper.getUserMessage(OAuthErrorCode.backendError),
        );
      }

      // Extract response data
      if (result.data == null || result.data!['signInWithGoogle'] == null) {
        if (kDebugMode) print('❌ [AUTH] Invalid response structure');
        return AuthResult.failure('Invalid response from server');
      }

      final loginData = result.data!['signInWithGoogle'] as Map<String, dynamic>;
      final accessToken = loginData['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) print('❌ [AUTH] Missing access token in backend response');
        return AuthResult.failure(
          OAuthErrorMapper.getUserMessage(OAuthErrorCode.backendError),
        );
      }

      if (kDebugMode) print('✅ [AUTH] Received backend access token');

      // T020: Create AUTH_CODE (same pattern as email/password login)
      final authCode = _createAuthCode(accessToken);

      // T021: Store tokens
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveAuthCode(authCode);
      if (kDebugMode) print('✅ [AUTH] Tokens stored securely');

      // T022: Refresh GraphQL client with new auth
      await _graphqlService.refreshClient();
      if (kDebugMode) print('✅ [AUTH] GraphQL client refreshed with new auth');

      // Return success with user data (T045, T046)
      // Note: Backend handles account linking automatically
      // - If email exists: links Google provider to existing account
      // - If new email: creates new account with Google provider
      // The authProviders field shows which methods are linked
      final user = loginData['user'] as Map<String, dynamic>;
      if (kDebugMode) {
        print('✅ [AUTH] Google sign-in successful for: ${user['email']}');
        if (user['authProviders'] != null) {
          final providers = (user['authProviders'] as List)
              .map((p) => p['provider'])
              .join(', ');
          print('✅ [AUTH] Linked providers: $providers');
        }
      }

      return AuthResult.success({
        'email': user['email'],
        'name': user['name'],
        'picture': user['picture'],
      });
    } on PlatformException catch (e) {
      // Handle Google Sign-In specific errors (T035)
      if (kDebugMode) {
        print('❌ [AUTH] Platform exception details:');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Details: ${e.details}');
        print('   Stack trace: ${e.stacktrace}');
      }

      // Map to user-friendly error message (T034)
      final userMessage = OAuthErrorMapper.mapPlatformError(e);
      return AuthResult.failure(userMessage);
    } catch (e) {
      // Handle network errors and other exceptions (T036)
      if (kDebugMode) print('❌ [AUTH] Exception: ${e.toString()}');

      // Check if user cancelled (in v7.0, cancellation throws an exception)
      if (e.toString().toLowerCase().contains('cancel')) {
        if (kDebugMode) print('❌ [AUTH] User cancelled sign-in');
        return AuthResult.failure(OAuthErrorMapper.getUserMessage(OAuthErrorCode.cancelled));
      }

      // Map to user-friendly error message
      if (e is Exception) {
        final userMessage = OAuthErrorMapper.mapGenericError(e);
        return AuthResult.failure(userMessage);
      }

      // Fallback for unknown errors
      return AuthResult.failure(OAuthErrorMapper.getUserMessage(OAuthErrorCode.unknown));
    }
  }
}
