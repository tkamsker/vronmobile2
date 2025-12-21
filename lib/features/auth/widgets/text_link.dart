import 'package:flutter/material.dart';

/// Text link widget with minimum 44x44 touch target
class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String? semanticLabel;

  const TextLink({
    super.key,
    required this.text,
    required this.onPressed,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }
}
