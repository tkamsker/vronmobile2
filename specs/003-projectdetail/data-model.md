# Data Model: Project Detail and Data Management

**Date**: 2025-12-21
**Status**: Approved

## Overview

This document defines the data structures for the Project Detail and Data Management feature. The primary entity is the existing `Project` model, which will be extended with a `description` field. A new `ProjectEditForm` model encapsulates form state for editing operations.

---

## Entity Definitions

### 1. Project (Extended)

**Location**: `lib/features/home/models/project.dart` (existing file, to be updated)

**Purpose**: Represents a user's VRon project with all displayable and editable properties.

#### Fields

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| `id` | String | Yes | Unique project identifier | GraphQL API |
| `slug` | String | Yes | URL-safe project identifier | GraphQL API |
| `name` | String | Yes | User-facing project name | GraphQL API (I18NField) |
| `description` | String | No | **NEW**: Long-form project description | GraphQL API (I18NField) |
| `imageUrl` | String | Yes | Project thumbnail/preview image URL | GraphQL API |
| `isLive` | bool | Yes | Whether project is published/live | GraphQL API |
| `liveDate` | DateTime? | No | Date project went live | GraphQL API |
| `subscription` | ProjectSubscription | Yes | Subscription details | GraphQL API (nested object) |

#### Dart Implementation

```dart
class Project {
  final String id;
  final String slug;
  final String name;
  final String description;  // NEW FIELD
  final String imageUrl;
  final bool isLive;
  final DateTime? liveDate;
  final ProjectSubscription subscription;

  const Project({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,  // NEW PARAMETER
    required this.imageUrl,
    required this.isLive,
    this.liveDate,
    required this.subscription,
  });

  /// Create Project from JSON (from API response)
  factory Project.fromJson(Map<String, dynamic> json) {
    // Extract name from I18NField structure
    String projectName = '';
    if (json['name'] != null) {
      final nameField = json['name'];
      if (nameField is Map<String, dynamic> && nameField['text'] != null) {
        projectName = nameField['text'] as String;
      } else if (nameField is String) {
        projectName = nameField;
      }
    }

    // Extract description from I18NField structure (NEW)
    String projectDescription = '';
    if (json['description'] != null) {
      final descField = json['description'];
      if (descField is Map<String, dynamic> && descField['text'] != null) {
        projectDescription = descField['text'] as String;
      } else if (descField is String) {
        projectDescription = descField;
      }
    }

    return Project(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? '',
      name: projectName,
      description: projectDescription,  // NEW
      imageUrl: json['imageUrl'] as String? ?? '',
      isLive: json['isLive'] as bool? ?? false,
      liveDate: json['liveDate'] != null
          ? DateTime.parse(json['liveDate'] as String)
          : null,
      subscription: ProjectSubscription.fromJson(
        (json['subscription'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  /// Convert Project to JSON (for mutations)
  Map<String, dynamic> toUpdateInput() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
    };
  }

  /// Create a copy of this Project with some fields replaced
  Project copyWith({
    String? id,
    String? slug,
    String? name,
    String? description,  // NEW
    String? imageUrl,
    bool? isLive,
    DateTime? liveDate,
    ProjectSubscription? subscription,
  }) {
    return Project(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,  // NEW
      imageUrl: imageUrl ?? this.imageUrl,
      isLive: isLive ?? this.isLive,
      liveDate: liveDate ?? this.liveDate,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.slug == slug &&
        other.name == name &&
        other.description == description &&  // NEW
        other.imageUrl == imageUrl &&
        other.isLive == isLive &&
        other.liveDate == liveDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      slug,
      name,
      description,  // NEW
      imageUrl,
      isLive,
      liveDate,
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, slug: $slug, isLive: $isLive)';
  }

  // ... existing computed properties (statusLabel, statusColorHex, etc.) remain unchanged
}
```

#### Validation Rules

| Field | Min Length | Max Length | Format | Error Message |
|-------|------------|------------|--------|---------------|
| `name` | 1 | 100 | Any Unicode | "Project name is required" / "Project name must be 100 characters or less" |
| `slug` | 3 | 50 | Lowercase alphanumeric + hyphens, no leading/trailing hyphens | "Slug must be at least 3 characters" / "Slug can only contain lowercase letters, numbers, and hyphens" |
| `description` | 0 | 500 | Any Unicode | "Description must be 500 characters or less" |

#### State Transitions

```
View State (Read-Only)
  ↓ User taps "Project data" tab
Edit State (Form Enabled)
  ↓ User modifies fields → Dirty state tracked
Validation State (On blur / form submit)
  ↓ All validations pass
Saving State (API call in progress)
  ├→ Success → Update local model, show success message, return to clean state
  └→ Error → Show error message, preserve edits, re-enable form
```

#### Migration Notes

**Backward Compatibility**: The existing `Project` model is used throughout the app. Adding `description` field requires:

1. Update all `Project()` constructor calls to include `description` parameter (default to empty string for now)
2. Update tests that create mock Project instances
3. Update `copyWith` method to handle description
4. Update equality operator and hashCode

**Migration Strategy**:
- Existing projects without description will return empty string from API
- UI gracefully handles empty descriptions (shows "Optional" hint, no content if empty)
- No database migration needed (backend already supports description field)

---

### 2. ProjectEditForm (New)

**Location**: `lib/features/projects/models/project_edit_form.dart` (new file)

**Purpose**: Encapsulates form state separate from domain model, tracks dirty state, provides validation.

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | Current name input value |
| `slug` | String | Yes | Current slug input value |
| `description` | String | No | Current description input value |
| `isDirty` | bool | Yes | Whether any field has been modified |
| `nameError` | String? | No | Current validation error for name |
| `slugError` | String? | No | Current validation error for slug |
| `descriptionError` | String? | No | Current validation error for description |

#### Dart Implementation

```dart
class ProjectEditForm {
  final String name;
  final String slug;
  final String description;
  final bool isDirty;
  final String? nameError;
  final String? slugError;
  final String? descriptionError;

  const ProjectEditForm({
    required this.name,
    required this.slug,
    required this.description,
    this.isDirty = false,
    this.nameError,
    this.slugError,
    this.descriptionError,
  });

  /// Create form from existing Project
  factory ProjectEditForm.fromProject(Project project) {
    return ProjectEditForm(
      name: project.name,
      slug: project.slug,
      description: project.description,
      isDirty: false,
    );
  }

  /// Check if form is valid (no errors and required fields present)
  bool get isValid {
    return nameError == null &&
        slugError == null &&
        descriptionError == null &&
        name.isNotEmpty &&
        slug.isNotEmpty;
  }

  /// Create a copy with updated fields
  ProjectEditForm copyWith({
    String? name,
    String? slug,
    String? description,
    bool? isDirty,
    String? nameError,
    String? slugError,
    String? descriptionError,
  }) {
    return ProjectEditForm(
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      isDirty: isDirty ?? this.isDirty,
      nameError: nameError ?? this.nameError,
      slugError: slugError ?? this.slugError,
      descriptionError: descriptionError ?? this.descriptionError,
    );
  }

  /// Convert form to UpdateProjectInput for mutation
  Map<String, dynamic> toUpdateInput() {
    return {
      'name': name.trim(),
      'slug': slug.trim().toLowerCase(),
      'description': description.trim(),
    };
  }

  @override
  String toString() {
    return 'ProjectEditForm(name: $name, slug: $slug, isDirty: $isDirty, isValid: $isValid)';
  }
}
```

#### Usage Pattern

```dart
class _ProjectDataTabState extends State<ProjectDataTab> {
  late ProjectEditForm _formState;
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _formState = ProjectEditForm.fromProject(widget.project);
    _nameController = TextEditingController(text: _formState.name);
    _slugController = TextEditingController(text: _formState.slug);
    _descriptionController = TextEditingController(text: _formState.description);
  }

  void _onNameChanged(String value) {
    setState(() {
      _formState = _formState.copyWith(
        name: value,
        isDirty: true,
        nameError: _validateName(value),
      );
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Project name is required';
    }
    if (value.length > 100) {
      return 'Project name must be 100 characters or less';
    }
    return null;
  }

  // ... similar for slug and description
}
```

---

## Relationships

```
User (implicit, via auth token)
  ↓ owns
Project
  ↓ has
ProjectSubscription (existing model, unchanged)

ProjectEditForm
  ↓ derives from
Project
  ↓ converts to
UpdateProjectInput (GraphQL mutation input)
```

---

## GraphQL Schema Mapping

### Query: getProjectDetail

**GraphQL Response Structure**:
```json
{
  "project": {
    "id": "proj_abc123",
    "slug": "marketing-analytics",
    "name": {
      "text": "Marketing Analytics"
    },
    "description": {
      "text": "Realtime overview of campaign performance across channels."
    },
    "imageUrl": "https://cdn.vron.com/projects/proj_abc123/thumb.jpg",
    "isLive": true,
    "liveDate": "2024-11-15T10:30:00Z",
    "subscription": {
      "isActive": true,
      "isTrial": false,
      "status": "ACTIVE",
      "canChoosePlan": false,
      "hasExpired": false,
      "currency": "EUR",
      "price": 29.99,
      "renewalInterval": "MONTHLY",
      "startedAt": "2024-11-01T00:00:00Z",
      "expiresAt": null,
      "renewsAt": "2024-12-01T00:00:00Z",
      "prices": {
        "currency": "EUR",
        "monthly": 29.99,
        "yearly": 299.99
      }
    }
  }
}
```

**Dart Model Mapping**:
- `project.id` → `Project.id`
- `project.slug` → `Project.slug`
- `project.name.text` → `Project.name`
- `project.description.text` → `Project.description` (NEW)
- `project.imageUrl` → `Project.imageUrl`
- `project.isLive` → `Project.isLive`
- `project.liveDate` → `Project.liveDate` (parsed to DateTime)
- `project.subscription` → `Project.subscription` (ProjectSubscription model)

### Mutation: updateProject

**GraphQL Input Structure**:
```json
{
  "id": "proj_abc123",
  "data": {
    "name": "Marketing Analytics Platform",
    "slug": "marketing-analytics-platform",
    "description": "Comprehensive analytics dashboard."
  }
}
```

**Dart Model Mapping**:
- `ProjectEditForm.name` → `UpdateProjectInput.name`
- `ProjectEditForm.slug` → `UpdateProjectInput.slug` (lowercase, trimmed)
- `ProjectEditForm.description` → `UpdateProjectInput.description` (trimmed)

---

## Testing Considerations

### Unit Tests

**Project Model Tests** (`test/features/home/models/project_test.dart`):
1. Test `fromJson` with description field present
2. Test `fromJson` with description field missing (should default to empty string)
3. Test `copyWith` includes description parameter
4. Test equality operator includes description
5. Test `toUpdateInput` includes description

**ProjectEditForm Tests** (`test/features/projects/models/project_edit_form_test.dart`):
1. Test `fromProject` creates form with correct initial values
2. Test `isValid` returns true when all fields valid
3. Test `isValid` returns false when required fields empty or errors present
4. Test `copyWith` updates individual fields
5. Test `toUpdateInput` formats fields correctly (trimmed, lowercase slug)
6. Test validation error states

### Integration Tests

**Full Edit Journey** (`test/integration/project_edit_journey_test.dart`):
1. Navigate to project detail screen
2. Switch to Project data tab
3. Modify name, slug, description
4. Verify form shows dirty state
5. Submit form
6. Verify success message
7. Verify UI reflects updated values
8. Verify form returns to clean state

---

## Summary

This data model extends the existing `Project` entity with a `description` field and introduces `ProjectEditForm` for form state management. Both models follow Flutter/Dart best practices with immutable data structures, factory constructors, and clear validation boundaries. The design maintains backward compatibility with existing code while enabling the new edit functionality.

**Key Design Decisions**:
- Minimal changes to existing Project model (add one field)
- Separate form state from domain model (ProjectEditForm)
- Validation logic centralized in utility class (covered in contracts section)
- Immutable data structures with copyWith pattern
- Clear separation between display model (Project) and edit model (ProjectEditForm)
