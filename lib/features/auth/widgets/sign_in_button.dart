import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

/// Primary sign-in button with loading state
class SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SignInButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.signInButtonSemantics,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(AppStrings.signInButton),
      ),
    );
  }
}
