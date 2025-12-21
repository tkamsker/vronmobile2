# Data Model: Main Screen (Not Logged-In)

**Feature**: 001-main-screen-login
**Date**: 2025-12-20

## Overview

This feature has minimal data model requirements as it's primarily a UI screen that coordinates navigation to authentication flows. No persistent data storage is needed.

## Entities

### FormState (Ephemeral UI State)

**Purpose**: Manages the state of email/password inputs during user interaction

**Lifecycle**: Created when screen loads, disposed when screen unmounts

**Fields**:

| Field | Type | Validation Rules | Description |
|-------|------|------------------|-------------|
| `email` | `String` | Required, email format (regex) | User's email address input |
| `password` | `String` | Required, non-empty | User's password input (not validated for complexity on this screen) |
| `isValid` | `bool` | Computed from validators | Whether form can be submitted |

**State Management**: Managed by Flutter's `GlobalKey<FormState>` - no external state management library needed

**Example**:
```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(/* email */),
      TextFormField(/* password */),
    ],
  ),
)

// Validation
if (_formKey.currentState!.validate()) {
  // Form is valid, trigger authentication
}
```

---

### NavigationDestination (Enum)

**Purpose**: Type-safe representation of navigation targets from this screen

**Lifecycle**: Compile-time constants

**Values**:

| Value | Target Screen | Feature | Description |
|-------|---------------|---------|-------------|
| `emailAuth` | Email/Password Auth | UC2 | Sign In with email/password |
| `googleAuth` | Google OAuth | UC3 | Sign In with Google |
| `facebookAuth` | Facebook OAuth | UC4 | Sign In with Facebook |
| `forgotPassword` | External Browser | UC5 | Password reset (web) |
| `createAccount` | Registration Screen | UC6 | Create new account |
| `guestMode` | Scanning Screen | UC7/UC14 | Enter app without login |

**Example**:
```dart
enum NavigationDestination {
  emailAuth,
  googleAuth,
  facebookAuth,
  forgotPassword,
  createAccount,
  guestMode,
}

void _navigate(NavigationDestination destination) {
  switch (destination) {
    case NavigationDestination.emailAuth:
      // Trigger UC2 authentication flow
      break;
    case NavigationDestination.createAccount:
      Navigator.pushNamed(context, AppRoutes.createAccount);
      break;
    // etc.
  }
}
```

---

### ValidationResult (Value Object)

**Purpose**: Encapsulates validation outcome for testability

**Lifecycle**: Created during validation, short-lived

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `isValid` | `bool` | Whether validation passed |
| `errorMessage` | `String?` | Error message if invalid, null if valid |

**Example**:
```dart
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.valid() : isValid = true, errorMessage = null;
  ValidationResult.invalid(this.errorMessage) : isValid = false;
}

ValidationResult validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return ValidationResult.invalid('Email is required');
  }
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(email)) {
    return ValidationResult.invalid('Invalid email format');
  }
  return ValidationResult.valid();
}
```

---

## State Transitions

This screen has no complex state machine. The only states are:

1. **Initial**: Form empty, Sign In button disabled
2. **Filling**: User typing, validation occurs on blur
3. **Valid**: Both fields valid, Sign In button enabled
4. **Submitting**: User tapped button, loading indicator shown (handled by navigation flow)
5. **Disposed**: User navigated away, form state cleared

```text
[Initial] --user types--> [Filling] --validation passes--> [Valid]
                                   --validation fails--> [Filling]

[Valid] --user taps button--> [Submitting] --navigation--> [Disposed]
[Any State] --back button--> [Disposed]
```

---

## Validation Rules

### Email Field

| Rule | Error Message | Regex/Logic |
|------|---------------|-------------|
| Required | "Email is required" | `value == null \|\| value.isEmpty` |
| Valid format | "Invalid email format" | `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$` |

### Password Field

| Rule | Error Message | Logic |
|------|---------------|-------|
| Required | "Password is required" | `value == null \|\| value.isEmpty` |

**Note**: Password complexity validation happens on registration (UC6), not on login screen.

---

## No Persistent Storage

This feature does not store any data:
- ❌ No database
- ❌ No SharedPreferences
- ❌ No secure storage
- ❌ No file system writes

Email/password values exist only in RAM while the screen is active. Authentication logic (UC2) handles secure storage of tokens.

---

## Relationships to Other Features

| Related Feature | Relationship | Data Flow |
|----------------|--------------|-----------|
| UC2: Email Auth | Invokes | Passes `email` and `password` strings to auth service |
| UC3: Google OAuth | Triggers | No data passed, OAuth flow is self-contained |
| UC4: Facebook OAuth | Triggers | No data passed, OAuth flow is self-contained |
| UC5: Forgot Password | Opens Browser | No data passed, user enters email on web form |
| UC6: Create Account | Navigates | No data passed to registration screen |
| UC7: Guest Mode | Navigates | No data passed, guest session is stateless |

---

## Testing Considerations

### Unit Tests
- Validate email regex patterns (valid/invalid cases)
- Validate required field logic
- ValidationResult value object behavior

### Widget Tests
- Form validation triggers on blur
- Error messages display correctly
- Button enabled/disabled based on form state

### Integration Tests
- Navigation flows to correct destinations
- Form state cleared on navigation back
