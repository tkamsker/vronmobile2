# Quickstart Guide: Google OAuth Login Implementation

**Date**: 2025-12-22
**Feature**: 003-google-oauth-login
**For**: Developers implementing the Google OAuth feature

## Overview

This guide provides a step-by-step walkthrough for implementing Google OAuth authentication in the vronmobile2 Flutter application. Follow this guide to understand the architecture, setup requirements, and implementation steps.

---

## Prerequisites

### Required Knowledge
- Dart/Flutter development experience
- Understanding of OAuth 2.0 flow
- Familiarity with Flutter's async/await patterns
- Basic GraphQL knowledge

### Required Accounts & Access
- [ ] Google Cloud Console access
- [ ] Firebase project access (for OAuth configuration)
- [ ] Backend API staging environment access
- [ ] Repository write access

### Required Tools
- Flutter SDK 3.x
- Dart 3.10+
- Android Studio (for Android testing)
- Xcode (for iOS testing)
- Git

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                      Mobile App                          │
│                                                           │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────┐ │
│  │ LoginScreen │──>│ OAuthButton  │──>│ AuthService  │ │
│  │  (UI)       │   │  (Widget)    │   │  (Logic)     │ │
│  └─────────────┘   └──────────────┘   └──────┬───────┘ │
│                                                 │         │
│                                     ┌───────────▼──────┐ │
│                                     │ google_sign_in   │ │
│                                     │    package       │ │
│                                     └───────────┬──────┘ │
└─────────────────────────────────────────────────┼────────┘
                                                  │
                            ┌─────────────────────▼──────────────┐
                            │  Google OAuth Native Flow          │
                            │  (iOS/Android System UI)           │
                            └─────────────────────┬──────────────┘
                                                  │ Returns idToken
┌──────────────────────────────────────────────────▼────────────┐
│                          Backend API                           │
│                                                                 │
│  ┌──────────────────┐   ┌──────────────┐   ┌───────────────┐ │
│  │ GraphQL Mutation │──>│ Token        │──>│ PostgreSQL    │ │
│  │ signInWithGoogle │   │ Validation   │   │ (User DB)     │ │
│  └──────────────────┘   └──────────────┘   └───────────────┘ │
│         │                                                       │
│         └──────> Returns JWT access token                      │
└─────────────────────────────────────────────┬─────────────────┘
                                              │
┌──────────────────────────────────────────────▼────────────────┐
│                     Mobile App (continued)                     │
│                                                                 │
│  ┌──────────────┐   ┌───────────────┐   ┌─────────────────┐  │
│  │ TokenStorage │──>│ GraphQLService│──>│ Authenticated   │  │
│  │ (Secure)     │   │ (Refreshed)   │   │ Home Screen     │  │
│  └──────────────┘   └───────────────┘   └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Google Cloud Setup (15 minutes)

### 1.1 Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create new)
3. Navigate to **APIs & Services** > **Credentials**
4. Click **+ CREATE CREDENTIALS** > **OAuth client ID**

### 1.2 Configure Android OAuth Client

1. Select **Android** as application type
2. Enter package name: `com.vron.vronmobile2` (check android/app/build.gradle)
3. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. Copy **SHA-1** from debug or release keystore
5. Paste SHA-1 in console
6. Click **Create**

### 1.3 Configure iOS OAuth Client

1. Click **+ CREATE CREDENTIALS** > **OAuth client ID** again
2. Select **iOS** as application type
3. Enter bundle ID: `com.vron.vronmobile2` (check ios/Runner.xcodeproj)
4. Click **Create**
5. **Note the iOS Client ID** - you'll need it for Info.plist

### 1.4 Download Configuration Files

**Android**:
1. Go to Firebase Console > Project Settings
2. Under "Your apps", select Android app
3. Download `google-services.json`
4. Place in `android/app/google-services.json`

**iOS**:
1. In Firebase Console, select iOS app
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/GoogleService-Info.plist`
4. Open Xcode project and add file to Runner target

---

## Step 2: Flutter Dependencies (5 minutes)

### 2.1 Update pubspec.yaml

Add `google_sign_in` package:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existing dependencies
  cupertino_icons: ^1.0.8
  url_launcher: ^6.2.0
  graphql_flutter: ^5.1.0
  flutter_secure_storage: ^9.0.0
  flutter_dotenv: ^5.1.0
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  shared_preferences: ^2.2.2

  # NEW: Add this line
  google_sign_in: ^7.0.0
```

### 2.2 Install Dependencies

```bash
flutter pub get
```

---

## Step 3: Platform Configuration (10 minutes)

### 3.1 Android Configuration

**android/app/build.gradle** - Verify Google Services plugin:

```gradle
dependencies {
    // Should already be present from existing setup
    classpath 'com.google.gms:google-services:4.3.15'
}
```

**android/app/build.gradle** (app level) - Verify plugin applied:

```gradle
apply plugin: 'com.google.gms.google-services'
```

**AndroidManifest.xml** - Verify INTERNET permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 3.2 iOS Configuration

**ios/Runner/Info.plist** - Add OAuth configuration:

```xml
<dict>
  <!-- Existing keys -->

  <!-- NEW: Add these keys -->
  <key>GIDClientID</key>
  <string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>

  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
      </array>
    </dict>
  </array>
</dict>
```

**Replace**:
- `YOUR_IOS_CLIENT_ID` with the iOS Client ID from Step 1.3
- `YOUR_CLIENT_ID` with the numeric part of the client ID

**ios/Podfile** - Update post_install (if not present):

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PROTOBUF_USE_DLOPEN=1',
      ]
    end
  end
end
```

Then run:
```bash
cd ios
pod install
cd ..
```

---

## Step 4: Code Implementation (30-45 minutes)

### 4.1 Extend AuthService

**lib/features/auth/services/auth_service.dart**:

```dart
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Existing code...

  // NEW: Initialize Google Sign-In
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  /// NEW: Authenticates user with Google OAuth
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In (v7.0+ requirement)
      await _googleSignIn.initialize();

      // Trigger Google OAuth flow
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      // User canceled
      if (googleAccount == null) {
        return AuthResult.failure('Sign-in was cancelled');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      if (googleAuth.idToken == null) {
        return AuthResult.failure('Failed to obtain Google credentials');
      }

      // Exchange Google token for backend JWT
      final result = await _graphqlService.mutate(
        _signInWithGoogleMutation,
        variables: {
          'input': {'idToken': googleAuth.idToken},
        },
      );

      // Handle GraphQL errors
      if (result.hasException) {
        final exception = result.exception;
        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          return AuthResult.failure(error.message);
        }
        return AuthResult.failure(
          'Authentication failed: ${exception.toString()}',
        );
      }

      // Extract response data
      if (result.data == null || result.data!['signInWithGoogle'] == null) {
        return AuthResult.failure('Invalid response from server');
      }

      final loginData = result.data!['signInWithGoogle'] as Map<String, dynamic>;
      final accessToken = loginData['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        return AuthResult.failure('Invalid login response: missing access token');
      }

      // Create AUTH_CODE (same pattern as email/password login)
      final authCode = _createAuthCode(accessToken);

      // Store tokens
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveAuthCode(authCode);

      // Refresh GraphQL client with new auth
      await _graphqlService.refreshClient();

      // Return success with user data
      final user = loginData['user'] as Map<String, dynamic>;
      return AuthResult.success({
        'email': user['email'],
        'name': user['name'],
        'picture': user['picture'],
      });
    } on PlatformException catch (e) {
      // Handle Google Sign-In specific errors
      return AuthResult.failure(_mapGoogleSignInError(e));
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  /// NEW: Signs out from Google
  Future<void> signOutFromGoogle() async {
    await _googleSignIn.signOut();
  }

  /// NEW: Maps Google Sign-In platform errors to user messages
  String _mapGoogleSignInError(PlatformException e) {
    switch (e.code) {
      case 'sign_in_canceled':
        return 'Sign-in was cancelled';
      case 'network_error':
        return 'Network error. Please check your connection and try again';
      case 'sign_in_failed':
        return 'Google sign-in failed. Please try again';
      default:
        return 'Google sign-in error: ${e.message ?? e.code}';
    }
  }

  // NEW: GraphQL mutation for Google OAuth
  static const String _signInWithGoogleMutation = '''
    mutation SignInWithGoogle(\$input: SignInWithGoogleInput!) {
      signInWithGoogle(input: \$input) {
        accessToken
        user {
          id
          email
          name
          picture
        }
      }
    }
  ''';
}
```

### 4.2 Update Main Screen to Wire Button

**lib/features/auth/screens/main_screen.dart**:

Add handler for Google sign-in button:

```dart
void _handleGoogleSignIn() async {
  setState(() {
    _isGoogleLoading = true;
  });

  try {
    final result = await _authService.signInWithGoogle();

    if (result.isSuccess) {
      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Sign-in failed')),
        );
      }
    }
  } finally {
    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }
}
```

Update UI to include Google button:

```dart
OAuthButton(
  provider: OAuthProvider.google,
  onPressed: _handleGoogleSignIn,
  isLoading: _isGoogleLoading,
),
```

---

## Step 5: Testing (20-30 minutes)

### 5.1 Unit Tests

Create tests for `signInWithGoogle` method:

**test/features/auth/services/auth_service_test.dart**:

```dart
group('signInWithGoogle', () {
  test('returns success when OAuth flow completes', () async {
    // Arrange
    final mockGoogleAccount = MockGoogleSignInAccount();
    final mockAuth = MockGoogleSignInAuthentication();

    when(mockGoogleAccount.authentication).thenAnswer((_) async => mockAuth);
    when(mockAuth.idToken).thenReturn('valid_id_token');

    // Mock GraphQL response
    when(mockGraphQLService.mutate(any, variables: anyNamed('variables')))
        .thenAnswer((_) async => QueryResult(/* success data */));

    // Act
    final result = await authService.signInWithGoogle();

    // Assert
    expect(result.isSuccess, true);
    expect(result.data?['email'], 'test@example.com');
  });

  test('returns failure when user cancels', () async {
    // Arrange
    when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

    // Act
    final result = await authService.signInWithGoogle();

    // Assert
    expect(result.isSuccess, false);
    expect(result.error, 'Sign-in was cancelled');
  });
});
```

### 5.2 Widget Tests

Test OAuthButton behavior:

**test/features/auth/widgets/oauth_button_test.dart**:

```dart
testWidgets('shows loading indicator when isLoading is true', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OAuthButton(
          provider: OAuthProvider.google,
          onPressed: () {},
          isLoading: true,
        ),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text(AppStrings.signInWithGoogle), findsNothing);
});
```

### 5.3 Integration Tests

Test complete OAuth flow:

**test/integration/auth_flow_test.dart**:

```dart
testWidgets('complete Google OAuth flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Tap Google sign-in button
  await tester.tap(find.byType(OAuthButton));
  await tester.pumpAndSettle();

  // Verify loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Mock completes, navigate to home
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

### 5.4 Manual Testing Checklist

**Android**:
- [ ] Debug build works (debug SHA-1 registered)
- [ ] Release build works (release SHA-1 registered)
- [ ] Google Play Services check works
- [ ] User can cancel OAuth flow
- [ ] Account linking works (existing email)

**iOS**:
- [ ] OAuth flow opens in Safari/system browser
- [ ] Callback redirects back to app
- [ ] User can cancel OAuth flow
- [ ] Account linking works (existing email)

---

## Step 6: Deployment Preparation (10 minutes)

### 6.1 Environment Configuration

Ensure OAuth client IDs are configured for:
- [ ] Development environment
- [ ] Staging environment
- [ ] Production environment

### 6.2 Backend Coordination

Confirm with backend team:
- [ ] `signInWithGoogle` mutation is deployed
- [ ] Token validation endpoint is configured
- [ ] Rate limiting is enabled
- [ ] Error codes match contract

### 6.3 Store Configuration

**Google Play Store**:
- Upload release SHA-1 fingerprint
- Verify OAuth consent screen is approved

**Apple App Store**:
- Verify iOS client ID is registered
- Test with TestFlight build

---

## Common Issues & Solutions

### Issue 1: "Sign-in failed" on Android Debug

**Symptom**: OAuth works in release but fails in debug mode

**Solution**:
1. Get debug SHA-1: `cd android && ./gradlew signingReport`
2. Add debug SHA-1 to Firebase Console
3. Re-download `google-services.json`
4. Clean rebuild: `flutter clean && flutter pub get`

### Issue 2: iOS Callback Not Working

**Symptom**: OAuth completes but app doesn't receive callback

**Solution**:
1. Verify `CFBundleURLSchemes` in Info.plist matches reversed client ID
2. Check URL scheme format: `com.googleusercontent.apps.NUMERIC_ID`
3. Ensure Xcode project has URL Types configured

### Issue 3: "Failed to obtain Google credentials"

**Symptom**: OAuth flow completes but idToken is null

**Solution**:
1. Verify OAuth scopes are requested: `email`, `profile`
2. Check Google Cloud Console has correct OAuth consent screen
3. Ensure user grants email permission

### Issue 4: Backend Returns INVALID_TOKEN

**Symptom**: Mobile gets idToken but backend rejects it

**Solution**:
1. Verify backend is using correct OAuth client ID for validation
2. Check token expiration (idToken valid for 1 hour)
3. Ensure backend validates with Google's API

---

## Performance Considerations

### Cold Start Optimization

Initialize Google Sign-In early:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Sign-In
  await GoogleSignIn().initialize();

  runApp(MyApp());
}
```

### Network Optimization

- Implement timeout for OAuth flow (30 seconds per SC-001)
- Cache user profile picture URL
- Retry backend token exchange on network errors

### Memory Management

- Google Sign-In handles lifecycle automatically
- No manual cleanup needed in most cases
- Sign out clears cached credentials

---

## Security Checklist

Before deploying to production:

- [ ] idToken validated by backend (never trusted from client)
- [ ] JWT tokens stored in flutter_secure_storage
- [ ] No tokens logged in production builds
- [ ] HTTPS enforced for all API calls
- [ ] Rate limiting enabled on backend
- [ ] OAuth consent screen reviewed and approved
- [ ] Error messages don't expose sensitive information
- [ ] Google Play Services availability checked on Android

---

## Monitoring & Analytics

### Key Metrics to Track

1. **OAuth Success Rate**: % of initiated flows that complete successfully
2. **Error Distribution**: Which error codes are most common
3. **Platform Comparison**: iOS vs Android success rates
4. **Account Linking Rate**: % of OAuth sign-ins that link to existing accounts
5. **Time to Complete**: Average time from button tap to home screen

### Logging Points

```dart
// Log OAuth initiation
analytics.logEvent('google_signin_initiated');

// Log OAuth success
analytics.logEvent('google_signin_success', parameters: {
  'account_linked': isExistingUser,
  'duration_ms': elapsedMilliseconds,
});

// Log OAuth failure
analytics.logEvent('google_signin_failed', parameters: {
  'error_code': errorCode,
  'error_message': errorMessage,
});
```

---

## Next Steps

After completing this quickstart:

1. ✅ Google OAuth implementation complete
2. ⏭️ Run full test suite
3. ⏭️ Deploy to staging environment
4. ⏭️ Perform UAT (User Acceptance Testing)
5. ⏭️ Deploy to production
6. ⏭️ Monitor metrics and error rates

---

## Resources

### Documentation
- [google_sign_in Package](https://pub.dev/packages/google_sign_in)
- [Google Identity Platform](https://developers.google.com/identity)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)

### Internal References
- [spec.md](./spec.md) - Feature specification
- [research.md](./research.md) - Technical research
- [data-model.md](./data-model.md) - Data structures
- [contracts/graphql-api.md](./contracts/graphql-api.md) - API contract

### Support
- Backend team: Contact for API issues
- DevOps team: Contact for OAuth configuration
- QA team: Coordinate integration testing

---

## Appendix: TDD Workflow

Following the constitution's TDD requirement:

### Red Phase
1. Write failing test for `signInWithGoogle` method
2. Run test, verify it fails
3. Write failing test for error handling
4. Run tests, verify they fail

### Green Phase
1. Implement minimum code to pass first test
2. Run test, verify it passes
3. Implement error handling to pass second test
4. Run tests, verify they pass

### Refactor Phase
1. Extract error mapping logic to helper method
2. Run tests, verify they still pass
3. Simplify token exchange code
4. Run tests, verify they still pass

**Repeat for each component**: OAuthButton updates, main screen integration, etc.
