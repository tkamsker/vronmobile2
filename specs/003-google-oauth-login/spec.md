# Feature Specification: Google OAuth Login (SDK-Based Flow)

**Feature Branch**: `003-google-oauth-login`
**Created**: 2025-12-22
**Updated**: 2026-01-06
**Status**: Implemented - SDK-Based Token Exchange
**Input**: User description: "Google OAuth Login mutation needs fixing"

**Implementation Approach**: Uses Google Sign-In SDK (`google_sign_in` package) to obtain Google credentials, then exchanges the idToken with backend via `signInWithGoogle` GraphQL mutation for app access token.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Google Sign-In from Login Screen (Priority: P1)

Users can authenticate using their existing Google account instead of creating a new username/password. This provides a faster, more convenient sign-in experience and reduces friction for new users.

**Why this priority**: This is the core value proposition - enabling users to authenticate with Google. Without this, the feature provides no value. It's the minimum viable implementation.

**Independent Test**: Can be fully tested by tapping the "Sign in with Google" button, completing Google's OAuth flow, and verifying successful authentication. Delivers immediate value by allowing Google-based authentication.

**Acceptance Scenarios**:

1. **Given** a user is on the login screen, **When** they tap "Sign in with Google" button, **Then** the Google Sign-In SDK initiates OAuth flow and Google's consent screen appears
2. **Given** the user completes Google authentication successfully, **When** the SDK returns Google credentials with idToken, **Then** the app sends idToken to backend `signInWithGoogle` mutation, exchanges it for access token, and navigates to the main application screen
3. **Given** the user is authenticated via Google, **When** they open the app again, **Then** they remain logged in without re-authenticating
4. **Given** Google Sign-In SDK returns valid credentials, **When** the app extracts the idToken, **Then** the backend validates the token and returns user profile data along with access token

---

### User Story 2 - Error Handling for OAuth Flow (Priority: P2)

Users receive clear feedback when Google authentication fails or is cancelled, allowing them to understand what went wrong and try again.

**Why this priority**: Error handling is essential for production readiness but doesn't block testing the happy path. Users need to understand failures, but the core authentication flow (P1) is more critical.

**Independent Test**: Can be tested independently by cancelling the Google OAuth flow or using invalid credentials, then verifying appropriate error messages are displayed.

**Acceptance Scenarios**:

1. **Given** the user is on Google's OAuth consent screen, **When** they tap "Cancel" or press back, **Then** the Google Sign-In SDK returns a cancellation error and the user sees "Sign-in was cancelled"
2. **Given** a network error occurs during token exchange, **When** the `signInWithGoogle` mutation request times out, **Then** the user sees "Network error. Please check your connection and try again"
3. **Given** Google OAuth service is unavailable, **When** the SDK cannot complete authentication with Google, **Then** the user sees "Google sign-in is temporarily unavailable. Please try again later"
4. **Given** the backend rejects the idToken, **When** the `signInWithGoogle` mutation returns an error, **Then** the app displays an appropriate error message based on the backend error code

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

- What happens when the Google Sign-In SDK returns null or empty idToken?
- How does the system handle expired or invalid idTokens from Google?
- What happens if the user denies email permission during Google OAuth consent?
- How does the system handle concurrent login attempts (email/password while Google OAuth is in progress)?
- What happens when backend API fails during the idToken validation?
- How does the system handle SDK initialization failures?
- What happens if the user closes the app during OAuth flow without completing or cancelling?
- How does the system handle backend returning invalid or malformed user data?

## Requirements *(mandatory)*

### Functional Requirements

#### OAuth Flow Requirements

- **FR-001**: System MUST display a "Sign in with Google" button on the login screen that follows Google's branding guidelines
- **FR-002**: System MUST initialize and use Google Sign-In SDK when user taps the Google sign-in button:
  - Use `google_sign_in` package (v7.0+)
  - Initialize SDK with `initialize()` method
  - Call `authenticate()` method with required scopes
  - Handle SDK-specific errors (cancellation, network issues, initialization failures)
- **FR-003**: System MUST extract Google credentials from SDK response:
  - Obtain `GoogleSignInAccount` from successful authentication
  - Extract `idToken` from account authentication object
  - Validate idToken is not null or empty before proceeding
  - Handle missing or invalid token scenarios
- **FR-004**: System MUST exchange Google idToken for access token using the `signInWithGoogle` GraphQL mutation:
  - Mutation input: `{ idToken: string }`
  - Mutation returns: `{ accessToken: string, user: { id, email, name, picture, authProviders } }`
  - Handle errors from the mutation (invalid token, expired token, network errors, backend validation failures)

#### Token and State Management

- **FR-005**: System MUST store authentication tokens securely using the existing TokenStorage service
- **FR-006**: System MUST refresh the GraphQL client with new authentication credentials after successful Google login
- **FR-007**: System MUST persist the authentication state so users remain logged in across app restarts

#### Error Handling

- **FR-008**: System MUST handle OAuth cancellation gracefully:
  - Detect SDK cancellation errors (user presses back/cancel)
  - Return the user to the login screen with appropriate message
- **FR-009**: System MUST display user-friendly error messages for authentication failures:
  - Network errors during idToken exchange
  - Invalid or expired idTokens from Google
  - Backend service unavailable
  - SDK initialization failures
  - Missing or null idToken from SDK
- **FR-010**: System MUST handle timeout scenarios:
  - If user doesn't complete OAuth flow within reasonable time
  - If SDK authentication times out
  - If backend mutation times out

#### Account Management

- **FR-011**: Backend MUST check for existing accounts with the same email and link accounts rather than creating duplicates (backend responsibility, documented here for completeness)

#### UI/UX Requirements

- **FR-012**: System MUST show a loading indicator on the Google sign-in button during SDK authentication
- **FR-013**: System MUST show loading state while exchanging idToken for access token with backend
- **FR-014**: System MUST follow the existing authentication pattern used by email/password login (using AuthService, TokenStorage, GraphQLService)
- **FR-015**: System MUST comply with accessibility requirements (Semantics labels for the Google sign-in button)

### Key Entities

- **Google idToken**: JWT token from Google Sign-In SDK containing user identity information, used to authenticate with backend via `signInWithGoogle` mutation
- **GoogleSignInAccount**: SDK object containing user profile (email, name, photo) and authentication credentials
- **Access Token**: JWT token received from `signInWithGoogle` mutation, used for authenticating subsequent API requests
- **User Account**: Represents a user in the system, which may be created via email/password or Google OAuth, linked by email address (backend entity)
- **Authentication State**: Tracks whether a user is authenticated, the authentication method used (Google vs email/password), and token expiration status
- **AuthProviders**: List of authentication providers linked to user account (e.g., EMAIL_PASSWORD, GOOGLE), managed by backend

### Technical Flow

```
1. User taps "Sign in with Google"
2. App initializes Google Sign-In SDK
3. SDK displays Google consent screen
4. User completes Google authentication
5. SDK returns GoogleSignInAccount with idToken
6. App extracts idToken from credentials
7. App calls signInWithGoogle GraphQL mutation:
   - Mutation input: { idToken: "GOOGLE_ID_TOKEN" }
8. Backend validates idToken with Google
9. Backend returns: { accessToken, user { id, email, name, picture, authProviders } }
10. App stores accessToken in secure storage
11. App refreshes GraphQL client with new token
12. App navigates to home screen
```

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully authenticate using their Google account in under 30 seconds (including SDK OAuth consent flow)
- **SC-002**: The Google sign-in button is immediately recognizable and follows platform design standards
- **SC-003**: 95% of OAuth authentication attempts either succeed or provide a clear error message to the user
- **SC-004**: Users who authenticate via Google remain logged in across app restarts without re-authentication
- **SC-005**: Zero duplicate accounts are created when users sign in with Google using an email that already exists in the system (backend responsibility)
- **SC-006**: Authentication error messages are clear enough that users understand what went wrong without contacting support
- **SC-007**: SDK errors are properly mapped to user-friendly messages 100% of the time
- **SC-008**: idToken exchange completes successfully within 3 seconds under normal network conditions

---

## Implementation Approach

### SDK-Based Token Exchange Flow (Current Implementation)
- Uses `google_sign_in` Flutter package (v7.0+) to obtain Google credentials
- SDK handles OAuth flow with Google directly (native Google Sign-In UI)
- App receives `GoogleSignInAccount` with `idToken` from SDK
- Calls `signInWithGoogle` GraphQL mutation with `idToken` parameter
- Backend validates `idToken` with Google's token validation API
- Backend returns access token and user profile data
- No deep links or URL redirects required - all handled within app

### Implementation Dependencies
- **google_sign_in**: ^7.0.0 - Flutter package for Google authentication
- **graphql_flutter**: ^5.1.0 - GraphQL client for backend communication
- **flutter_secure_storage**: ^9.0.0 - Secure token storage
- Backend GraphQL endpoint with `signInWithGoogle` mutation support
- Google Cloud Console project with OAuth 2.0 credentials configured
