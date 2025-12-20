import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/features/auth/utils/email_validator.dart';

/// Email input field with validation
class EmailInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const EmailInput({
    super.key,
    required this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.emailInputSemantics,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: AppStrings.emailLabel,
          hintText: AppStrings.emailHint,
        ),
        validator: EmailValidator.validate,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
