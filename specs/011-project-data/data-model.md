# Data Model: Project Data Edit Screen

**Feature**: 011-project-data
**Date**: 2025-12-21
**Status**: Phase 1 Complete

## Overview

This document defines the data structures for the project data edit screen. The feature primarily reuses the existing Project model and adds form-specific state management.

## Entities

### Project (Existing - Reused)

**Location**: `lib/features/home/models/project.dart`
**Status**: Already exists, no modifications needed

**Relevant Fields**:
```dart
class Project {
  final String id;
  final String slug;
  final String name;           // Used for form initial value
  final String description;    // Used for form initial value
  final String? imageUrl;
  // ... other fields not used in this feature
}
```

**Usage in Feature**:
- Read `name` and `description` for initial form values
- Receive updated Project after successful mutation

---

### ProjectDataScreenState (New - Form State)

**Location**: `lib/features/project_data/screens/project_data_screen.dart`
**Status**: New - to be implemented

**State Variables**:
```dart
class _ProjectDataScreenState extends State<ProjectDataScreen> {
  // Form Management
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  // UI State
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Services
  final ProjectService _projectService = ProjectService();
}
```

**State Lifecycle**:
1. **initState()**: Initialize controllers with initial project data
2. **Form editing**: Update _hasUnsavedChanges on text change
3. **Validation**: Triggered on save button tap
4. **Mutation**: Set _isLoading = true, call service, handle result
5. **dispose()**: Clean up controllers

---

### ProjectUpdateInput (GraphQL Input Type)

**Location**: GraphQL API schema (server-side)
**Status**: Existing API contract

**Structure** (as expected by API):
```graphql
input ProjectUpdateInput {
  name: String
  description: String
  # Additional fields as per API schema
}
```

**Dart Representation** (when calling mutation):
```dart
final input = {
  'name': _nameController.text.trim(),
  'description': _descriptionController.text.trim(),
};

await _projectService.updateProject(widget.projectId, input);
```

---

## Validation Rules

### Name Field

**Rules**:
- ✅ Required (non-empty after trim)
- ✅ Minimum length: 3 characters
- ✅ Maximum length: 100 characters (client-side, server may enforce different limit)

**Validator**:
```dart
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
```

### Description Field

**Rules**:
- ✅ Optional (can be empty)
- ✅ Maximum length: 500 characters (client-side)

**Validator**:
```dart
String? _validateDescription(String? value) {
  if (value != null && value.trim().length > 500) {
    return 'projectData.validation.descriptionTooLong'.tr();
  }
  return null;
}
```

---

## Navigation Arguments

### ProjectDataScreen Arguments

**Passed via Navigator**:
```dart
Navigator.pushNamed(
  context,
  AppRoutes.projectData,
  arguments: {
    'projectId': 'proj_123',
    'initialName': 'Marketing Analytics',
    'initialDescription': 'Track marketing performance...',
  },
);
```

**Extracted in ProjectDataScreen**:
```dart
class ProjectDataScreen extends StatefulWidget {
  final String projectId;
  final String initialName;
  final String initialDescription;

  const ProjectDataScreen({
    required this.projectId,
    required this.initialName,
    required this.initialDescription,
    super.key,
  });

  @override
  State<ProjectDataScreen> createState() => _ProjectDataScreenState();
}
```

---

## Service Layer Data Flow

### ProjectService.updateProject

**Method Signature**:
```dart
Future<Project> updateProject(
  String projectId,
  Map<String, dynamic> input,
) async
```

**Input**:
- `projectId`: String - The project ID to update
- `input`: Map - The fields to update (name, description)

**Output**:
- `Project`: The updated project with all fields
- Throws `Exception` on error

**Data Transformation**:
```dart
// Screen → Service
final input = {
  'name': _nameController.text.trim(),
  'description': _descriptionController.text.trim(),
};

// Service → GraphQL API
{
  "id": "proj_123",
  "input": {
    "name": "Updated Name",
    "description": "Updated description"
  }
}

// GraphQL API → Service
{
  "data": {
    "updateProject": {
      "id": "proj_123",
      "slug": "marketing-analytics",
      "name": { "text": "Updated Name" },
      "description": { "text": "Updated description" }
    }
  }
}

// Service → Screen
Project(
  id: "proj_123",
  slug: "marketing-analytics",
  name: "Updated Name",
  description: "Updated description",
  ...
)
```

---

## Error Response Models

### GraphQL Error Response

**Structure**:
```dart
{
  "errors": [
    {
      "message": "Project not found",
      "extensions": {
        "code": "NOT_FOUND"
      }
    }
  ]
}
```

**Error Types to Handle**:
1. **NOT_FOUND**: Project doesn't exist → Navigate back + show error
2. **UNAUTHORIZED**: User not authorized → Navigate to login
3. **VALIDATION_ERROR**: Invalid input → Show field-specific errors
4. **CONFLICT**: Concurrent update → Show conflict dialog
5. **NETWORK_ERROR**: Connection issues → Show retry option

---

## State Transitions

### Form State Machine

```
┌─────────────┐
│   Initial   │ ← Screen loads with initial data
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Editing   │ ← User types in form fields
└──────┬──────┘   (_hasUnsavedChanges = true)
       │
       ▼
┌─────────────┐
│ Validating  │ ← User taps Save button
└──────┬──────┘   (form.validate())
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌─────────────┐  ┌─────────────┐
│   Invalid   │  │   Saving    │ ← _isLoading = true
└──────┬──────┘  └──────┬──────┘   (call mutation)
       │                │
       │                ├─────────────┐
       │                │             │
       │                ▼             ▼
       │         ┌─────────────┐  ┌─────────────┐
       │         │   Success   │  │    Error    │
       │         └──────┬──────┘  └──────┬──────┘
       │                │                │
       │                ▼                │
       │         ┌─────────────┐         │
       │         │  Navigate   │         │
       │         │    Back     │         │
       │         └─────────────┘         │
       │                                 │
       └─────────────────────────────────┘
                       │
                       ▼
                ┌─────────────┐
                │   Editing   │ ← User can fix errors
                └─────────────┘
```

---

## i18n Translation Keys

### Required Keys in Translation Files

**en.json, de.json, pt.json**:
```json
{
  "projectData": {
    "title": "Edit Project",
    "subtitle": "Update project information",
    "nameLabel": "Project Name",
    "namePlaceholder": "Enter project name",
    "descriptionLabel": "Description",
    "descriptionPlaceholder": "Enter project description (optional)",
    "saveButton": "Save Changes",
    "cancelButton": "Cancel",
    "unsavedChangesTitle": "Unsaved Changes",
    "unsavedChangesMessage": "You have unsaved changes. Are you sure you want to leave?",
    "discardButton": "Discard",
    "keepEditingButton": "Keep Editing",
    "saveSuccess": "Project updated successfully",
    "validation": {
      "nameRequired": "Project name is required",
      "nameTooShort": "Project name must be at least 3 characters",
      "nameTooLong": "Project name must be less than 100 characters",
      "descriptionTooLong": "Description must be less than 500 characters"
    },
    "errors": {
      "notFound": "Project not found",
      "unauthorized": "You don't have permission to edit this project",
      "conflict": "This project was updated by another user. Please refresh and try again.",
      "network": "Connection error. Please check your internet connection.",
      "unknown": "An error occurred. Please try again."
    }
  }
}
```

---

## Relationships

```
┌─────────────────────────┐
│  ProjectDetailScreen    │
│  (010-project-detail)   │
└───────────┬─────────────┘
            │ Navigate (push)
            │ Pass: projectId, name, description
            ▼
┌─────────────────────────┐
│   ProjectDataScreen     │
│   (011-project-data)    │
└───────────┬─────────────┘
            │ Uses
            ▼
┌─────────────────────────┐
│    ProjectService       │
│    updateProject()      │
└───────────┬─────────────┘
            │ Mutates
            ▼
┌─────────────────────────┐
│   GraphQL API           │
│   updateProject         │
└───────────┬─────────────┘
            │ Returns
            ▼
┌─────────────────────────┐
│   Updated Project       │
└─────────────────────────┘
```

---

## Summary

**Existing Models**:
- ✅ Project model (reused, no changes)

**New State**:
- Form state with TextEditingControllers
- Validation state
- Loading/error states

**No Database Changes**:
- All data persisted via GraphQL API
- No local storage required

**Validation**:
- Client-side validation for UX
- Server-side validation assumed (enforced by API)
