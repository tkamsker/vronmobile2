import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

/// Password input field with visibility toggle
class PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const PasswordInput({super.key, required this.controller, this.focusNode});

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.passwordInputSemantics,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _isObscured,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: AppStrings.passwordLabel,
          hintText: AppStrings.passwordHint,
          suffixIcon: IconButton(
            icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _isObscured = !_isObscured;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppStrings.passwordRequired;
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
