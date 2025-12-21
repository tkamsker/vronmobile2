import 'package:flutter/material.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';

/// Form widget for editing project data with validation
class ProjectForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const ProjectForm({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Name Field
        Semantics(
          label: 'projectData.nameLabel'.tr(),
          hint: 'projectData.namePlaceholder'.tr(),
          textField: true,
          child: TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'projectData.nameLabel'.tr(),
              hintText: 'projectData.namePlaceholder'.tr(),
              border: const OutlineInputBorder(),
            ),
            validator: _validateName,
            maxLength: 100,
          ),
        ),

        const SizedBox(height: 16),

        // Project Description Field
        Semantics(
          label: 'projectData.descriptionLabel'.tr(),
          hint: 'projectData.descriptionPlaceholder'.tr(),
          textField: true,
          multiline: true,
          child: TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'projectData.descriptionLabel'.tr(),
              hintText: 'projectData.descriptionPlaceholder'.tr(),
              border: const OutlineInputBorder(),
            ),
            validator: _validateDescription,
            maxLines: 5,
            maxLength: 500,
          ),
        ),
      ],
    );
  }

  /// Validate project name field
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'projectData.validation.nameRequired'.tr();
    }
    if (value.trim().length < 3) {
      return 'projectData.validation.nameTooShort'.tr();
    }
    if (value.trim().length > 100) {
      return 'projectData.validation.nameTooLong'.tr();
    }
    return null;
  }

  /// Validate project description field
  String? _validateDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'projectData.validation.descriptionTooLong'.tr();
    }
    return null;
  }
}
