# Feature Specification: Google OAuth Login (Mobile Redirect Flow)

**Feature Branch**: `003-google-oauth-login`
**Created**: 2025-12-22
**Updated**: 2026-01-06
**Status**: Draft - Breaking Change from Previous Implementation
**Input**: User description: "Google OAuth Login mutation needs fixing"

**BREAKING CHANGE**: Backend team has updated the OAuth implementation from native SDK token-based flow to redirect-based mobile OAuth flow with new `exchangeMobileAuthCode` mutation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Google Sign-In from Login Screen (Priority: P1)

Users can authenticate using their existing Google account instead of creating a new username/password. This provides a faster, more convenient sign-in experience and reduces friction for new users.

**Why this priority**: This is the core value proposition - enabling users to authenticate with Google. Without this, the feature provides no value. It's the minimum viable implementation.

**Independent Test**: Can be fully tested by tapping the "Sign in with Google" button, completing Google's OAuth flow, and verifying successful authentication. Delivers immediate value by allowing Google-based authentication.

**Acceptance Scenarios**:

1. **Given** a user is on the login screen, **When** they tap "Sign in with Google" button, **Then** the app redirects to the backend OAuth URL and Google's consent screen opens in a browser/web view
2. **Given** the user completes Google authentication successfully, **When** the backend redirects back to the app with an authorization code, **Then** the app exchanges the code for an access token and navigates to the main application screen
3. **Given** the user is authenticated via Google, **When** they open the app again, **Then** they remain logged in without re-authenticating
4. **Given** the backend OAuth flow completes, **When** the app receives a deep link callback with query parameters, **Then** the app correctly extracts either the authorization code or error code from the URL

---

### User Story 2 - Error Handling for OAuth Flow (Priority: P2)

Users receive clear feedback when Google authentication fails or is cancelled, allowing them to understand what went wrong and try again.

**Why this priority**: Error handling is essential for production readiness but doesn't block testing the happy path. Users need to understand failures, but the core authentication flow (P1) is more critical.

**Independent Test**: Can be tested independently by cancelling the Google OAuth flow or using invalid credentials, then verifying appropriate error messages are displayed.

**Acceptance Scenarios**:

1. **Given** the user is on Google's OAuth consent screen, **When** they tap "Cancel" or press back, **Then** the backend redirects back to the app with an error code, and the user sees "Sign-in was cancelled"
2. **Given** a network error occurs during the code exchange, **When** the `exchangeMobileAuthCode` mutation request times out, **Then** the user sees "Network error. Please check your connection and try again"
3. **Given** Google OAuth service is unavailable, **When** the backend cannot complete OAuth with Google, **Then** the backend redirects back with an error code, and the user sees "Google sign-in is temporarily unavailable. Please try again later"
4. **Given** the backend returns an error in the redirect URL, **When** the app receives the deep link with `error` query parameter, **Then** the app displays an appropriate error message without attempting code exchange

---

### User Story 3 - Account Linking (Priority: P3)

When a user signs in with Google using an email that already exists in the system (previously registered with email/password), the accounts are automatically linked without creating a duplicate.

**Why this priority**: This is an enhancement that improves user experience for existing users but isn't critical for initial launch. New users and users without existing accounts get full value from P1 and P2.

**Independent Test**: Can be tested by creating an account with email/password, then signing in with Google using the same email address and verifying the accounts are linked (not duplicated).

**Acceptance Scenarios**:

1. **Given** a user has an existing account with email "user@example.com" (email/password), **When** they sign in with Google using "user@example.com", **Then** they access their existing account (not a new account)
2. **Given** a user signs in with Google for the first time with a new email, **When** authentication succeeds, **Then** a new account is created with their Google email and profile information

---

### Edge Cases

- What happens when the deep link callback is malformed or missing query parameters?
- How does the system handle expired or invalid authorization codes from the backend?
- What happens if the user denies email permission during Google OAuth consent?
- How does the system handle concurrent login attempts (email/password while OAuth redirect is in progress)?
- What happens when backend API fails during the OAuth redirect flow?
- How does the system handle deep link callbacks received when the app is not in the foreground?
- What happens if the user manually closes the browser/web view during OAuth flow without completing or cancelling?
- How does the system handle the case where the authorization code has already been used (replay attack)?

## Requirements *(mandatory)*

### Functional Requirements

#### OAuth Flow Requirements

- **FR-001**: System MUST display a "Sign in with Google" button on the login screen that follows Google's branding guidelines
- **FR-002**: System MUST redirect to backend OAuth URL when the user taps the Google sign-in button:
  - URL format: `https://api.vron.stage.motorenflug.at/auth/google?role=MERCHANT&preferredLanguage={LANG}&redirectUrl={DEEP_LINK}&fromMobile=true`
  - Where `{LANG}` is the user's preferred language (EN, DE, PT)
  - Where `{DEEP_LINK}` is the app's deep link for OAuth callback (URL-encoded)
- **FR-003**: System MUST handle deep link callbacks from the backend OAuth flow:
  - Register a custom URL scheme or universal link for OAuth callbacks
  - Parse query parameters: `error` (error code) OR `code` (authorization code)
  - If `error` is present, display appropriate error message to user
  - If `code` is present, proceed to code exchange
- **FR-004**: System MUST exchange authorization code for access token using the `exchangeMobileAuthCode` GraphQL mutation:
  - Mutation input: `{ code: string }`
  - Mutation returns: `{ accessToken: string }`
  - Handle errors from the mutation (invalid code, expired code, network errors)

#### Token and State Management

- **FR-005**: System MUST store authentication tokens securely using the existing TokenStorage service
- **FR-006**: System MUST refresh the GraphQL client with new authentication credentials after successful Google login
- **FR-007**: System MUST persist the authentication state so users remain logged in across app restarts

#### Error Handling

- **FR-008**: System MUST handle OAuth cancellation gracefully:
  - Detect `error` parameter in deep link callback
  - Return the user to the login screen with appropriate message
- **FR-009**: System MUST display user-friendly error messages for authentication failures:
  - Network errors during code exchange
  - Invalid or expired authorization codes
  - Backend service unavailable
  - Malformed deep link callbacks
- **FR-010**: System MUST handle timeout scenarios:
  - If user doesn't complete OAuth flow within reasonable time (e.g., 5 minutes)
  - If deep link callback is not received after redirect

#### Account Management

- **FR-011**: Backend MUST check for existing accounts with the same email and link accounts rather than creating duplicates (backend responsibility, documented here for completeness)

#### UI/UX Requirements

- **FR-012**: System MUST show a loading indicator on the Google sign-in button during the initial redirect
- **FR-013**: System MUST show loading state while exchanging authorization code for access token
- **FR-014**: System MUST follow the existing authentication pattern used by email/password login (using AuthService, TokenStorage, GraphQLService)
- **FR-015**: System MUST comply with accessibility requirements (Semantics labels for the Google sign-in button)

### Key Entities

- **OAuth Authorization Code**: Temporary code received from backend OAuth redirect, used to exchange for access token via `exchangeMobileAuthCode` mutation
- **OAuth Redirect URL**: Deep link URL that the backend uses to return control to the mobile app with either authorization code or error
- **Access Token**: JWT token received from `exchangeMobileAuthCode` mutation, used for authenticating subsequent API requests
- **User Account**: Represents a user in the system, which may be created via email/password or Google OAuth, linked by email address (backend entity)
- **Authentication State**: Tracks whether a user is authenticated, the authentication method used (Google vs email/password), and token expiration status

### Technical Flow

```
1. User taps "Sign in with Google"
2. App redirects to: https://api.vron.stage.motorenflug.at/auth/google
   - Query params: role=MERCHANT, preferredLanguage=EN, redirectUrl=app://oauth-callback, fromMobile=true
3. Backend handles OAuth with Google (user sees Google consent screen)
4. Backend redirects back to app deep link with query params:
   - Success: app://oauth-callback?code=AUTHORIZATION_CODE
   - Error: app://oauth-callback?error=ERROR_CODE
5. App receives deep link callback:
   - If error: Display error message
   - If code: Call exchangeMobileAuthCode mutation
6. Backend validates code and returns accessToken
7. App stores accessToken and completes authentication
```

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully authenticate using their Google account in under 45 seconds (including OAuth consent and redirect flow)
- **SC-002**: The Google sign-in button is immediately recognizable and follows platform design standards
- **SC-003**: 95% of OAuth authentication attempts either succeed or provide a clear error message to the user
- **SC-004**: Users who authenticate via Google remain logged in across app restarts without re-authentication
- **SC-005**: Zero duplicate accounts are created when users sign in with Google using an email that already exists in the system (backend responsibility)
- **SC-006**: Authentication error messages are clear enough that users understand what went wrong without contacting support
- **SC-007**: Deep link callbacks are handled correctly 100% of the time, with appropriate error handling for malformed URLs
- **SC-008**: Authorization code exchange completes successfully within 3 seconds under normal network conditions

---

## Breaking Changes from Previous Implementation

### Old Implementation (Token-based SSO)
- Used `google_sign_in` Flutter package to obtain Google `idToken`
- Called `signInWithGoogle` mutation with `idToken` parameter
- Backend verified `idToken` with Google's API
- Direct token exchange within the app

### New Implementation (Redirect-based Mobile OAuth)
- Uses URL redirect to backend OAuth endpoint
- Backend handles OAuth flow with Google entirely
- Receives authorization code via deep link callback
- Calls NEW `exchangeMobileAuthCode` mutation with `code` parameter
- Backend validates code and returns access token

### Migration Implications
- Remove dependency on `google_sign_in` package (or keep for future use)
- Implement deep link handling for OAuth callbacks
- Update GraphQL mutation from `signInWithGoogle` to `exchangeMobileAuthCode`
- Update UI flow to handle browser/web view redirect
- Update error handling for redirect-based flow
- Re-test entire OAuth flow end-to-end
