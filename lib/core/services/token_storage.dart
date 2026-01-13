import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for authentication tokens
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _authCodeKey = 'auth_code';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  /// Saves the access token securely
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Retrieves the access token
  /// Returns null if no token is stored
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Saves the refresh token securely
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieves the refresh token
  /// Returns null if no token is stored
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Saves the AUTH_CODE securely (base64 encoded auth payload)
  Future<void> saveAuthCode(String authCode) async {
    await _storage.write(key: _authCodeKey, value: authCode);
  }

  /// Retrieves the AUTH_CODE
  /// Returns null if no AUTH_CODE is stored
  Future<String?> getAuthCode() async {
    return await _storage.read(key: _authCodeKey);
  }

  /// Saves both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Deletes the access token
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  /// Deletes the refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Deletes the AUTH_CODE
  Future<void> deleteAuthCode() async {
    await _storage.delete(key: _authCodeKey);
  }

  /// Deletes all stored tokens (logout)
  Future<void> deleteAllTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteAuthCode();
  }

  /// Checks if an access token exists
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
