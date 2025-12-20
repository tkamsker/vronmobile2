# Research: Main Screen (Not Logged-In)

**Feature**: 001-main-screen-login
**Date**: 2025-12-20
**Purpose**: Research Flutter best practices for authentication screens, input validation, accessibility, and navigation patterns

## Research Areas

### 1. Flutter Form Validation Patterns

**Decision**: Use `TextFormField` with `Form` widget and validation callbacks

**Rationale**:
- `TextFormField` is Flutter's built-in widget designed for form inputs with validation
- `Form` widget provides centralized validation control via `GlobalKey<FormState>`
- Validation callbacks (`validator`) execute synchronously and return error strings
- Built-in support for showing/hiding validation messages
- No additional dependencies required

**Alternatives Considered**:
- **Custom validation library** (e.g., `form_field_validator`): Rejected - adds dependency for simple use case, violates YAGNI
- **Reactive forms** (e.g., `flutter_form_builder`): Rejected - over-engineered for single screen with 2 input fields
- **Manual TextField with custom validation**: Rejected - reinvents Form widget functionality

**Implementation Approach**:
```dart
// Email validation example
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!emailRegex.hasMatch(value)) {
    return 'Invalid email format';
  }
  return null; // Valid
}
```

**References**:
- Flutter docs: https://docs.flutter.dev/cookbook/forms/validation
- Dart RegExp for email: RFC 5322 simplified pattern

---

### 2. Navigation Between Screens

**Decision**: Use Flutter's built-in `Navigator.push` and named routes

**Rationale**:
- `Navigator` is Flutter's standard routing mechanism
- Named routes provide clean separation of route definitions
- No routing package needed for simple navigation (YAGNI principle)
- Easy to test navigation with mock Navigator observers

**Alternatives Considered**:
- **go_router package**: Rejected - over-engineered for current needs, adds dependency
- **Auto_route package**: Rejected - code generation overhead not justified
- **GetX navigation**: Rejected - pulls in entire state management library

**Implementation Approach**:
```dart
// Define routes in lib/core/navigation/routes.dart
class AppRoutes {
  static const main = '/';
  static const createAccount = '/create-account';
  static const guestMode = '/guest-mode';
  // etc.
}

// Navigate
Navigator.pushNamed(context, AppRoutes.createAccount);
```

**References**:
- Flutter Navigation docs: https://docs.flutter.dev/cookbook/navigation/named-routes

---

### 3. Opening External URLs (Password Reset)

**Decision**: Use `url_launcher` package

**Rationale**:
- Official Flutter package maintained by flutter.dev team
- Cross-platform support (iOS/Android/Web)
- Simple API: `launchUrl(Uri.parse(url))`
- Handles platform-specific browser launching

**Alternatives Considered**:
- **webview_flutter**: Rejected - opens URL in embedded WebView, not native browser (spec requires browser)
- **Custom platform channels**: Rejected - reinventing existing solution

**Implementation Approach**:
```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openPasswordReset() async {
  final url = Uri.parse('https://vron.one/forgot-password');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
```

**References**:
- url_launcher package: https://pub.dev/packages/url_launcher

---

### 4. Accessibility Best Practices

**Decision**: Use `Semantics` widget and semantic properties on existing widgets

**Rationale**:
- Flutter's semantic tree automatically generates accessibility data
- Most widgets (TextFormField, ElevatedButton) have built-in semantic properties
- `Semantics` widget wraps custom widgets to add labels
- Testable via `flutter_test` semantic matchers

**Alternatives Considered**:
- **Manual screen reader testing only**: Rejected - not automated, doesn't catch regressions
- **Third-party accessibility libraries**: Rejected - Flutter's built-in support is sufficient

**Implementation Approach**:
```dart
// Most widgets have automatic semantics
ElevatedButton(
  onPressed: () {},
  child: Text('Sign In'), // Text automatically becomes semantic label
)

// For custom widgets or clarification
Semantics(
  label: 'Email address input field',
  hint: 'Enter your email to sign in',
  child: TextFormField(
    decoration: InputDecoration(labelText: 'Email'),
  ),
)

// Testing
expect(
  find.bySemanticsLabel('Sign In'),
  findsOneWidget,
);
```

**References**:
- Flutter Accessibility guide: https://docs.flutter.dev/development/accessibility-and-localization/accessibility
- Semantic testing: https://api.flutter.dev/flutter/flutter_test/CommonFinders/bySemanticsLabel.html

---

### 5. Keyboard Handling & Layout Adjustments

**Decision**: Use `Scaffold` with `resizeToAvoidBottomInset: true` and `SingleChildScrollView`

**Rationale**:
- `Scaffold` automatically adjusts when keyboard appears if `resizeToAvoidBottomInset: true`
- `SingleChildScrollView` ensures content is scrollable if keyboard would obscure inputs
- No additional packages needed
- Standard Flutter pattern for forms

**Alternatives Considered**:
- **Manual padding calculations**: Rejected - error-prone, doesn't handle all cases
- **keyboard_actions package**: Rejected - adds dependency for basic functionality

**Implementation Approach**:
```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        // form content
      ),
    ),
  ),
)
```

**References**:
- Scaffold resizing: https://api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomInset.html

---

### 6. Touch Target Sizes (Accessibility)

**Decision**: Ensure all interactive widgets are minimum 44x44 logical pixels

**Rationale**:
- WCAG 2.1 Level AA requires minimum 44x44 pixels for touch targets
- Flutter's Material buttons (ElevatedButton, TextButton) default to 48px height (compliant)
- Custom widgets or smaller buttons need explicit sizing

**Alternatives Considered**:
- **Ignoring guideline**: Rejected - violates constitution's accessibility requirements
- **Using 48x48 everywhere**: Acceptable - provides more buffer than minimum

**Implementation Approach**:
```dart
// Buttons automatically compliant
ElevatedButton(
  onPressed: () {},
  child: Text('Sign In'),
) // Defaults to 48px height

// For TextButton links, ensure padding
TextButton(
  onPressed: () {},
  style: TextButton.styleFrom(
    minimumSize: Size(44, 44), // Enforce minimum
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: Text('Forgot Password?'),
)
```

**References**:
- WCAG 2.1 Target Size: https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
- Material Button specs: https://m3.material.io/components/buttons/specs

---

### 7. Email Validation Regex

**Decision**: Use simplified RFC 5322 regex pattern

**Rationale**:
- Full RFC 5322 email regex is extremely complex and unnecessary
- Simplified pattern catches 99% of valid/invalid emails
- Client-side validation is for UX only (backend does authoritative validation)
- Standard pattern: `^[^@]+@[^@]+\.[^@]+$`

**Alternatives Considered**:
- **Full RFC 5322 regex**: Rejected - overly complex, hard to maintain
- **email_validator package**: Rejected - adds dependency for one-line regex
- **No validation**: Rejected - poor UX, violates functional requirements

**Pattern**:
```dart
final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
```

**References**:
- Email validation discussion: https://stackoverflow.com/questions/201323/how-can-i-validate-an-email-address-using-a-regular-expression

---

### 8. Internationalization (i18n) Preparation

**Decision**: Use Flutter's built-in `intl` package with ARB files

**Rationale**:
- Official Flutter approach to i18n
- ARB (Application Resource Bundle) files are industry standard
- Supports de/en/pt as specified
- Type-safe string access via generated code
- Spec indicates i18n strings defined in separate feature (UC22), but structure should support it

**Alternatives Considered**:
- **easy_localization package**: Rejected - third-party when official solution exists
- **Hard-coded strings**: Rejected - violates spec's internationalization assumption

**Implementation Approach**:
```dart
// Structure (will be populated by UC22)
lib/l10n/
├── app_en.arb
├── app_de.arb
└── app_pt.arb

// Usage (once UC22 implemented)
Text(AppLocalizations.of(context)!.signInButton)
```

**References**:
- Flutter i18n guide: https://docs.flutter.dev/development/accessibility-and-localization/internationalization

---

## Summary of Technology Decisions

| Area | Technology | Justification |
|------|------------|---------------|
| UI Framework | Flutter Material widgets | Built-in, cross-platform, matches iOS guidelines for auth screens |
| Form Validation | TextFormField + Form widget | Built-in, no dependencies, sufficient for use case |
| Navigation | Navigator with named routes | Simple, built-in, testable |
| External URLs | url_launcher package | Official package, cross-platform |
| Accessibility | Semantics widget + built-in properties | Flutter's native support, testable |
| Keyboard Handling | Scaffold resizeToAvoidBottomInset | Automatic, no dependencies |
| Email Validation | RegExp (simplified RFC 5322) | Simple one-liner, sufficient for client-side |
| i18n | intl package + ARB files | Official Flutter approach, type-safe |

**All decisions align with constitution principles**: Test-First (all testable), Simplicity & YAGNI (minimal dependencies), Platform-Native Patterns (Flutter idioms).
