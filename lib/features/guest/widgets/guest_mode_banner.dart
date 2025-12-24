import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

/// Guest mode banner widget
/// Displays at the top of screens when user is in guest mode
/// Shows amber banner with message and Sign Up button
class GuestModeBanner extends StatelessWidget {
  final VoidCallback onSignUpPressed;

  const GuestModeBanner({
    super.key,
    required this.onSignUpPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Guest Mode active - Scans saved locally only',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border(
            bottom: BorderSide(
              color: Colors.amber.shade700,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.amber.shade900,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.guestModeBanner,
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Sign Up button',
              button: true,
              child: TextButton(
                onPressed: onSignUpPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(44, 44), // Accessibility: minimum touch target
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
