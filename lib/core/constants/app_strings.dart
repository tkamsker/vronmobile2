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

  // Project management strings
  static const String createProjectTitle = 'Create Project';
  static const String projectNameLabel = 'Name';
  static const String projectNameHint = 'My Room';
  static const String projectSlugLabel = 'Slug';
  static const String projectSlugHint = 'my-room';
  static const String projectSlugHelper = 'Auto-generated from name (editable)';
  static const String projectDescriptionLabel = 'Description';
  static const String projectDescriptionHint = 'Optional description';
  static const String createProjectButton = 'Create Project';
  static const String saveProjectButton = 'Save';
  static const String cancelButton = 'Cancel';

  // Project validation messages
  static const String projectNameRequired = 'Name is required';
  static const String projectNameTooShort = 'Name must be at least 3 characters';
  static const String projectNameTooLong = 'Name must be 100 characters or less';
  static const String projectSlugRequired = 'Slug is required';
  static const String projectSlugInvalid = 'Slug must contain only lowercase letters, numbers, and hyphens';
  static const String projectSlugDuplicate = 'A project with this slug already exists';

  // Project success messages
  static const String projectCreatedSuccess = 'Project created successfully';
  static const String projectUpdatedSuccess = 'Project updated successfully';

  // Project error messages
  static const String projectCreateError = 'Error creating project';
  static const String projectNetworkError = 'Network error. Please try again.';

  // Unsaved changes dialog
  static const String unsavedChangesTitle = 'Unsaved Changes';
  static const String unsavedChangesMessage = 'You have unsaved changes. Discard them?';
  static const String keepEditingButton = 'Keep Editing';
  static const String discardButton = 'Discard';

  // Project semantics
  static const String projectNameSemantics = 'Project name input field';
  static const String projectSlugSemantics = 'Project slug input field';
  static const String projectDescriptionSemantics = 'Project description input field';
  static const String createProjectButtonSemantics = 'Create project button';
  static const String saveProjectButtonSemantics = 'Save project button';

  // LiDAR Scanning strings (Feature 014)
  static const String scanningTitle = 'LiDAR Scanning';
  static const String startScanButton = 'Start Scanning';
  static const String stopScanButton = 'Stop Scanning';
  static const String uploadGlbButton = 'Upload GLB File';
  static const String saveScanButton = 'Save to Project';
  static const String previewScanButton = 'Preview';
  static const String scanInProgress = 'Scanning in progress...';
  static const String scanComplete = 'Scan complete';
  static const String scanSaved = 'Scan saved locally';

  // LiDAR capability messages
  static const String lidarNotSupported = 'LiDAR scanning is not supported on this device';
  static const String lidarRequiresIPhone12Pro = 'Requires iPhone 12 Pro or newer with LiDAR sensor';
  static const String lidarIOSOnly = 'LiDAR scanning is only available on iOS devices';
  static const String lidarOldIOSVersion = 'Requires iOS 16.0 or later for LiDAR scanning';

  // Scanning error messages
  static const String scanPermissionDenied = 'Camera permission is required for LiDAR scanning';
  static const String scanPermissionDeniedDetail = 'Please enable camera access in Settings';
  static const String scanStorageError = 'Failed to save scan data';
  static const String scanStorageFull = 'Insufficient storage space';
  static const String scanInterrupted = 'Scan was interrupted';
  static const String scanFailed = 'Scan failed. Please try again';
  static const String scanTimeout = 'Scan took too long and was cancelled';

  // File upload error messages
  static const String filePickerCancelled = 'File selection cancelled';
  static const String fileInvalidFormat = 'Invalid file format. Please select a .glb file';
  static const String fileTooLarge = 'File size exceeds 250 MB limit';
  static const String fileReadError = 'Failed to read selected file';
  static const String fileUploadError = 'Failed to upload file';

  // Scan interruption dialog
  static const String scanInterruptedTitle = 'Scan Interrupted';
  static const String scanInterruptedMessage = 'The scan was interrupted. What would you like to do?';
  static const String savePartialButton = 'Save Partial Scan';
  static const String discardScanButton = 'Discard';
  static const String continueScanButton = 'Continue Scanning';

  // Conversion messages (US3)
  static const String convertingToGlb = 'Converting to GLB format...';
  static const String conversionComplete = 'Conversion complete';
  static const String conversionFailed = 'Conversion failed';
  static const String conversionUnsupportedGeometry = 'Scan contains unsupported geometry';
  static const String conversionMissingTextures = 'Some textures are missing or corrupted';
  static const String conversionMemoryExceeded = 'Conversion requires too much memory';
  static const String conversionTimeout = 'Conversion took too long';

  // Scanning semantics
  static const String startScanButtonSemantics = 'Start LiDAR scanning button';
  static const String startScanButtonHint = 'Begin scanning the room with LiDAR sensor';
  static const String stopScanButtonSemantics = 'Stop scanning button';
  static const String stopScanButtonHint = 'Stop the current LiDAR scan';
  static const String uploadGlbButtonSemantics = 'Upload GLB file button';
  static const String uploadGlbButtonHint = 'Select and upload an existing GLB file';
  static const String scanProgressSemantics = 'Scan progress indicator';
  static const String scanProgressHint = 'Shows the progress of the current scan';
}
