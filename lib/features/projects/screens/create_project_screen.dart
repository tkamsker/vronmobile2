import 'package:flutter/material.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/core/utils/slug_generator.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';

/// Screen for creating a new project
///
/// Provides a form with:
/// - Name field (required, 3-100 chars)
/// - Slug field (auto-generated, editable)
/// - Description field (optional)
///
/// Features:
/// - Auto-generates slug from name as user types
/// - Validates input before submission
/// - Handles duplicate slug errors from backend
/// - Shows unsaved changes warning on navigation
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late ProjectService _projectService;

  bool _isDirty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _descriptionController = TextEditingController();
    _projectService = ProjectService();

    // Auto-generate slug from name as user types
    _nameController.addListener(_generateSlug);

    // Track dirty state for unsaved changes warning
    _nameController.addListener(_onFieldChanged);
    _slugController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Auto-generate slug from project name
  void _generateSlug() {
    final name = _nameController.text;
    final generatedSlug = SlugGenerator.slugify(name);

    // Only update if slug has changed to avoid cursor jumping
    if (_slugController.text != generatedSlug) {
      _slugController.text = generatedSlug;
    }
  }

  /// Track whether form has unsaved changes
  void _onFieldChanged() {
    final isDirty = _nameController.text.isNotEmpty ||
        _slugController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty;

    if (isDirty != _isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  /// Handle form submission
  Future<void> _handleSave() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create project via service
      await _projectService.createProject(
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.projectCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back with success indicator
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.projectCreateError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle back navigation with unsaved changes warning
  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop || !_isDirty) return;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.unsavedChangesTitle),
        content: const Text(AppStrings.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.keepEditingButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.discardButton),
          ),
        ],
      ),
    );

    if (shouldPop == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.createProjectTitle),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Name field (required)
              Semantics(
                label: AppStrings.projectNameSemantics,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.projectNameLabel,
                    hintText: AppStrings.projectNameHint,
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.projectNameRequired;
                    }
                    if (value.trim().length < 3) {
                      return AppStrings.projectNameTooShort;
                    }
                    if (value.trim().length > 100) {
                      return AppStrings.projectNameTooLong;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Slug field (auto-generated but editable)
              Semantics(
                label: AppStrings.projectSlugSemantics,
                child: TextFormField(
                  controller: _slugController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.projectSlugLabel,
                    hintText: AppStrings.projectSlugHint,
                    helperText: AppStrings.projectSlugHelper,
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.projectSlugRequired;
                    }
                    if (!SlugGenerator.isValidSlug(value.trim())) {
                      return AppStrings.projectSlugInvalid;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Description field (optional)
              Semantics(
                label: AppStrings.projectDescriptionSemantics,
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.projectDescriptionLabel,
                    hintText: AppStrings.projectDescriptionHint,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSave(),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              Semantics(
                label: AppStrings.createProjectButtonSemantics,
                button: true,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(AppStrings.createProjectButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
