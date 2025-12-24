/// i18n string keys stub
/// Actual translations will be implemented in UC22 (Language Selection)
class AppStrings {
  // Main screen labels
  static const String emailLabel = 'Email';
  static const String emailHint = 'Enter your email';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';

  // Button labels
  static const String signInButton = 'Sign In';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String signInWithFacebook = 'Sign in with Facebook';
  static const String continueAsGuest = 'Continue as Guest';

  // Link labels
  static const String forgotPasswordLink = 'Forgot Password?';
  static const String createAccountLink = 'Create Account';

  // Validation messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Invalid email format';
  static const String passwordRequired = 'Password is required';

  // OAuth error messages
  static const String oauthCancelled = 'Sign-in was cancelled';
  static const String oauthNetworkError = 'Network error. Please check your connection and try again';
  static const String oauthServiceUnavailable = 'Google sign-in is temporarily unavailable. Please try again later';
  static const String oauthInvalidCredentials = 'Failed to obtain Google credentials';
  static const String oauthAuthenticationFailed = 'Authentication failed. Please try again';
  static const String oauthBackendError = 'Sign-in failed. Please try again later';

  // Accessibility labels
  static const String emailInputSemantics = 'Email address input field';
  static const String passwordInputSemantics = 'Password input field';
  static const String signInButtonSemantics = 'Sign in button';
  static const String googleButtonSemantics = 'Sign in with Google button';
  static const String facebookButtonSemantics = 'Sign in with Facebook button';
  static const String guestButtonSemantics = 'Continue as guest button';
  static const String forgotPasswordSemantics = 'Forgot password link';
  static const String createAccountSemantics = 'Create account link';

  // Guest mode strings
  static const String guestModeTitle = 'Guest Mode';
  static const String guestModeBanner = 'Guest Mode - Scans saved locally only';
  static const String guestModeButton = 'Continue as Guest';
  static const String guestModeHint = 'Scan rooms without creating an account';
  static const String guestSignUpButton = 'Sign Up';
  static const String guestContinueButton = 'Continue as Guest';

  // Account creation dialog
  static const String createAccountTitle = 'Create Account';
  static const String createAccountMessage = 'Sign up to unlock:';
  static const String createAccountBenefit1 = 'Save scans to the cloud';
  static const String createAccountBenefit2 = 'Access from any device';
  static const String createAccountBenefit3 = 'Share with team members';
  static const String createAccountBenefit4 = 'Unlimited scan storage';
  static const String createAccountNote = 'Note: Guest scans cannot be migrated to your account.';

  // Guest mode semantics
  static const String guestModeBannerSemantics = 'Guest Mode Active';
  static const String guestModeBannerHint = 'You are using the app without an account. Scans are saved on this device only.';
  static const String guestSignUpButtonSemantics = 'Sign Up';
  static const String guestSignUpButtonHint = 'Create an account to save scans to the cloud';
}
