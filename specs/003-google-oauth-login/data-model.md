# Data Model: Google OAuth Login

**Date**: 2025-12-22
**Feature**: 003-google-oauth-login

## Overview

This document defines the data structures and entities involved in the Google OAuth authentication flow. The data model extends the existing authentication system while maintaining consistency with current patterns.

---

## Core Entities

### 1. GoogleAuthCredentials

**Purpose**: Represents OAuth credentials received from Google's authentication flow

**Fields**:
- `idToken`: String - JWT token signed by Google, contains user identity claims
- `accessToken`: String - OAuth access token for accessing Google APIs (short-lived)
- `serverAuthCode`: String? (optional) - Authorization code for server-side token exchange
- `email`: String - User's Google email address
- `displayName`: String? - User's full name from Google profile
- `photoUrl`: String? - URL to user's Google profile picture

**Source**: Obtained from `GoogleSignInAccount.authentication` and `GoogleSignInAccount` properties

**Lifecycle**:
1. Created when user completes Google OAuth consent
2. `idToken` sent to backend for validation
3. Backend tokens replace Google tokens in storage
4. Google tokens discarded after successful backend exchange

**Validation Rules**:
- `idToken` must be non-empty
- `email` must be valid email format
- `accessToken` must be present (even if not used by app)

**Usage**:
```dart
class GoogleAuthCredentials {
  final String idToken;
  final String accessToken;
  final String? serverAuthCode;
  final String email;
  final String? displayName;
  final String? photoUrl;

  GoogleAuthCredentials({
    required this.idToken,
    required this.accessToken,
    this.serverAuthCode,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  // Factory constructor from GoogleSignInAccount
  factory GoogleAuthCredentials.fromGoogleAccount(
    GoogleSignInAccount account,
    GoogleSignInAuthentication auth,
  ) {
    return GoogleAuthCredentials(
      idToken: auth.idToken!,
      accessToken: auth.accessToken!,
      serverAuthCode: auth.serverAuthCode,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}
```

---

### 2. OAuthAuthenticationResult (Extension of existing AuthResult)

**Purpose**: Wrapper for Google OAuth authentication results, extends existing `AuthResult` pattern

**Fields**:
- `isSuccess`: bool - Whether authentication succeeded
- `data`: Map<String, dynamic>? - User data on success (email, name, picture)
- `error`: String? - Error message on failure
- `errorCode`: OAuthErrorCode? - Categorized error type

**State Transitions**:
```
[User taps button]
  → INITIATED
  → [Google OAuth flow]
    → SUCCESS (isSuccess: true, data populated)
    OR
    → FAILURE (isSuccess: false, error populated)
```

**Error Codes** (new enum):
```dart
enum OAuthErrorCode {
  canceled,          // User canceled OAuth flow
  networkError,      // Network connectivity issue
  invalidCredentials, // Invalid or expired Google token
  backendError,      // Backend GraphQL mutation failed
  unknown,           // Uncategorized error
}
```

**Usage**:
```dart
// Success case
AuthResult.success({
  'email': 'user@example.com',
  'name': 'John Doe',
  'picture': 'https://...',
});

// Failure case
AuthResult.failure('Network error. Please check your connection');
```

---

### 3. User Account (Backend Entity - Reference)

**Purpose**: Backend representation of user account, supports multiple auth methods

**Fields** (relevant to OAuth):
- `id`: UUID - Unique user identifier
- `email`: String - Primary identifier for account linking
- `name`: String? - Display name
- `picture`: String? - Profile picture URL
- `authProviders`: List<AuthProvider> - Authentication methods enabled
  - `{ provider: 'email', enabled: true }`
  - `{ provider: 'google', googleId: '...', enabled: true }`
- `createdAt`: DateTime - Account creation timestamp
- `lastLoginAt`: DateTime - Last successful authentication

**Account Linking Logic** (backend):
- Query by email address
- If exists: Add google provider to `authProviders`
- If not exists: Create new user with google provider

**Mobile Responsibility**:
- Mobile app does NOT manage this entity
- Backend returns user data in GraphQL response
- Mobile stores only authentication tokens

---

### 4. Authentication State (Session State)

**Purpose**: In-memory session state managed by Provider (or StatefulWidget)

**Fields**:
- `isAuthenticated`: bool - Whether user is currently logged in
- `userEmail`: String? - Current user's email
- `userName`: String? - Current user's name
- `userPicture`: String? - Current user's profile picture URL
- `authMethod`: AuthMethod - How user authenticated (email_password or google_oauth)
- `isLoading`: bool - Whether auth operation in progress

**State Transitions**:
```
UNAUTHENTICATED (default)
  → [Sign in] → LOADING → AUTHENTICATED
  → [Sign out] → LOADING → UNAUTHENTICATED
  → [Token expired] → UNAUTHENTICATED
```

**Persistence**:
- **NOT persisted** across app restarts (per constitution)
- Tokens stored securely via `TokenStorage`
- State rebuilt from tokens on app launch

**Usage**:
```dart
class AuthenticationState with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  String? _userPicture;
  AuthMethod _authMethod = AuthMethod.none;
  bool _isLoading = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  // ... other getters

  // Actions
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ... OAuth flow
      _isAuthenticated = true;
      _authMethod = AuthMethod.googleOAuth;
      _userEmail = result.email;
      // ...
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void signOut() {
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userPicture = null;
    _authMethod = AuthMethod.none;
    notifyListeners();
  }
}

enum AuthMethod {
  none,
  emailPassword,
  googleOAuth,
}
```

---

## Data Flow Diagram

```
┌─────────────────┐
│  User Interface │
│  (Login Screen) │
└────────┬────────┘
         │ Tap "Sign in with Google"
         ▼
┌─────────────────┐
│  AuthService    │◄────── Existing service, extended
│  .signInWith    │
│   Google()      │
└────────┬────────┘
         │ Calls google_sign_in
         ▼
┌─────────────────┐
│  Google OAuth   │
│  Native Flow    │
└────────┬────────┘
         │ Returns GoogleSignInAccount
         ▼
┌─────────────────┐
│ GoogleAuth      │◄────── New model
│ Credentials     │
│ (idToken, email)│
└────────┬────────┘
         │ Send to backend
         ▼
┌──────────────────────┐
│ GraphQL Service      │◄────── Existing service
│ exchangeGoogleIdToken│
│ mutation             │
└────────┬─────────────┘
         │ Validates token with Google
         │ Creates/links account
         ▼
┌─────────────────┐
│ Backend JWT     │
│ Tokens          │
│ (accessToken,   │
│  AUTH_CODE)     │
└────────┬────────┘
         │ Store securely
         ▼
┌─────────────────┐
│ TokenStorage    │◄────── Existing service
│ flutter_secure_ │
│ storage         │
└────────┬────────┘
         │ Refresh client
         ▼
┌─────────────────┐
│ GraphQL Client  │◄────── Existing service
│ (authenticated) │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│ Authentication  │
│ State           │
│ (Provider)      │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│ Navigate to     │
│ Home Screen     │
└─────────────────┘
```

---

## Validation Rules

### Input Validation

| Field | Validation | Error Message |
|-------|------------|---------------|
| idToken | Not empty, valid JWT format | "Invalid Google authentication" |
| accessToken | Not empty | "Invalid Google authentication" |
| email | Valid email format, non-empty | "Invalid email address" |

### Business Rules

1. **Account Linking**:
   - If email exists: Link Google provider to existing account
   - If email new: Create new account
   - Never create duplicate accounts for same email

2. **Token Expiration**:
   - Google `accessToken` short-lived (~1 hour)
   - Backend JWT tokens follow existing expiration policy
   - Mobile app does NOT refresh Google tokens (backend handles validation)

3. **Error Handling**:
   - User cancellation: Silent failure, return to login screen
   - Network errors: Show retry option
   - Invalid credentials: Force re-authentication
   - Backend errors: Show generic error, log for debugging

---

## Relationships

```
User Account (Backend)
  │
  ├── 1:N → AuthProviders (email, google)
  │   └── Google provider includes googleId
  │
  └── 1:N → Sessions (JWT tokens)
      └── Stored in mobile via TokenStorage

Authentication State (Mobile Session)
  │
  ├── References → User Email
  ├── References → User Name
  ├── References → User Picture
  └── Tracks → AuthMethod (how authenticated)

GoogleAuthCredentials (Temporary)
  │
  └── Transforms to → Backend JWT Tokens
      └── Stored in → TokenStorage
```

---

## Storage Locations

| Data | Storage Location | Persistence |
|------|-----------------|-------------|
| Google idToken | Memory only (temporary) | Until backend exchange |
| Backend JWT tokens | flutter_secure_storage | Across app restarts |
| AUTH_CODE | flutter_secure_storage | Across app restarts |
| User email/name/picture | Memory (Provider state) | Session only |
| isAuthenticated | Memory (Provider state) | Session only |
| AuthMethod | Memory (Provider state) | Session only |

---

## Privacy & Security Considerations

1. **Token Security**:
   - Google tokens never logged or exposed
   - Backend tokens stored in secure storage only
   - No tokens in shared preferences or plain files

2. **Data Minimization**:
   - Only request email and profile scopes
   - Don't store unnecessary Google data
   - User picture URL cached by Flutter (not manually stored)

3. **Account Linking Privacy**:
   - Backend verifies email ownership via Google token
   - No manual email verification needed for OAuth users
   - Existing email/password users can add Google provider seamlessly

4. **Error Messages**:
   - No sensitive info in error messages
   - Generic messages for backend errors
   - Detailed errors only in debug logs

---

## Testing Scenarios

### Happy Path
1. New user signs in with Google → Account created
2. Existing user (email/password) signs in with Google → Account linked
3. Returning Google user → Silent sign-in on app launch

### Error Paths
1. User cancels OAuth → Return to login screen
2. Network error → Show retry option
3. Invalid token → Force re-authentication
4. Backend error → Show generic error

### Edge Cases
1. Email permission denied → Cannot proceed (email required)
2. Expired Google token → Backend validation fails, re-authenticate
3. Concurrent sign-in attempts → Cancel previous, start new

---

## Migration Path

**No data migration required** - this is a new feature.

Existing users with email/password accounts can:
1. Sign in with email/password (existing flow)
2. Add Google OAuth (account linking, P3 priority)
3. Future sign-ins can use either method

---

## Next Steps

1. ✅ Data model defined
2. ⏭️ Create GraphQL contracts (contracts/ directory)
3. ⏭️ Generate quickstart guide for developers
