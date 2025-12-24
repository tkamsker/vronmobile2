# Data Model: Complete Project Management Features

**Feature**: 008-view-projects
**Date**: 2025-12-24
**Prerequisites**: research.md ✅

## Overview

This document defines the data structures, enums, and validation rules for the complete project management feature. These models extend the existing Project entity and introduce new types for sorting and creation.

---

## 1. ProjectSortOption (New Enum)

### Purpose

Defines available sort options for the project list. Used to specify how projects should be ordered in the UI.

### Definition

```dart
/// Sort options for project list
///
/// Used by ProjectService.fetchProjects() to determine list ordering
enum ProjectSortOption {
  /// Sort by name A-Z (case-insensitive)
  nameAscending,

  /// Sort by name Z-A (case-insensitive)
  nameDescending,

  /// Sort by updated date, newest first
  dateNewest,

  /// Sort by updated date, oldest first
  dateOldest,

  /// Sort by status priority (Live > Trial > Inactive > Not Live),
  /// with secondary sort by name A-Z
  status,
}
```

### Display Names

```dart
extension ProjectSortOptionExtension on ProjectSortOption {
  /// Human-readable label for UI display
  String get label {
    switch (this) {
      case ProjectSortOption.nameAscending:
        return 'Name (A-Z)';
      case ProjectSortOption.nameDescending:
        return 'Name (Z-A)';
      case ProjectSortOption.dateNewest:
        return 'Date (Newest)';
      case ProjectSortOption.dateOldest:
        return 'Date (Oldest)';
      case ProjectSortOption.status:
        return 'Status';
    }
  }

  /// Icon for UI display (optional)
  IconData get icon {
    switch (this) {
      case ProjectSortOption.nameAscending:
        return Icons.arrow_upward;
      case ProjectSortOption.nameDescending:
        return Icons.arrow_downward;
      case ProjectSortOption.dateNewest:
        return Icons.date_range;
      case ProjectSortOption.dateOldest:
        return Icons.history;
      case ProjectSortOption.status:
        return Icons.label;
    }
  }
}
```

### Usage

```dart
// In HomeScreen
ProjectSortOption _currentSort = ProjectSortOption.dateNewest;

// In sort menu selection
void _handleSortSelection(ProjectSortOption? newSort) {
  if (newSort != null) {
    setState(() {
      _currentSort = newSort;
    });
    _refreshProjects();
  }
}

// In ProjectService
Future<List<Project>> fetchProjects({ProjectSortOption? sortBy}) async {
  final projects = await _fetchFromAPI();
  if (sortBy != null) {
    _sortProjects(projects, sortBy);
  }
  return projects;
}
```

### Storage

**Session-only**: Sort preference stored in memory (State variable), not persisted across app restarts.

**Alternative** (if persistence needed later):
```dart
// Store in shared_preferences
await prefs.setString('project_sort', sortBy.name);

// Retrieve
final sortName = prefs.getString('project_sort');
final sortBy = ProjectSortOption.values.firstWhere(
  (e) => e.name == sortName,
  orElse: () => ProjectSortOption.dateNewest,
);
```

---

## 2. CreateProjectInput (New Class)

### Purpose

Input model for creating a new project via GraphQL createProject mutation. Maps to backend CreateProjectInput type.

### Definition

```dart
/// Input data for creating a new project
///
/// Maps to GraphQL CreateProjectInput type
class CreateProjectInput {
  /// Project name (required, 3-100 characters)
  final String name;

  /// URL-friendly slug (required, must be unique)
  final String slug;

  /// Project description (optional)
  final String? description;

  const CreateProjectInput({
    required this.name,
    required this.slug,
    this.description,
  });

  /// Convert to GraphQL mutation variables
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }

  /// Create from form data
  factory CreateProjectInput.fromForm({
    required String name,
    required String slug,
    String? description,
  }) {
    return CreateProjectInput(
      name: name.trim(),
      slug: slug.trim().toLowerCase(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
    );
  }
}
```

### Validation Rules

#### Field: `name`

| Rule | Constraint | Error Message |
|------|------------|---------------|
| **Required** | Not null, not empty after trim | "Name is required" |
| **Min length** | >= 3 characters | "Name must be at least 3 characters" |
| **Max length** | <= 100 characters | "Name must be 100 characters or less" |
| **Format** | Any printable characters | N/A |

#### Field: `slug`

| Rule | Constraint | Error Message |
|------|------------|---------------|
| **Required** | Not null, not empty after trim | "Slug is required" |
| **Format** | Regex: `^[a-z0-9]+(-[a-z0-9]+)*$` | "Slug must contain only lowercase letters, numbers, and hyphens" |
| **Uniqueness** | Unique across all projects (backend) | "A project with this slug already exists" |
| **No leading hyphens** | Cannot start with `-` | "Slug cannot start with a hyphen" |
| **No trailing hyphens** | Cannot end with `-` | "Slug cannot end with a hyphen" |
| **No consecutive hyphens** | No `--` sequences | "Slug cannot contain consecutive hyphens" |

#### Field: `description`

| Rule | Constraint | Error Message |
|------|------------|---------------|
| **Optional** | Can be null or empty | N/A |
| **Max length** | No explicit limit (reasonable text assumed) | N/A |
| **Format** | Any printable characters | N/A |

### Usage Example

```dart
// In CreateProjectScreen
Future<void> _handleSave() async {
  if (!_formKey.currentState!.validate()) return;

  final input = CreateProjectInput.fromForm(
    name: _nameController.text,
    slug: _slugController.text,
    description: _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text,
  );

  try {
    final project = await _projectService.createProject(input);
    // Navigate back with success
  } catch (e) {
    // Show error
  }
}
```

---

## 3. Project Entity (Existing - No Changes)

### Current Definition

```dart
class Project {
  final String id;
  final String slug;
  final String name;
  final String description;
  final String? imageUrl;
  final ProjectStatus status;
  final ProjectSubscription subscription;
  final DateTime updatedAt;
  final DateTime? createdAt; // Used for date sorting

  // ... existing implementation
}
```

### Fields Used by This Feature

| Field | Used For | Notes |
|-------|----------|-------|
| `id` | Unique identifier | Generated by backend |
| `slug` | URL routing, uniqueness validation | Auto-generated from name in create form |
| `name` | Display, sorting (A-Z/Z-A) | Primary project identifier |
| `description` | Display in detail view | Optional in create form |
| `imageUrl` | Display (optional) | Not set during creation (default null) |
| `status` | Sorting by status priority | Computed from subscription fields |
| `subscription` | Status computation | Backend default values |
| `updatedAt` | Sorting by date | Set by backend on creation |
| `createdAt` | Sorting by date (if available) | Set by backend on creation |

### No Modifications Needed

The existing Project model has all fields required for this feature. No schema changes or migrations needed.

---

## 4. Validation Rules Summary

### Client-Side Validation (Flutter)

**Timing**: Submit-time validation via `Form.validate()`

**Location**: TextFormField validators in CreateProjectScreen

**Rules**:
```dart
// Name field
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Name is required';
  }
  if (value.trim().length < 3) {
    return 'Name must be at least 3 characters';
  }
  if (value.trim().length > 100) {
    return 'Name must be 100 characters or less';
  }
  return null;
}

// Slug field
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Slug is required';
  }
  if (!SlugGenerator.isValidSlug(value.trim())) {
    return 'Slug must contain only lowercase letters, numbers, and hyphens';
  }
  return null;
}

// Description field
validator: (value) {
  // Optional field, no validation
  return null;
}
```

### Backend Validation (GraphQL)

**Timing**: On mutation execution before database write

**Rules**:
- Name: Required, 3-100 chars (trimmed)
- Slug: Required, unique, format validation
- Description: Optional, any text

**Error codes**:
- `VALIDATION_ERROR`: Field validation failure
- `DUPLICATE_SLUG`: Slug already exists in database

---

## 5. State Management

### Sort Preference State

**Storage**: In-memory (StatefulWidget state or Provider)

**Scope**: Session-only (lost on app restart)

**Location**: HomeScreen state

```dart
class _HomeScreenState extends State<HomeScreen> {
  ProjectSortOption _currentSort = ProjectSortOption.dateNewest; // Default

  void _handleSortChange(ProjectSortOption newSort) {
    setState(() {
      _currentSort = newSort;
    });
    _refreshProjects();
  }
}
```

### Form State

**Storage**: TextEditingController + Form dirty state

**Scope**: Screen lifecycle (lost on navigation)

**Location**: CreateProjectScreen state

```dart
class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  bool _isDirty = false;
  bool _isLoading = false;

  // Controllers manage form state
}
```

---

## 6. Data Flow

### Create Project Flow

```
User Input (CreateProjectScreen)
   ↓
TextEditingControllers
   ↓
Form Validation
   ↓
CreateProjectInput.fromForm()
   ↓
ProjectService.createProject(input)
   ↓
GraphQLService.mutate(createProjectMutation, variables)
   ↓
Backend validates & creates Project
   ↓
Project.fromJson(response)
   ↓
Navigate back to HomeScreen
   ↓
HomeScreen refreshes list
   ↓
New project appears at top (sorted by date)
```

### Sort Projects Flow

```
User taps sort button (HomeScreen)
   ↓
SortMenu displays options
   ↓
User selects ProjectSortOption
   ↓
HomeScreen updates _currentSort state
   ↓
ProjectService.fetchProjects(sortBy: _currentSort)
   ↓
Service fetches list from cache/API
   ↓
Service applies sort via List.sort()
   ↓
Sorted list returned
   ↓
UI rebuilds with sorted list
```

---

## 7. Error Handling

### Client-Side Errors

| Error Type | Handling | User Feedback |
|------------|----------|---------------|
| **Validation failure** | Form returns false, validators show inline errors | Red text below fields |
| **Empty required field** | Validator returns error string | "Name is required" |
| **Invalid slug format** | Validator returns error string | "Slug must contain only..." |

### Backend Errors

| Error Type | Handling | User Feedback |
|------------|----------|---------------|
| **Duplicate slug** | Catch GraphQL error with code DUPLICATE_SLUG | SnackBar: "A project with this slug already exists" |
| **Network failure** | Catch exception | SnackBar: "Network error. Please try again." |
| **GraphQL error** | Catch exception | SnackBar: "Error creating project: {message}" |

### Recovery Actions

- **Validation errors**: User corrects form, retries save
- **Duplicate slug**: User modifies slug, retries save
- **Network errors**: User retries save when online
- **Unknown errors**: User contacts support if persistent

---

## 8. Performance Considerations

### Sort Performance

| Operation | Items | Expected Time | Target |
|-----------|-------|---------------|--------|
| **Name sort** | 100 | <5ms | <500ms ✅ |
| **Name sort** | 1000 | 10-50ms | <500ms ✅ |
| **Date sort** | 100 | <5ms | <500ms ✅ |
| **Date sort** | 1000 | 10-50ms | <500ms ✅ |
| **Status sort** | 100 | <10ms | <500ms ✅ |
| **Status sort** | 1000 | 20-60ms | <500ms ✅ |

### Slug Generation Performance

| Operation | Input Size | Expected Time | Target |
|-----------|------------|---------------|--------|
| **Generate slug** | 50 chars | <5ms | <100ms ✅ |
| **Generate slug** | 500 chars | <10ms | <100ms ✅ |
| **Validate slug** | Any | <1ms | <100ms ✅ |

### Form Validation Performance

| Operation | Expected Time | Target |
|-----------|---------------|--------|
| **Validate all fields** | <5ms | <100ms ✅ |
| **Auto-generate slug** | <5ms | <100ms ✅ |
| **Display inline error** | <16ms (1 frame) | <100ms ✅ |

---

## Summary

| Entity | Type | Purpose | Status |
|--------|------|---------|--------|
| **ProjectSortOption** | Enum | Define sort options | ✅ Ready for implementation |
| **CreateProjectInput** | Class | Input for createProject mutation | ✅ Ready for implementation |
| **Project** | Existing | No changes needed | ✅ Already implemented |

**Validation**: All rules defined and ready for implementation
**Performance**: All targets easily met with proposed approach
**State Management**: Clear patterns established

**Next**: Create GraphQL contracts and integration guide
