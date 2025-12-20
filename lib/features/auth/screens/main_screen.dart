import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/features/auth/widgets/email_input.dart';
import 'package:vronmobile2/features/auth/widgets/password_input.dart';
import 'package:vronmobile2/features/auth/widgets/sign_in_button.dart';
import 'package:vronmobile2/features/auth/widgets/oauth_button.dart';
import 'package:vronmobile2/features/auth/widgets/text_link.dart';

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

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSignInLoading = true;
      });
      // TODO: Implement email/password authentication (UC2)
      // Placeholder for now
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isSignInLoading = false;
          });
        }
      });
    }
  }

  void _handleGoogleSignIn() {
    setState(() {
      _isGoogleLoading = true;
    });
    // TODO: Implement Google OAuth (UC3)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    });
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

  void _handleForgotPassword() {
    // TODO: Implement forgot password flow (UC5)
    // Opens browser to password reset page
  }

  void _handleCreateAccount() {
    // TODO: Navigate to create account screen (UC6)
    // Navigator.pushNamed(context, AppRoutes.createAccount);
  }

  void _handleContinueAsGuest() {
    // TODO: Navigate to guest mode (UC7)
    // Navigator.pushNamed(context, AppRoutes.guestMode);
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
