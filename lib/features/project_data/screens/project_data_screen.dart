import 'package:flutter/material.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import 'package:vronmobile2/features/project_data/widgets/project_form.dart';
import 'package:vronmobile2/features/project_data/widgets/save_button.dart';

/// Screen for editing project data
class ProjectDataScreen extends StatefulWidget {
  final String projectId;
  final String initialName;
  final String initialDescription;

  const ProjectDataScreen({
    super.key,
    required this.projectId,
    required this.initialName,
    required this.initialDescription,
  });

  @override
  State<ProjectDataScreen> createState() => _ProjectDataScreenState();
}

class _ProjectDataScreenState extends State<ProjectDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final ProjectService _projectService = ProjectService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Check if form has unsaved changes
  bool get _hasUnsavedChanges {
    return _nameController.text.trim() != widget.initialName ||
           _descriptionController.text.trim() != widget.initialDescription;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);

        if (!_hasUnsavedChanges) {
          if (mounted) {
            navigator.pop(false);
          }
          return;
        }

        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop == true && mounted) {
          navigator.pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('projectData.title'.tr()),
          leading: Semantics(
            button: true,
            label: 'Close and discard changes',
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _handleCancel,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle
                Text(
                  'projectData.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),

                const SizedBox(height: 24),

                // Form Fields
                ProjectForm(
                  nameController: _nameController,
                  descriptionController: _descriptionController,
                ),

                const SizedBox(height: 32),

                // Save Button
                Semantics(
                  button: true,
                  label: 'projectData.saveButton'.tr(),
                  enabled: !_isLoading,
                  child: SaveButton(
                    onPressed: _handleSave,
                    label: 'projectData.saveButton'.tr(),
                    isLoading: _isLoading,
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel Button
                Semantics(
                  button: true,
                  label: 'projectData.cancelButton'.tr(),
                  enabled: !_isLoading,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('projectData.cancelButton'.tr()),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Changes Note
                Center(
                  child: Text(
                    'Changes will be saved immediately',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle save button press
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final input = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      await _projectService.updateProject(widget.projectId, input);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('projectData.saveSuccess'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final errorMessage = _parseErrorMessage(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'common.retry'.tr(),
              textColor: Colors.white,
              onPressed: _handleSave,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Handle cancel button press
  Future<void> _handleCancel() async {
    if (_isLoading) return;

    if (!_hasUnsavedChanges) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    final shouldDiscard = await _showUnsavedChangesDialog();
    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  /// Show unsaved changes confirmation dialog
  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('projectData.unsavedChangesTitle'.tr()),
        content: Text('projectData.unsavedChangesMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('projectData.keepEditingButton'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('projectData.discardButton'.tr()),
          ),
        ],
      ),
    );
  }

  /// Parse error message to user-friendly text
  String _parseErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('not found')) {
      return 'projectData.errors.notFound'.tr();
    } else if (errorLower.contains('unauthorized')) {
      return 'projectData.errors.unauthorized'.tr();
    } else if (errorLower.contains('conflict')) {
      return 'projectData.errors.conflict'.tr();
    } else if (errorLower.contains('network') ||
        errorLower.contains('timeout') ||
        errorLower.contains('connection')) {
      return 'projectData.errors.network'.tr();
    } else {
      return 'projectData.errors.unknown'.tr();
    }
  }
}
