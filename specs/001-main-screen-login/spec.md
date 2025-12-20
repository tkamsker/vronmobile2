# Feature Specification: Main Screen (Not Logged-In)

**Feature Branch**: `001-main-screen-login`
**Created**: 2025-12-20
**Status**: Draft
**Input**: User description: "Main screen for non-logged-in users with sign in, OAuth, and guest mode options"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Display Authentication Options (Priority: P1)

A user who opens the app without an active session is presented with a welcome screen that clearly displays all available authentication methods and entry points.

**Why this priority**: This is the first screen users see when not logged in. It must be functional to unblock all other authentication use cases (UC2-UC7). Without this screen, users cannot proceed with any authentication flow.

**Independent Test**: Can be fully tested by launching the app in logged-out state and verifying all UI elements are visible and properly positioned according to the Figma design.

**Acceptance Scenarios**:

1. **Given** the app is launched, **When** no active session exists, **Then** the main screen is displayed with VRON branding
2. **Given** the main screen is displayed, **When** the user views the screen, **Then** email and password input fields are visible
3. **Given** the main screen is displayed, **When** the user views the screen, **Then** "Sign In", "Sign in with Google", and "Sign in with Facebook" buttons are visible
4. **Given** the main screen is displayed, **When** the user views the screen, **Then** "Forgot Password?", "Create Account", and "Guest Mode" options are visible

---

### User Story 2 - Navigate to Authentication Flows (Priority: P2)

Users can tap on any authentication option or link to navigate to the appropriate screen or initiate the corresponding authentication flow.

**Why this priority**: Enables users to actually use the authentication methods. Depends on P1 being complete but can be tested independently by verifying navigation without implementing full authentication logic.

**Independent Test**: Can be tested by tapping each button/link and verifying correct screen transitions or flow initiations occur (even if destination screens show placeholders).

**Acceptance Scenarios**:

1. **Given** the main screen is displayed, **When** user taps "Sign In" button, **Then** authentication attempt is initiated using email and password fields
2. **Given** the main screen is displayed, **When** user taps "Sign in with Google", **Then** Google OAuth flow is initiated
3. **Given** the main screen is displayed, **When** user taps "Sign in with Facebook", **Then** Facebook OAuth flow is initiated
4. **Given** the main screen is displayed, **When** user taps "Forgot Password?" link, **Then** browser opens to password reset page
5. **Given** the main screen is displayed, **When** user taps "Create Account" link, **Then** account creation screen is displayed
6. **Given** the main screen is displayed, **When** user taps "Guest Mode" button, **Then** user navigates directly to scanning screen

---

### User Story 3 - Input Validation and User Feedback (Priority: P3)

The screen provides immediate visual feedback for user interactions and validates email/password inputs before allowing sign-in attempts.

**Why this priority**: Improves user experience and prevents unnecessary API calls, but the screen is functional without it. Can be added as polish after core functionality works.

**Independent Test**: Can be tested by interacting with input fields and buttons, verifying visual states change appropriately (disabled/enabled, error messages, loading indicators).

**Acceptance Scenarios**:

1. **Given** email field is empty, **When** user taps "Sign In", **Then** validation message appears indicating email is required
2. **Given** email format is invalid, **When** user leaves email field, **Then** validation message appears indicating invalid email format
3. **Given** password field is empty, **When** user taps "Sign In", **Then** validation message appears indicating password is required
4. **Given** valid inputs are provided, **When** user taps "Sign In", **Then** button shows loading state during authentication
5. **Given** any OAuth button is tapped, **When** OAuth flow is in progress, **Then** button shows loading state

---

### Edge Cases

- What happens when user is already logged in but navigates to this screen?
- What happens when device has no internet connection and user tries to authenticate?
- What happens when user rapidly taps multiple authentication buttons?
- What happens when user rotates device while on this screen?
- What happens when user backgrounds the app during OAuth flow?
- What happens when OAuth provider is unavailable or returns an error?
- What happens when user enters extremely long text in email/password fields?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Screen MUST display email and password input fields with appropriate input types (email keyboard for email, obscured text for password)
- **FR-002**: Screen MUST display three authentication action buttons: "Sign In", "Sign in with Google", and "Sign in with Facebook"
- **FR-003**: Screen MUST display three navigation links: "Forgot Password?", "Create Account", and "Guest Mode"
- **FR-004**: Email input field MUST validate email format before allowing sign-in attempt
- **FR-005**: Sign In button MUST be disabled when email or password fields are empty
- **FR-006**: "Forgot Password?" link MUST open device's default browser to the password reset URL (configurable environment-specific URL)
- **FR-007**: "Create Account" link MUST navigate to account registration screen (UC6)
- **FR-008**: "Guest Mode" button MUST navigate directly to LiDAR scanning screen (UC14) without authentication
- **FR-009**: "Sign in with Google" button MUST initiate Google OAuth flow (delegates to UC3)
- **FR-010**: "Sign in with Facebook" button MUST initiate Facebook OAuth flow (delegates to UC4)
- **FR-011**: Screen MUST match Figma design specifications for layout, spacing, colors, and typography
- **FR-012**: Screen MUST be accessible with proper semantic labels for screen readers
- **FR-013**: Screen MUST handle keyboard appearance and dismissal without obscuring critical UI elements
- **FR-014**: All interactive elements MUST meet minimum touch target size of 44x44 logical pixels

### Key Entities

- **User Session**: Represents authentication state; when no valid session exists, this screen is shown
- **Authentication Provider**: Represents different auth methods (email/password, Google, Facebook); this screen presents all available providers

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view all authentication options within 1 second of app launch in logged-out state
- **SC-002**: 95% of users successfully navigate to their intended authentication flow on first attempt
- **SC-003**: Screen maintains 60fps performance with smooth animations and transitions
- **SC-004**: All interactive elements are tappable without precision issues (measured by successful tap rate >98%)
- **SC-005**: Screen layout adapts correctly to all supported device sizes and orientations
- **SC-006**: 100% of interactive elements are discoverable by screen readers with meaningful labels
- **SC-007**: Email validation provides immediate feedback within 300ms of user leaving field
- **SC-008**: Users can dismiss keyboard and access all screen elements without scrolling on standard device sizes (iPhone SE and larger)

## Assumptions

- The Figma design (https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-34) is the single source of truth for visual design
- Password reset page URL is configured per environment and accessible via browser
- OAuth flows (Google, Facebook) are implemented in separate features (UC3, UC4) and only need to be triggered from this screen
- Email/password authentication logic (UC2) is implemented separately and only needs to be triggered from this screen
- Account creation screen (UC6) and scanning screen (UC14) exist as separate features
- Standard iOS/Flutter keyboard behavior is sufficient (no custom keyboard required)
- Email validation uses standard RFC-compliant email regex pattern
- App supports iOS devices running version 15.0 or later
- All text content will be internationalized (de, en, pt) but strings are defined in separate i18n feature

## Dependencies

- **Depends on**: Loading screen (from General Requirements) must complete before this screen is shown
- **Blocks**: UC2 (Email Auth), UC3 (Google Login), UC4 (Facebook Login), UC5 (Forgot Password), UC6 (Create Account), UC7 (Guest Mode) - all require this screen to navigate from
- **External**: Figma design must be finalized before implementation begins
- **External**: Environment configuration must include password reset URL
