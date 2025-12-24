# Slug Validation Rules

**Feature**: 008-view-projects
**Date**: 2025-12-24

## Overview

This document defines the validation rules for project slugs, both client-side (Flutter) and server-side (GraphQL backend). Slugs are URL-friendly identifiers that must be unique across all projects.

---

## Valid Slug Format

### Regular Expression

```regex
^[a-z0-9]+(-[a-z0-9]+)*$
```

### Rules

1. **Lowercase only**: No uppercase letters allowed
2. **Alphanumeric**: Only letters (a-z) and numbers (0-9)
3. **Hyphens as separators**: Hyphens (-) allowed between alphanumeric segments
4. **No leading hyphens**: Cannot start with a hyphen
5. **No trailing hyphens**: Cannot end with a hyphen
6. **No consecutive hyphens**: Cannot contain `--` or more consecutive hyphens
7. **At least one character**: Cannot be empty string

### Valid Examples

✅ `my-project`
✅ `project-123`
✅ `test`
✅ `a-b-c-d-e`
✅ `project-2024`
✅ `my-room-scan`

### Invalid Examples

❌ `My-Project` (uppercase letters)
❌ `my_project` (underscores not allowed)
❌ `my project` (spaces not allowed)
❌ `-my-project` (leading hyphen)
❌ `my-project-` (trailing hyphen)
❌ `my--project` (consecutive hyphens)
❌ `my@project` (special characters)
❌ `café` (accented characters)
❌ `` (empty string)

---

## Client-Side Validation (Flutter)

### Location

`lib/core/utils/slug_generator.dart`

### Validator Function

```dart
class SlugGenerator {
  static final RegExp _validSlugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  /// Validates if a string is a valid slug
  ///
  /// Returns true if the slug matches the required format:
  /// - Lowercase alphanumeric characters and hyphens only
  /// - No leading or trailing hyphens
  /// - No consecutive hyphens
  ///
  /// Example:
  /// ```dart
  /// SlugGenerator.isValidSlug('my-project'); // true
  /// SlugGenerator.isValidSlug('My-Project'); // false
  /// SlugGenerator.isValidSlug('my--project'); // false
  /// ```
  static bool isValidSlug(String slug) {
    if (slug.isEmpty) return false;
    return _validSlugPattern.hasMatch(slug);
  }
}
```

### Usage in Form Validation

```dart
// In CreateProjectScreen
TextFormField(
  controller: _slugController,
  decoration: const InputDecoration(
    labelText: 'Slug',
    hintText: 'my-project',
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Slug is required';
    }
    if (!SlugGenerator.isValidSlug(value.trim())) {
      return 'Slug must contain only lowercase letters, numbers, and hyphens';
    }
    return null;
  },
)
```

### Validation Timing

**Submit-time validation**: Slug is validated only when user attempts to save the form.

**Why not real-time?**
- Allows user to see auto-generated slug without immediate errors
- Slug can be manually edited before submission
- Validation error only appears if invalid slug is submitted

---

## Server-Side Validation (GraphQL Backend)

### Input Type

```graphql
input CreateProjectInput {
  name: String!      # Required: 3-100 characters
  slug: String!      # Required: Valid slug format, must be unique
  description: String
}
```

### Validation Steps

1. **Required check**: Slug must not be null or empty
2. **Format check**: Slug must match regex `^[a-z0-9]+(-[a-z0-9]+)*$`
3. **Uniqueness check**: Slug must not exist in database (case-insensitive)
4. **Length check** (implicit): Reasonable slug length (no explicit limit, but typically <200 chars)

### Error Codes

#### VALIDATION_ERROR

**When**: Slug fails format validation (regex mismatch)

**HTTP Status**: 400 Bad Request

**Response**:
```json
{
  "errors": [
    {
      "message": "Slug must contain only lowercase letters, numbers, and hyphens",
      "extensions": {
        "code": "VALIDATION_ERROR",
        "field": "slug"
      }
    }
  ]
}
```

#### DUPLICATE_SLUG

**When**: Slug already exists in database

**HTTP Status**: 409 Conflict

**Response**:
```json
{
  "errors": [
    {
      "message": "Project with slug 'my-project' already exists",
      "extensions": {
        "code": "DUPLICATE_SLUG",
        "field": "slug"
      }
    }
  ]
}
```

---

## Slug Auto-Generation

### Algorithm

The client auto-generates slugs from project names using the following process:

```dart
static String slugify(String text, {int? maxLength, String delimiter = '-'}) {
  if (text.isEmpty) return '';

  // Step 1: Remove diacritics (é → e, ñ → n)
  // Step 2: Convert to lowercase
  // Step 3: Replace whitespace with hyphens
  // Step 4: Remove non-alphanumeric characters (except hyphens)
  // Step 5: Collapse consecutive hyphens to single hyphen
  // Step 6: Trim leading/trailing hyphens
  // Step 7: Optional truncation at word boundaries

  // Implementation in lib/core/utils/slug_generator.dart
}
```

### Example Transformations

| Input Name | Generated Slug |
|------------|----------------|
| `Hello World` | `hello-world` |
| `My Room Scan` | `my-room-scan` |
| `Product #123` | `product-123` |
| `Café & Restaurant` | `cafe-restaurant` |
| `   Multiple   Spaces   ` | `multiple-spaces` |
| `Project!!!` | `project` |
| `C++ Programming` | `c-programming` |

### Real-Time Generation

Slug is auto-generated as user types the project name:

```dart
// In CreateProjectScreen
@override
void initState() {
  super.initState();
  _nameController = TextEditingController();
  _slugController = TextEditingController();

  // Auto-generate slug as user types name
  _nameController.addListener(() {
    final name = _nameController.text;
    final generatedSlug = SlugGenerator.slugify(name);
    if (_slugController.text != generatedSlug) {
      _slugController.text = generatedSlug;
    }
  });
}
```

### User Override

Users can manually edit the auto-generated slug:
- Slug field is editable TextFormField (not read-only)
- Validation runs on manual edits
- Manual edits persist until name changes again

---

## Error Handling

### Client-Side Error Handling

```dart
// In CreateProjectScreen
Future<void> _handleSave() async {
  if (!_formKey.currentState!.validate()) {
    // Validation failed - inline errors displayed
    return;
  }

  try {
    final input = CreateProjectInput.fromForm(
      name: _nameController.text,
      slug: _slugController.text,
      description: _descriptionController.text,
    );

    await _projectService.createProject(input);

    // Success - navigate back
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  } catch (e) {
    // Handle backend errors
    if (mounted) {
      final message = _getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

String _getErrorMessage(dynamic error) {
  final errorString = error.toString();

  // Handle duplicate slug error
  if (errorString.contains('DUPLICATE_SLUG') ||
      errorString.contains('already exists')) {
    return 'A project with this slug already exists. Please choose a different slug.';
  }

  // Handle validation error
  if (errorString.contains('VALIDATION_ERROR')) {
    return 'Invalid input. Please check your entries.';
  }

  // Generic error
  return 'Failed to create project. Please try again.';
}
```

### Server-Side Error Handling

**Backend behavior**:
1. Receives createProject mutation with `CreateProjectInput`
2. Validates input (format, length, required fields)
3. Checks database for slug uniqueness (case-insensitive)
4. Returns appropriate error code if validation fails
5. Creates project if all validations pass

**Database constraint**:
```sql
-- Unique constraint on slug (case-insensitive)
CREATE UNIQUE INDEX idx_projects_slug_lower ON projects (LOWER(slug));
```

---

## Testing

### Unit Tests

```dart
// test/core/utils/slug_generator_test.dart
group('SlugGenerator.isValidSlug', () {
  test('accepts valid slugs', () {
    expect(SlugGenerator.isValidSlug('hello-world'), true);
    expect(SlugGenerator.isValidSlug('project-123'), true);
    expect(SlugGenerator.isValidSlug('test'), true);
    expect(SlugGenerator.isValidSlug('a-b-c-d'), true);
  });

  test('rejects invalid slugs', () {
    expect(SlugGenerator.isValidSlug('Hello-World'), false); // uppercase
    expect(SlugGenerator.isValidSlug('-hello'), false); // leading hyphen
    expect(SlugGenerator.isValidSlug('hello-'), false); // trailing hyphen
    expect(SlugGenerator.isValidSlug('hello--world'), false); // consecutive hyphens
    expect(SlugGenerator.isValidSlug('hello_world'), false); // underscore
    expect(SlugGenerator.isValidSlug('hello world'), false); // space
    expect(SlugGenerator.isValidSlug(''), false); // empty
  });
});
```

### Integration Tests

```dart
// test/integration/create_project_flow_test.dart
testWidgets('shows error for duplicate slug', (tester) async {
  // Setup: Create project with slug 'test-project'
  // ...

  // Attempt to create another project with same slug
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(Key('name-field')), 'Test Project 2');
  await tester.enterText(find.byKey(Key('slug-field')), 'test-project');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify error message displayed
  expect(
    find.text('A project with this slug already exists'),
    findsOneWidget,
  );
});
```

---

## Performance

### Validation Performance

| Operation | Expected Time | Target |
|-----------|---------------|--------|
| Slug format validation | <1ms | <100ms ✅ |
| Slug auto-generation | <10ms | <100ms ✅ |
| Backend uniqueness check | <50ms | <3s ✅ |

### Uniqueness Check

**Database query**:
```sql
SELECT EXISTS(SELECT 1 FROM projects WHERE LOWER(slug) = LOWER($1));
```

**Indexed lookup**: O(log n) time complexity with B-tree index

**Expected performance**: <50ms for databases with millions of projects

---

## Summary

| Aspect | Implementation | Status |
|--------|----------------|--------|
| **Format validation** | Regex-based client & server | ✅ Specified |
| **Uniqueness validation** | Database constraint | ✅ Specified |
| **Auto-generation** | Real-time from name field | ✅ Specified |
| **Error handling** | Inline errors + SnackBar | ✅ Specified |
| **User override** | Editable slug field | ✅ Specified |
| **Testing** | Unit + integration tests | ✅ Specified |

**Next**: Implement slug generator utility and wire to create form
