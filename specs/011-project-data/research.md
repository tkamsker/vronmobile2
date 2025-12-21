# Research: Project Data Edit Screen

**Feature**: 011-project-data
**Date**: 2025-12-21
**Status**: Phase 0 Complete

## Overview

This document records research findings and technical decisions for implementing the project data edit screen feature.

## Research Findings

### 1. Flutter Form Validation Pattern

**Decision**: Use Flutter's built-in Form widget with TextFormField validators

**Rationale**:
- Already used throughout the codebase (consistent with existing patterns)
- Provides automatic validation state management
- GlobalKey<FormState> pattern for form-level validation
- Built-in error display with customizable styling
- No additional dependencies required

**Implementation Pattern**:
```dart
class _ProjectDataScreenState extends State<ProjectDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'projectData.validation.nameRequired'.tr();
    }
    if (value.trim().length < 3) {
      return 'projectData.validation.nameTooShort'.tr();
    }
    return null;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Proceed with mutation
    }
  }
}
```

**Alternatives Considered**:
- form_validator package - rejected (unnecessary dependency)
- Custom validation framework - rejected (over-engineering)

**References**:
- Flutter Form widget: https://api.flutter.dev/flutter/widgets/Form-class.html
- Existing pattern used in authentication screens (if any)

---

### 2. GraphQL Mutation Approach

**Decision**: Extend existing ProjectService with updateProject method

**Rationale**:
- Consistent with existing architecture (ProjectService already has getProjects)
- Centralizes GraphQL operations in service layer
- Reuses existing GraphQL client configuration
- Follows single responsibility principle

**Implementation Pattern**:
```dart
// lib/features/home/services/project_service.dart
class ProjectService {
  // ... existing getProjects method ...

  Future<Project> updateProject(String projectId, Map<String, dynamic> input) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql('''
          mutation UpdateProject(\$id: ID!, \$input: ProjectUpdateInput!) {
            updateProject(id: \$id, input: \$input) {
              id
              slug
              name { text(lang: EN) }
              description { text(lang: EN) }
            }
          }
        '''),
        variables: {
          'id': projectId,
          'input': input,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Project.fromJson(result.data!['updateProject']);
  }
}
```

**Alternatives Considered**:
- Separate ProjectUpdateService - rejected (unnecessary fragmentation)
- Direct mutation in screen widget - rejected (violates separation of concerns)

**References**:
- Existing ProjectService: lib/features/home/services/project_service.dart
- GraphQL mutation docs: https://github.com/zino-hofmann/graphql-flutter

---

### 3. Error Handling for Save Operations

**Decision**: Three-tier error handling strategy

**Rationale**:
- Client validation prevents invalid data submission
- Network errors need user-friendly messages
- Server errors need to be displayed with context

**Implementation Strategy**:

**Tier 1 - Client Validation** (before mutation):
- Required field validation
- Length constraints
- Format validation
- Display inline errors under form fields

**Tier 2 - Network Errors** (GraphQL client errors):
- Timeout errors → "Connection timeout. Please try again."
- Network unavailable → "No internet connection. Please check your network."
- Display in SnackBar with retry option

**Tier 3 - Server Errors** (GraphQL mutation errors):
- "Project not found" → Navigate back + show error
- "Unauthorized" → Navigate to login
- "Validation error" → Display specific field errors
- "Conflict" → Show conflict resolution dialog
- Display in Dialog for critical errors, SnackBar for recoverable errors

**Error Display Pattern**:
```dart
try {
  await _projectService.updateProject(widget.projectId, input);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('projectData.saveSuccess'.tr())),
    );
    Navigator.pop(context, true); // Return updated=true
  }
} catch (e) {
  if (mounted) {
    final errorMessage = _parseErrorMessage(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'common.retry'.tr(),
          onPressed: _saveChanges,
        ),
      ),
    );
  }
}
```

**Alternatives Considered**:
- Global error handler - rejected (loses context-specific handling)
- Toast messages - rejected (not Flutter-native pattern)

---

### 4. Navigation and Data Flow

**Decision**: Modal navigation with result return

**Rationale**:
- Project detail screen needs to know if data was updated
- Follows Flutter's standard dialog/modal pattern
- Allows detail screen to refresh data after edit

**Implementation Pattern**:

From ProjectDetailScreen:
```dart
final wasUpdated = await Navigator.pushNamed(
  context,
  AppRoutes.projectData,
  arguments: {'projectId': widget.projectId},
);

if (wasUpdated == true) {
  // Refresh project detail data
  setState(() {
    _projectFuture = _projectService.fetchProjectDetail(widget.projectId);
  });
}
```

From ProjectDataScreen:
```dart
// On successful save:
Navigator.pop(context, true); // Return true

// On cancel or back:
Navigator.pop(context, false); // Return false
```

**Alternatives Considered**:
- State management (Provider/Riverpod) - rejected (over-engineering for single feature)
- Event bus - rejected (adds complexity, harder to debug)

**References**:
- Flutter navigation with results: https://docs.flutter.dev/cookbook/navigation/returning-data

---

### 5. Form Field State Management

**Decision**: TextEditingController for each field + dispose pattern

**Rationale**:
- Standard Flutter pattern for text input
- Required for form validation
- Allows programmatic text updates
- Proper cleanup with dispose()

**Implementation Pattern**:
```dart
class _ProjectDataScreenState extends State<ProjectDataScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
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
}
```

**Alternatives Considered**:
- StatelessWidget with callbacks - rejected (doesn't support form state)
- Form state in separate class - rejected (unnecessary complexity)

---

## Technical Constraints

1. **Existing Integration Points**:
   - Must navigate from ProjectDetailScreen
   - Must use existing ProjectService pattern
   - Must follow existing i18n patterns with .tr()

2. **Design Requirements**:
   - Must match Requirements/ProjectDetailData.jpg layout
   - Form fields with labels and validation errors
   - Save/Cancel buttons
   - Loading state during mutation

3. **Performance Requirements**:
   - Form field updates must be immediate (< 16ms for 60fps)
   - Save operation should complete in < 2 seconds
   - Validation feedback immediate (< 100ms)

## Dependencies

**No new dependencies required**:
- ✅ graphql_flutter - already in use for queries, supports mutations
- ✅ flutter (SDK) - Form, TextFormField built-in
- ✅ i18n_service - already implemented

## Testing Strategy

1. **Widget Tests** (TDD - write first):
   - Test form validation (empty fields, too short, valid input)
   - Test save button enabled/disabled state
   - Test loading state display
   - Test error message display

2. **Unit Tests** (TDD - write first):
   - Test ProjectService.updateProject method
   - Test error parsing logic

3. **Integration Tests**:
   - Test full save flow (form → validation → mutation → navigation)
   - Test error scenarios (network error, server error)

## Conclusion

All technical decisions follow existing patterns in the codebase and require no new dependencies. The implementation will:
- Use Flutter's built-in Form widget for validation
- Extend ProjectService with updateProject mutation
- Implement three-tier error handling
- Use modal navigation with result return
- Follow TextEditingController pattern for form state
