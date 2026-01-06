# Research: Google OAuth Login Implementation

**Date**: 2025-12-22
**Feature**: 003-google-oauth-login

## Unknowns Resolved

### 1. Google OAuth Package Selection

**Decision**: Use `google_sign_in ^7.0.0`

**Rationale**:
- Official package maintained by Google/Flutter team
- Best-in-class support for native iOS and Android platforms
- Follows OAuth 2.0 best practices for mobile applications
- Seamless integration with existing Flutter patterns
- Active maintenance with v7.0 modernization (2025)
- Well-documented with extensive community examples

**Alternatives Considered**:
- `flutter_appauth`: More flexible for multi-provider OAuth, but overkill for Google-only implementation
- Custom OAuth implementation: Rejected due to security complexity and maintenance burden
- Firebase Auth + Google Sign-In: Not needed since backend handles authentication via GraphQL

**Version Selection**: 7.0+ (latest stable, includes critical iOS 15+ improvements and modern API patterns)

---

### 2. OAuth Scopes Required

**Decision**: Request `email` and `profile` scopes

**Scopes Configuration**:
```dart
final scopes = [
  'email',  // User's email address
  'https://www.googleapis.com/auth/userinfo.profile',  // Name, picture, profile info
];
```

**Rationale**:
- `email` scope: Required for account linking (FR-008) - matches users by email address
- `profile` scope: Provides name and picture for user experience
- `openid` scope: Auto-included by default, provides OpenID Connect identifier
- Minimal scopes principle: Request only what's needed per security best practices

**User Consent**: Google's consent screen will show: "See your email address" and "See your personal info, including any personal info you've made publicly available"

---

### 3. Platform-Specific Configuration

**Decision**: Use standard Google Cloud Console setup for both platforms

**Android Requirements**:
1. Register SHA-1 debug and release fingerprints in Firebase Console
2. Download and place `google-services.json` in `android/app/`
3. Ensure Google Play Services are available on device
4. Minimum SDK: API 21+ (already supported)

**iOS Requirements**:
1. Configure `GIDClientID` in `Info.plist` with Web Client ID
2. Add URL scheme for OAuth callback: `com.googleusercontent.apps.YOUR_CLIENT_ID`
3. Minimum deployment target: iOS 15+ (already supported)
4. Update Podfile with protobuf configuration

**Rationale**: Standard Google OAuth configuration, well-documented, minimal friction

---

### 4. Backend API Integration Pattern

**Decision**: Exchange Google OAuth credentials for backend JWT tokens via GraphQL mutation

**Flow**:
1. Mobile app initiates Google OAuth flow via `google_sign_in`
2. User completes authentication in Google's native UI
3. App receives `idToken` and `accessToken` from Google
4. App sends `idToken` to backend GraphQL mutation (`exchangeGoogleIdToken`)
5. Backend validates token with Google's API
6. Backend returns application JWT accessToken (String)
7. App stores tokens via existing `TokenStorage` service
8. App refreshes `GraphQLService` client with new auth

**Rationale**:
- Follows existing email/password login pattern (FR-010)
- Backend controls user account creation and linking (FR-008)
- Centralized authentication logic in backend
- Reuses existing `AuthService.login()` pattern
- Secure: idToken is cryptographically signed by Google

**GraphQL Mutation** (defined in contracts):
```graphql
mutation ExchangeGoogleIdToken($input: ExchangeGoogleIdTokenInput!) {
  exchangeGoogleIdToken(input: $input)
}
```

**Note**: Backend returns String directly (accessToken). User profile data (email, name, picture) is obtained from the Google Sign-In SDK (`GoogleSignInAccount`) on the client side.

---

### 5. Error Handling Strategy

**Decision**: Map Google OAuth errors to user-friendly messages defined in `app_strings.dart`

**Error Categories**:
1. **User Cancellation**: `GoogleSignInException.canceled` → "Sign-in was cancelled"
2. **Network Errors**: `GoogleSignInException.network` → "Network error. Please check your connection and try again"
3. **Service Unavailable**: Platform errors → "Google sign-in is temporarily unavailable. Please try again later"
4. **Missing Play Services (Android)**: Platform check → "Google Play Services required. Please update your device"
5. **Backend Errors**: GraphQL errors → Handle via existing error patterns

**Rationale**:
- Aligns with spec requirements (FR-006, FR-007)
- Consistent with existing error handling patterns
- User-friendly messages without technical jargon

---

### 6. State Management Approach

**Decision**: Session-only state using Provider (no persistence across app restarts)

**Implementation**:
- Use Provider for reactive state management during session
- Store authentication tokens in `flutter_secure_storage` (via `TokenStorage`)
- Do NOT persist OAuth state in `shared_preferences`
- On app restart, attempt silent sign-in via `signInSilently()`
- If silent sign-in fails, user must re-authenticate

**Rationale**:
- Follows project guidelines (CLAUDE.md: "Session-only state management")
- Security: OAuth state expires naturally, forcing periodic re-authentication
- Simplicity: No complex state persistence logic
- Aligns with existing auth pattern

---

### 7. Test Strategy

**Decision**: Implement TDD with unit, widget, and integration tests

**Test Coverage**:
1. **Unit Tests** (auth_service_test.dart):
   - Test `signInWithGoogle()` success path
   - Test error handling (cancellation, network errors)
   - Test token exchange with backend
   - Mock `GoogleSignIn` and `GraphQLService`

2. **Widget Tests** (oauth_button_test.dart):
   - Test button renders with correct Google branding
   - Test loading state during sign-in
   - Test tap triggers sign-in flow
   - Test accessibility (Semantics labels)

3. **Integration Tests** (auth_flow_test.dart):
   - Test complete OAuth flow (mock Google response)
   - Test account linking for existing email
   - Test new account creation
   - Test error scenarios end-to-end

**Rationale**:
- Constitution requirement: Test-First Development (TDD)
- Ensures reliability of authentication (critical feature)
- Prevents regression during refactoring

---

### 8. Account Linking Logic

**Decision**: Backend handles account linking based on email address

**Logic** (implemented in backend):
```
IF user_email exists in database:
    link_oauth_provider_to_existing_account(email, google_id)
    return existing_user_with_oauth_linked
ELSE:
    create_new_user(email, name, picture, google_id)
    return new_user
END
```

**Mobile Responsibility**:
- Send Google idToken to backend
- Trust backend to handle linking logic
- Display appropriate welcome message (new vs returning user)

**Rationale**:
- Backend is authoritative for user accounts (FR-008)
- Mobile app remains thin client
- Prevents duplicate accounts at data layer
- Consistent with existing architecture

---

## Implementation Best Practices

### 1. Always Initialize Before Use
```dart
await GoogleSignIn().initialize();  // v7.0+ requirement
```

### 2. Implement Silent Sign-In
```dart
// On app startup, attempt to restore session
final account = await _googleSignIn.signInSilently();
if (account != null) {
  // User has valid session, restore state
}
```

### 3. Secure Token Storage
```dart
// Use existing TokenStorage service
await _tokenStorage.saveAccessToken(backendToken);
```

### 4. Handle Platform Differences
```dart
// Plugin handles most differences, but be aware:
// - Android requires Google Play Services
// - iOS requires URL scheme configuration
```

### 5. Test on Real Devices
- Debug vs release mode differences (especially Android SHA-1)
- Test on devices without Google Play Services
- Test account linking with existing email

---

## Known Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Google Play Services unavailable (Android) | High | Check availability before sign-in, provide clear error |
| SHA-1 mismatch (debug vs release) | High | Register both debug and release SHA-1 fingerprints |
| Backend API changes | Medium | Define clear contract in contracts/ directory |
| Network timeout during OAuth | Medium | Implement retry logic, show user-friendly error |
| User cancels OAuth flow | Low | Handle gracefully, return to login screen (FR-006) |

---

## Dependencies to Add

```yaml
dependencies:
  google_sign_in: ^7.0.0  # Add to pubspec.yaml
```

**No other dependencies required** - reuses existing packages:
- `flutter_secure_storage: 9.0.0` (existing)
- `graphql_flutter: 5.1.0` (existing)
- `flutter: sdk` (existing)

---

## Next Steps

1. ✅ Research complete
2. ⏭️ Proceed to Phase 1: Data Model & Contracts
   - Define data structures for OAuth flow
   - Create GraphQL contract for backend integration
   - Document quickstart guide for developers
