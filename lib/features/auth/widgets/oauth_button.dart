import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/core/theme/app_theme.dart';

/// OAuth provider types
enum OAuthProvider { google, facebook }

/// OAuth button for Google/Facebook authentication
class OAuthButton extends StatelessWidget {
  final OAuthProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const OAuthButton({
    super.key,
    required this.provider,
    required this.onPressed,
    required this.isLoading,
  });

  String get _buttonText {
    switch (provider) {
      case OAuthProvider.google:
        return AppStrings.signInWithGoogle;
      case OAuthProvider.facebook:
        return AppStrings.signInWithFacebook;
    }
  }

  String get _semanticLabel {
    switch (provider) {
      case OAuthProvider.google:
        return AppStrings.googleButtonSemantics;
      case OAuthProvider.facebook:
        return AppStrings.facebookButtonSemantics;
    }
  }

  Color get _backgroundColor {
    switch (provider) {
      case OAuthProvider.google:
        return AppTheme.googleBlue;
      case OAuthProvider.facebook:
        return AppTheme.facebookBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      button: true,
      enabled: !isLoading,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(_buttonText),
      ),
    );
  }
}
