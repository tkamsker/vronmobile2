import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Project data edit form tab
/// Allows editing project name and description (slug is read-only)
class ProjectDataTab extends StatefulWidget {
  final Project project;
  final void Function(String name, String description)? onSave;

  const ProjectDataTab({
    super.key,
    required this.project,
    this.onSave,
  });

  @override
  State<ProjectDataTab> createState() => _ProjectDataTabState();
}

class _ProjectDataTabState extends State<ProjectDataTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _slugController;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    _slugController = TextEditingController(text: widget.project.slug);

    // Track changes to mark form as dirty
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final isDirty = _nameController.text != widget.project.name ||
        _descriptionController.text != widget.project.description;

    if (isDirty != _isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _handlePopInvoked(bool didPop) async {
    // If already popped or no unsaved changes, do nothing
    if (didPop || !_isDirty) return;

    // Show warning dialog for unsaved changes
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );

    if (shouldPop == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.onSave != null) {
        widget.onSave!(
          _nameController.text,
          _descriptionController.text,
        );
      }

      setState(() {
        _isDirty = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field (editable)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter project name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field (editable)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter project description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  // Description is optional, no validation needed
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Slug field (read-only)
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'project-slug',
                  border: OutlineInputBorder(),
                  helperText: 'Read-only: Editing slug is not supported yet',
                ),
                enabled: false,
              ),
              const SizedBox(height: 24),

              // Save button
              Semantics(
                button: true,
                label: _isSaving ? 'Saving project changes' : 'Save project changes',
                hint: _isSaving ? 'Please wait...' : 'Double tap to save',
                enabled: !_isSaving,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
