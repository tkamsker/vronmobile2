import 'package:flutter/material.dart';

/// Custom floating action button for creating new projects
class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Create new project',
      button: true,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF2196F3), // Blue color from design
        elevation: 6,
        child: const Icon(
          Icons.add,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}
