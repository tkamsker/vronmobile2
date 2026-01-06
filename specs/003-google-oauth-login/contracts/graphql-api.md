# GraphQL API Contract: Google OAuth Authentication (Mobile Redirect Flow)

**Date**: 2025-12-22
**Updated**: 2026-01-06
**Feature**: 003-google-oauth-login
**API Version**: To be determined by backend team

**BREAKING CHANGE**: This contract has been updated to reflect the new redirect-based mobile OAuth flow. The old `signInWithGoogle` mutation with `idToken` parameter is being replaced by `exchangeMobileAuthCode` mutation.

## Overview

This document defines the GraphQL mutation contract between the mobile application and backend API for Google OAuth authentication using the redirect-based mobile flow. The backend is responsible for:
1. Handling the OAuth redirect flow with Google (via `/auth/google` endpoint)
2. Returning authorization code or error via deep link callback
3. Validating the authorization code when exchanged via GraphQL mutation
4. Creating or linking user accounts based on email
5. Returning application JWT tokens for subsequent API calls

---

## New Mutation: exchangeMobileAuthCode

### Description
Exchanges a mobile OAuth authorization code for an application access token. The authorization code is obtained from the backend's OAuth redirect callback (deep link) after the user completes Google authentication.

### Request

```graphql
mutation ExchangeMobileAuthCode($input: ExchangeMobileAuthCodeInput!) {
  exchangeMobileAuthCode(input: $input) {
    accessToken
  }
}
```

### Input Type

```graphql
input ExchangeMobileAuthCodeInput {
  """
  Authorization code received from backend OAuth redirect callback
  This code is extracted from the deep link query parameter: ?code=AUTHORIZATION_CODE
  Backend must validate this code and ensure it:
  - Has not been used before (single-use)
  - Has not expired (typically 5-10 minutes)
  - Was issued by this backend instance
  """
  code: String!
}
```

### Response Type

```graphql
type ExchangeMobileAuthCodeResponse {
  """
  Application JWT access token for authenticating subsequent API requests
  This is the backend's own JWT, NOT a Google token
  Format and claims should match the existing email/password login tokens
  """
  accessToken: String!
}
```

**Note**: Unlike the old `signInWithGoogle` mutation, this mutation returns ONLY the `accessToken`. User information can be fetched separately using the authenticated token if needed (e.g., via a `me` query).

---

## OAuth Redirect Endpoint

### Endpoint: GET /auth/google

This endpoint initiates the OAuth flow with Google and is called by the mobile app via URL redirect.

**URL**: `https://api.vron.stage.motorenflug.at/auth/google`

**Query Parameters**:
- `role`: User role (e.g., `MERCHANT`)
- `preferredLanguage`: User's preferred language (`EN`, `DE`, `PT`)
- `redirectUrl`: URL-encoded deep link where backend should redirect after OAuth completes
- `fromMobile`: Set to `true` to indicate mobile client (affects callback behavior)

**Example**:
```
https://api.vron.stage.motorenflug.at/auth/google?role=MERCHANT&preferredLanguage=EN&redirectUrl=app%3A%2F%2Foauth-callback&fromMobile=true
```

**Backend Behavior**:
1. Redirect user to Google's OAuth consent screen
2. Handle Google's OAuth callback
3. Validate user with Google
4. Create/link user account in database
5. Generate authorization code (single-use, short-lived)
6. Redirect back to mobile app with result:
   - Success: `{redirectUrl}?code={AUTHORIZATION_CODE}`
   - Error: `{redirectUrl}?error={ERROR_CODE}`

---

## Backend Responsibilities

### 1. Authorization Code Validation

The backend MUST validate authorization codes in the `exchangeMobileAuthCode` mutation:
1. Verify the code was issued by this backend instance
2. Verify the code has not expired (typically 5-10 minutes from issuance)
3. Verify the code has not been used before (single-use)
4. Invalidate the code immediately after successful exchange

### 2. Account Creation / Linking Logic

This logic occurs during the `/auth/google` redirect flow (BEFORE the code is generated):

```
DURING /auth/google callback from Google:
    Extract user info from Google (email, name, picture)

    IF user with email exists:
        IF google provider already linked:
            UPDATE lastLoginAt
            GENERATE authorization code linked to user
        ELSE:
            ADD google provider to user.authProviders
            UPDATE lastLoginAt
            GENERATE authorization code linked to user
    ELSE:
        CREATE new user:
            - email: from Google
            - name: from Google
            - picture: from Google
            - authProviders: [{ provider: 'google', enabled: true }]
            - createdAt: now()
            - lastLoginAt: now()
        GENERATE authorization code linked to new user

    REDIRECT to mobile app with code

DURING exchangeMobileAuthCode mutation:
    Validate code
    Lookup user associated with code
    Generate JWT access token for user
    Invalidate code
    RETURN accessToken
```

### 3. JWT Token Generation

The backend MUST:
1. Generate a JWT `accessToken` with the user's identity
2. Follow the existing token format (same as email/password login)
3. Include necessary claims for GraphQL authentication
4. Set appropriate expiration time (consistent with email/password tokens)

**Required JWT Claims** (consistent with existing auth):
- User identifier (id or email)
- Merchant role information
- Token expiration
- Issuer and audience

**Mobile App AUTH_CODE Generation**:
The mobile app will create the `AUTH_CODE` using the same pattern as email/password login:
```dart
final authPayload = {
  'MERCHANT': {'accessToken': accessToken},
  'activeRoles': {'merchants': 'MERCHANT'},
};
final authCode = base64Encode(utf8.encode(jsonEncode(authPayload)));
```

### 4. Authorization Code Security

The backend MUST implement these security measures for authorization codes:

1. **Single-Use**: Each code can only be exchanged once
2. **Short-Lived**: Codes expire after 5-10 minutes
3. **Cryptographically Secure**: Use secure random generation
4. **Rate Limiting**: Limit code exchange attempts per IP/device
5. **Logging**: Log all code generation and exchange attempts

---

## Error Responses

### OAuth Redirect Errors

When the `/auth/google` flow fails, the backend redirects to the mobile app with an `error` query parameter:

**Format**: `{redirectUrl}?error={ERROR_CODE}`

**Error Codes**:

| Error Code | Scenario | Mobile Handling |
|------------|----------|-----------------|
| `access_denied` | User denied OAuth consent | Show "Sign-in was cancelled" |
| `server_error` | Backend error during OAuth | Show "Sign-in failed. Please try again later" |
| `temporarily_unavailable` | Google OAuth unavailable | Show "Google sign-in is temporarily unavailable" |

### GraphQL Mutation Errors

The `exchangeMobileAuthCode` mutation uses standard GraphQL error format:

```json
{
  "errors": [
    {
      "message": "Human-readable error message",
      "extensions": {
        "code": "ERROR_CODE",
        "field": "code"
      }
    }
  ],
  "data": {
    "exchangeMobileAuthCode": null
  }
}
```

### Mutation Error Codes

| Code | Scenario | Mobile Handling |
|------|----------|-----------------|
| `INVALID_CODE` | Code is malformed, expired, or already used | Show "Authentication failed. Please try again" |
| `CODE_EXPIRED` | Code has expired (older than 5-10 minutes) | Show "Session expired. Please sign in again" |
| `CODE_ALREADY_USED` | Code has already been exchanged | Show "Invalid authentication code. Please try again" |
| `NETWORK_ERROR` | Backend internal error | Show "Network error. Please try again later" |
| `INTERNAL_ERROR` | Unexpected backend error | Show "Sign-in failed. Please try again later" |
| `RATE_LIMIT_EXCEEDED` | Too many code exchange attempts | Show "Too many attempts. Please try again in a few minutes" |

### Example Error Response

```json
{
  "errors": [
    {
      "message": "Invalid or expired authorization code",
      "extensions": {
        "code": "INVALID_CODE",
        "field": "code"
      }
    }
  ],
  "data": {
    "exchangeMobileAuthCode": null
  }
}
```

---

## Request/Response Examples

### Example 1: Complete OAuth Flow

**Step 1: Mobile app redirects to backend**
```
User taps "Sign in with Google"
App opens: https://api.vron.stage.motorenflug.at/auth/google?role=MERCHANT&preferredLanguage=EN&redirectUrl=app%3A%2F%2Foauth-callback&fromMobile=true
```

**Step 2: Backend handles OAuth and redirects back**
```
Success case:
app://oauth-callback?code=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9abc123def456

Error case:
app://oauth-callback?error=access_denied
```

**Step 3: Mobile app exchanges code for token**

**GraphQL Request**:
```graphql
mutation {
  exchangeMobileAuthCode(input: {
    code: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9abc123def456"
  }) {
    accessToken
  }
}
```

**Response** (Success):
```json
{
  "data": {
    "exchangeMobileAuthCode": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
}
```

### Example 2: Invalid Code Error

**Request**:
```graphql
mutation {
  exchangeMobileAuthCode(input: {
    code: "expired_or_invalid_code"
  }) {
    accessToken
  }
}
```

**Response** (Error):
```json
{
  "errors": [
    {
      "message": "Invalid or expired authorization code",
      "extensions": {
        "code": "INVALID_CODE",
        "field": "code"
      }
    }
  ],
  "data": {
    "exchangeMobileAuthCode": null
  }
}
```

### Example 3: OAuth Redirect Error

**Redirect from backend** (user cancelled):
```
app://oauth-callback?error=access_denied
```

**Mobile app handling**:
```dart
if (uri.queryParameters.containsKey('error')) {
  final error = uri.queryParameters['error'];
  // Show user-friendly message: "Sign-in was cancelled"
  return;
}
```

---

## Mobile Implementation Snippet

```dart
class AuthService {
  // ... existing code ...

  /// Initiates Google OAuth redirect flow
  Future<void> initiateGoogleOAuth() async {
    final baseUrl = 'https://api.vron.stage.motorenflug.at/auth/google';
    final redirectUrl = Uri.encodeComponent('app://oauth-callback');
    final language = 'EN'; // Get from user preferences

    final oauthUrl = '$baseUrl?role=MERCHANT&preferredLanguage=$language&redirectUrl=$redirectUrl&fromMobile=true';

    // Open in browser or web view
    await launchUrl(Uri.parse(oauthUrl));
  }

  /// Handles deep link callback from OAuth redirect
  /// Called when app receives: app://oauth-callback?code=... or ?error=...
  Future<AuthResult> handleOAuthCallback(Uri uri) async {
    try {
      // Check for error first
      if (uri.queryParameters.containsKey('error')) {
        final error = uri.queryParameters['error'];
        return AuthResult.failure(_mapOAuthError(error));
      }

      // Extract authorization code
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        return AuthResult.failure('Invalid OAuth callback');
      }

      // Exchange code for access token
      final result = await _graphqlService.mutate(
        _exchangeMobileAuthCodeMutation,
        variables: {
          'input': {'code': code},
        },
      );

      if (result.hasException) {
        final error = result.exception?.graphqlErrors.first;
        return AuthResult.failure(error?.message ?? 'Authentication failed');
      }

      final data = result.data!['exchangeMobileAuthCode'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;

      // Store tokens (same pattern as email/password login)
      final authCode = _createAuthCode(accessToken);
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveAuthCode(authCode);

      // Refresh GraphQL client
      await _graphqlService.refreshClient();

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  static const String _exchangeMobileAuthCodeMutation = '''
    mutation ExchangeMobileAuthCode(\$input: ExchangeMobileAuthCodeInput!) {
      exchangeMobileAuthCode(input: \$input) {
        accessToken
      }
    }
  ''';

  String _mapOAuthError(String? errorCode) {
    switch (errorCode) {
      case 'access_denied':
        return 'Sign-in was cancelled';
      case 'temporarily_unavailable':
        return 'Google sign-in is temporarily unavailable';
      default:
        return 'Sign-in failed. Please try again later';
    }
  }
}
```

---

## Security Considerations

### Backend Security Requirements

1. **Token Validation**:
   - ALWAYS validate idToken with Google's API (never trust client)
   - Verify token signature cryptographically
   - Check token expiration timestamp
   - Verify audience matches your OAuth client ID
   - Reject tokens with `email_verified: false`

2. **Rate Limiting**:
   - Implement rate limiting per IP address
   - Limit sign-in attempts to prevent abuse
   - Return `RATE_LIMIT_EXCEEDED` error after threshold

3. **Logging**:
   - Log all sign-in attempts (success and failure)
   - Include timestamps, email, and IP address
   - Do NOT log idToken or accessToken values

4. **Account Linking Security**:
   - Only link accounts if email is verified by Google
   - Prevent account takeover by validating email ownership
   - Notify user via email when new provider is linked (optional enhancement)

### Mobile Security Requirements

1. **Token Handling**:
   - Never log or expose Google idToken
   - Store backend JWT in flutter_secure_storage only
   - Clear tokens on sign-out

2. **HTTPS Only**:
   - All API calls over HTTPS
   - Reject insecure connections

3. **Error Messages**:
   - Don't expose sensitive details in user-facing errors
   - Log detailed errors for debugging only

---

## Testing Checklist

### Backend Tests
- [ ] Validate valid Google idToken → Success response
- [ ] Reject expired idToken → INVALID_TOKEN error
- [ ] Reject malformed idToken → INVALID_TOKEN error
- [ ] Create new user for new email → User created
- [ ] Link Google to existing email/password account → Provider added
- [ ] Return existing Google user → Success response
- [ ] Handle Google API unavailable → NETWORK_ERROR
- [ ] Enforce rate limiting → RATE_LIMIT_EXCEEDED
- [ ] Verify email_verified claim → Reject unverified emails

### Mobile Integration Tests
- [ ] Send valid idToken → Receive JWT tokens
- [ ] Handle INVALID_TOKEN error gracefully
- [ ] Handle network errors → Retry option
- [ ] Store tokens securely → TokenStorage
- [ ] Refresh GraphQL client with new auth
- [ ] Navigate to home screen on success

---

## API Versioning

**Current Version**: N/A (new endpoint)

**Future Considerations**:
- If breaking changes needed, use versioned mutation name: `signInWithGoogleV2`
- Document changes in API changelog
- Support old version during deprecation period

---

## Backend Reference Implementation Notes

This contract assumes the backend will:
1. Use a library for Google token verification (e.g., google-auth-library)
2. Store user accounts in PostgreSQL (existing setup)
3. Generate JWT tokens using existing auth infrastructure
4. Follow the same token format as email/password login
5. Implement the account linking logic described above

**Recommended Libraries** (backend):
- Node.js: `google-auth-library`
- Python: `google-auth`
- Java: `com.google.api-client`
- Go: `google.golang.org/api/idtoken`

---

## Questions for Backend Team

1. **OAuth Client ID**: Which OAuth client ID should we use for token verification?
2. **Token Expiration**: What should the JWT accessToken expiration time be?
3. **User Creation**: Are there additional fields to populate on user creation?
4. **Account Linking**: Should we send notification email when linking providers?
5. **Rate Limiting**: What rate limit thresholds should we enforce?
6. **Monitoring**: Are there specific metrics to track for OAuth sign-ins?

---

## Next Steps

1. ✅ GraphQL contract defined
2. ⏭️ Backend team implements mutation
3. ⏭️ Mobile team implements integration (per tasks.md)
4. ⏭️ Integration testing with staging environment
