import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

/// Account creation prompt dialog
/// Shown when guest user taps "Sign Up" in the guest mode banner
/// Offers choice to continue as guest or create account
class AccountCreationDialog extends StatelessWidget {
  final VoidCallback? onSignUp;

  const AccountCreationDialog({
    super.key,
    this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create an Account?'),
      content: const Text(
        'Create an account to save your scans to the cloud and access them from any device.',
      ),
      actions: [
        Semantics(
          label: 'Continue as Guest button',
          button: true,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44), // Accessibility: minimum touch target
            ),
            child: const Text('Continue as Guest'),
          ),
        ),
        Semantics(
          label: 'Sign Up button',
          button: true,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSignUp?.call();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(44, 44), // Accessibility: minimum touch target
            ),
            child: const Text('Sign Up'),
          ),
        ),
      ],
    );
  }
}
