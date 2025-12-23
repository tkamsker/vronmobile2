import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/auth/widgets/email_input.dart';
import 'package:vronmobile2/features/auth/widgets/password_input.dart';
import 'package:vronmobile2/features/auth/widgets/sign_in_button.dart';
import 'package:vronmobile2/features/auth/widgets/oauth_button.dart';
import 'package:vronmobile2/features/auth/widgets/text_link.dart';
import 'package:vronmobile2/features/auth/services/auth_service.dart';

/// Main authentication screen for non-logged-in users
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();

  bool _isFormValid = false;
  bool _isSignInLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    // Check if both fields have non-empty values
    final hasEmail = _emailController.text.isNotEmpty;
    final hasPassword = _passwordController.text.isNotEmpty;

    // If both fields have values, validate the form
    if (hasEmail && hasPassword) {
      final isValid = _formKey.currentState?.validate() ?? false;
      if (isValid != _isFormValid) {
        setState(() {
          _isFormValid = isValid;
        });
      }
    } else {
      // If either field is empty, form is invalid
      if (_isFormValid) {
        setState(() {
          _isFormValid = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (kDebugMode) print('🔘 [UI] Sign In button pressed');

    if (_formKey.currentState?.validate() ?? false) {
      if (kDebugMode) print('✅ [UI] Form validation passed');

      setState(() {
        _isSignInLoading = true;
      });

      try {
        if (kDebugMode) print('📡 [UI] Calling authentication service...');

        // Call authentication service
        final result = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (kDebugMode) {
          print(
            '📡 [UI] Authentication service returned: ${result.isSuccess ? "SUCCESS" : "FAILURE"}',
          );
        }

        if (!mounted) return;

        if (result.isSuccess) {
          if (kDebugMode) {
            print('✅ [UI] Login successful - navigating to home screen');
          }

          final userEmail = result.data?['email'] as String?;

          // Navigate to home screen and remove login screen from stack
          Navigator.of(
            context,
          ).pushReplacementNamed(AppRoutes.home, arguments: userEmail);

          if (kDebugMode) print('✅ [UI] Navigated to home screen');
        } else {
          if (kDebugMode) print('❌ [UI] Login failed: ${result.error}');
          // Login failed - show error message
          _showError(result.error ?? 'Login failed');
        }
      } catch (e) {
        if (kDebugMode) print('❌ [UI] Unexpected error: ${e.toString()}');
        if (mounted) {
          _showError('Unexpected error: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSignInLoading = false;
          });
        }
      }
    } else {
      if (kDebugMode) print('❌ [UI] Form validation failed');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (kDebugMode) print('🔘 [UI] Google Sign In button pressed');

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      if (kDebugMode) print('📡 [UI] Calling Google OAuth service...');

      // Call Google OAuth service
      final result = await _authService.signInWithGoogle();

      if (kDebugMode) {
        print(
          '📡 [UI] Google OAuth service returned: ${result.isSuccess ? "SUCCESS" : "FAILURE"}',
        );
      }

      if (!mounted) return;

      if (result.isSuccess) {
        if (kDebugMode) {
          print('✅ [UI] Google sign-in successful - navigating to home screen');
        }

        final userEmail = result.data?['email'] as String?;

        // Navigate to home screen and remove login screen from stack
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.home, arguments: userEmail);

        if (kDebugMode) print('✅ [UI] Navigated to home screen');
      } else {
        if (kDebugMode) print('❌ [UI] Google sign-in failed: ${result.error}');
        // Sign-in failed - show error message
        _showError(result.error ?? 'Google sign-in failed');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [UI] Unexpected error: ${e.toString()}');
      if (mounted) {
        _showError('Unexpected error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _handleFacebookSignIn() {
    setState(() {
      _isFacebookLoading = true;
    });
    // TODO: Implement Facebook OAuth (UC4)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isFacebookLoading = false;
        });
      }
    });
  }

  Future<void> _handleForgotPassword() async {
    // T035: Implement forgot password flow (UC5)
    // Opens browser to password reset page
    final baseUrl = EnvConfig.merchantUrl;
    final url = Uri.parse('$baseUrl/auth/forgot-password');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showError('Could not open password reset page');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error opening password reset: ${e.toString()}');
      }
    }
  }

  void _handleCreateAccount() {
    // T036: Navigate to create account screen (UC6)
    try {
      Navigator.pushNamed(context, AppRoutes.createAccount);
    } catch (e) {
      _showError('Navigation error: ${e.toString()}');
    }
  }

  void _handleContinueAsGuest() {
    // T037: Navigate to guest mode (UC7/UC14)
    try {
      Navigator.pushNamed(context, AppRoutes.guestMode);
    } catch (e) {
      _showError('Navigation error: ${e.toString()}');
    }
  }

  // T038: Add navigation error handling
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo/Branding placeholder
                Text(
                  'VRON',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Email input
                EmailInput(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                ),

                const SizedBox(height: 16),

                // Password input
                PasswordInput(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                ),

                const SizedBox(height: 8),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextLink(
                    text: AppStrings.forgotPasswordLink,
                    semanticLabel: AppStrings.forgotPasswordSemantics,
                    onPressed: _handleForgotPassword,
                  ),
                ),

                const SizedBox(height: 24),

                // Sign In button
                SignInButton(
                  onPressed: _isFormValid ? _handleSignIn : null,
                  isLoading: _isSignInLoading,
                ),

                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                // Google sign-in button
                OAuthButton(
                  provider: OAuthProvider.google,
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isGoogleLoading,
                ),

                const SizedBox(height: 12),

                // Facebook sign-in button
                OAuthButton(
                  provider: OAuthProvider.facebook,
                  onPressed: _handleFacebookSignIn,
                  isLoading: _isFacebookLoading,
                ),

                const SizedBox(height: 24),

                // Continue as Guest button
                Semantics(
                  label: AppStrings.guestButtonSemantics,
                  button: true,
                  child: OutlinedButton(
                    onPressed: _handleContinueAsGuest,
                    child: const Text(AppStrings.continueAsGuest),
                  ),
                ),

                const SizedBox(height: 24),

                // Create account link
                Center(
                  child: TextLink(
                    text: AppStrings.createAccountLink,
                    semanticLabel: AppStrings.createAccountSemantics,
                    onPressed: _handleCreateAccount,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
