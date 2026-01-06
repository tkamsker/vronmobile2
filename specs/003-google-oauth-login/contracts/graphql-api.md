# GraphQL API Contract: Google OAuth Authentication

**Date**: 2025-12-22
**Feature**: 003-google-oauth-login
**API Version**: To be determined by backend team

## Overview

This document defines the GraphQL mutation contract between the mobile application and backend API for Google OAuth authentication. The backend is responsible for:
1. Validating the Google idToken with Google's API
2. Creating or linking user accounts based on email
3. Returning application JWT tokens for subsequent API calls

---

## Mutation: exchangeGoogleIdToken

### Description
Authenticates a user via Google OAuth by validating the Google idToken and returning an application-specific JWT access token. The mutation returns only the access token string; user profile information is obtained directly from the Google Sign-In SDK.

### Request

```graphql
mutation ExchangeGoogleIdToken($input: ExchangeGoogleIdTokenInput!) {
  exchangeGoogleIdToken(input: $input)
}
```

### Input Type

```graphql
input ExchangeGoogleIdTokenInput {
  """
  Google idToken obtained from google_sign_in package
  JWT token signed by Google containing user identity claims
  Backend must validate this token with Google's token verification API
  """
  idToken: String!
}
```

### Response Type

```graphql
"""
Returns a String directly (not an object)
This is the application JWT access token for authenticating subsequent API requests
This is NOT the Google access token - it's the backend's own JWT
"""
String!
```

**Note**: User profile data (email, name, picture) is obtained from the Google Sign-In SDK (`GoogleSignInAccount`) on the client side, not from this mutation. The backend creates or links the user account internally based on the validated idToken.

---

## Backend Responsibilities

### 1. Token Validation

The backend MUST:
1. Validate the `idToken` with Google's token verification API
2. Verify the token signature, expiration, and audience
3. Extract user claims (email, name, picture) from validated token

**Google Token Verification Endpoint**:
```
POST https://oauth2.googleapis.com/tokeninfo?id_token={idToken}
```

**Expected Claims** (from validated idToken):
- `email`: User's email address
- `email_verified`: Must be `true`
- `name`: User's full name
- `picture`: Profile picture URL
- `sub`: Google user ID (unique identifier)
- `aud`: OAuth client ID (must match configured client ID)
- `exp`: Token expiration (must be in the future)

### 2. Account Creation / Linking Logic

```
IF user with email exists:
    IF google provider already linked:
        UPDATE lastLoginAt
        RETURN existing user + new JWT
    ELSE:
        ADD google provider to user.authProviders
        UPDATE lastLoginAt
        RETURN existing user + new JWT
ELSE:
    CREATE new user:
        - email: from Google token
        - name: from Google token
        - picture: from Google token
        - authProviders: [{ provider: 'google', enabled: true }]
        - createdAt: now()
        - lastLoginAt: now()
    RETURN new user + new JWT
```

### 3. JWT Token Generation

The backend MUST:
1. Generate a JWT `accessToken` with the user's identity
2. Follow the existing token format (same as email/password login)
3. Include necessary claims for GraphQL authentication
4. Set appropriate expiration time

**Required JWT Claims** (consistent with existing auth):
- User identifier (id or email)
- Merchant role information (as per existing `_createAuthCode`)
- Token expiration
- Issuer and audience

**AUTH_CODE Generation**:
The mobile app will create the `AUTH_CODE` using the same pattern as email/password login:
```dart
final authPayload = {
  'MERCHANT': {'accessToken': accessToken},
  'activeRoles': {'merchants': 'MERCHANT'},
};
final authCode = base64Encode(utf8.encode(jsonEncode(authPayload)));
```

---

## Error Responses

### Standard GraphQL Error Format

```json
{
  "errors": [
    {
      "message": "Human-readable error message",
      "extensions": {
        "code": "ERROR_CODE",
        "field": "idToken"
      }
    }
  ],
  "data": {
    "exchangeGoogleIdToken": null
  }
}
```

### Error Codes

| Code | Scenario | Mobile Handling |
|------|----------|-----------------|
| `INVALID_TOKEN` | idToken is malformed or expired | Show "Authentication failed. Please try again" |
| `TOKEN_VERIFICATION_FAILED` | Google's API rejected the token | Show "Invalid Google authentication" |
| `EMAIL_NOT_VERIFIED` | Google account email not verified | Show "Please verify your email with Google" |
| `NETWORK_ERROR` | Backend couldn't reach Google's API | Show "Network error. Please try again later" |
| `INTERNAL_ERROR` | Unexpected backend error | Show "Sign-in failed. Please try again later" |
| `RATE_LIMIT_EXCEEDED` | Too many sign-in attempts | Show "Too many attempts. Please try again in a few minutes" |

### Example Error Response

```json
{
  "errors": [
    {
      "message": "Invalid or expired Google token",
      "extensions": {
        "code": "INVALID_TOKEN",
        "field": "idToken"
      }
    }
  ],
  "data": {
    "exchangeGoogleIdToken": null
  }
}
```

---

## Request/Response Examples

### Example 1: New User Sign-In

**Request**:
```graphql
mutation {
  exchangeGoogleIdToken(input: {
    idToken: "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE..."
  })
}
```

**Response** (Success):
```json
{
  "data": {
    "exchangeGoogleIdToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Note**: User profile data is obtained from Google Sign-In SDK:
```dart
// From GoogleSignInAccount
email: "newuser@example.com"
name: "John Doe"
picture: "https://lh3.googleusercontent.com/..."
```

### Example 2: Existing User (Email/Password) Adding Google

**Request**:
```graphql
mutation {
  exchangeGoogleIdToken(input: {
    idToken: "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE..."
  })
}
```

**Response** (Success - Account Linked):
```json
{
  "data": {
    "exchangeGoogleIdToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Note**: The backend automatically links the Google account to the existing email/password account if the email matches. The mobile app receives only the access token; account linking is transparent to the client.

### Example 3: Invalid Token Error

**Request**:
```graphql
mutation {
  exchangeGoogleIdToken(input: {
    idToken: "invalid_or_expired_token"
  })
}
```

**Response** (Error):
```json
{
  "errors": [
    {
      "message": "Invalid or expired Google token",
      "extensions": {
        "code": "INVALID_TOKEN",
        "field": "idToken"
      }
    }
  ],
  "data": {
    "exchangeGoogleIdToken": null
  }
}
```

---

## Mobile Implementation Snippet

```dart
class AuthService {
  // ... existing code ...

  /// Authenticates user with Google OAuth
  /// Returns AuthResult with success status or error message
  Future<AuthResult> signInWithGoogle() async {
    try {
      // 1. Initiate Google Sign-In
      await _googleSignIn.initialize();
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        // User canceled
        return AuthResult.failure('Sign-in was cancelled');
      }

      // 2. Get Google authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      if (googleAuth.idToken == null) {
        return AuthResult.failure('Failed to obtain Google credentials');
      }

      // 3. Exchange Google token for backend JWT
      final result = await _graphqlService.mutate(
        _exchangeGoogleIdTokenMutation,
        variables: {
          'input': {'idToken': googleAuth.idToken},
        },
      );

      if (result.hasException) {
        final error = result.exception?.graphqlErrors.first;
        return AuthResult.failure(error?.message ?? 'Authentication failed');
      }

      // Backend returns String directly (not an object)
      final accessToken = result.data!['exchangeGoogleIdToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        return AuthResult.failure('Invalid response from server');
      }

      // 4. Store tokens (same pattern as email/password login)
      final authCode = _createAuthCode(accessToken);
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveAuthCode(authCode);

      // 5. Refresh GraphQL client
      await _graphqlService.refreshClient();

      // 6. Return success with user data from Google Sign-In SDK
      return AuthResult.success({
        'email': googleAccount.email,
        'name': googleAccount.displayName,
        'picture': googleAccount.photoUrl,
      });
    } on PlatformException catch (e) {
      // Handle platform-specific errors (Google Sign-In errors)
      return AuthResult.failure(_mapPlatformError(e));
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  static const String _exchangeGoogleIdTokenMutation = '''
    mutation ExchangeGoogleIdToken(\$input: ExchangeGoogleIdTokenInput!) {
      exchangeGoogleIdToken(input: \$input)
    }
  ''';
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
- If breaking changes needed, use versioned mutation name: `exchangeGoogleIdTokenV2`
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
