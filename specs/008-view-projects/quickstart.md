# Quickstart Guide: Integrating Project Management Features

**Feature**: 008-view-projects
**Date**: 2025-12-24
**Prerequisites**: research.md ✅, data-model.md ✅, contracts/ ✅

## Overview

This guide provides step-by-step integration instructions for adding the complete project management features to the existing codebase. Follow these patterns to maintain consistency with existing code.

---

## 1. Create Project Integration

### Step 1: Add Slug Generator Utility

**File**: `lib/core/utils/slug_generator.dart`

**Pattern**: Follows existing utility pattern from `lib/features/auth/utils/email_validator.dart`

**Implementation**:
```dart
/// Slug generation utility for creating URL-friendly strings
class SlugGenerator {
  // Pre-compiled regex patterns
  static final RegExp _validSlugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  /// Generate URL-friendly slug from text
  static String slugify(String text, {int? maxLength}) {
    // Implementation from research.md
  }

  /// Validate if string is a valid slug
  static bool isValidSlug(String slug) {
    if (slug.isEmpty) return false;
    return _validSlugPattern.hasMatch(slug);
  }
}
```

**Integration Points**:
- Used in CreateProjectScreen for auto-generation
- Used in form validation for slug field
- Tested in `test/core/utils/slug_generator_test.dart`

---

### Step 2: Add CreateProject Method to ProjectService

**File**: `lib/features/home/services/project_service.dart`

**Pattern**: Follows existing `updateProject()` method pattern

**Add mutation string**:
```dart
static const String _createProjectMutation = r'''
  mutation createProject($data: CreateProjectInput!) {
    createProject(data: $data) {
      id
      slug
      name { text(lang: EN) }
      description { text(lang: EN) }
      imageUrl
      status
      subscription {
        live
        active
        trial
        expiresAt
        monthlyPrice
      }
      updatedAt
      createdAt
    }
  }
''';
```

**Add method**:
```dart
/// Creates a new project
///
/// Throws exception if:
/// - Network error occurs
/// - Slug already exists (DUPLICATE_SLUG)
/// - Validation fails (VALIDATION_ERROR)
Future<Project> createProject({
  required String name,
  required String slug,
  String? description,
}) async {
  try {
    final result = await _graphQLService.mutate(
      _createProjectMutation,
      variables: {
        'data': {
          'name': name,
          'slug': slug,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      },
    );

    if (result.hasException) {
      final exception = result.exception!;

      // Handle duplicate slug error
      if (exception.graphqlErrors.any((e) =>
          e.extensions?['code'] == 'DUPLICATE_SLUG')) {
        throw Exception('A project with this slug already exists');
      }

      // Handle validation errors
      if (exception.graphqlErrors.any((e) =>
          e.extensions?['code'] == 'VALIDATION_ERROR')) {
        final errorMessage = exception.graphqlErrors.first.message;
        throw Exception(errorMessage);
      }

      // Generic error
      throw Exception('Failed to create project: ${exception.toString()}');
    }

    return Project.fromJson(result.data!['createProject']);
  } catch (e) {
    rethrow;
  }
}
```

**Integration Points**:
- Called from CreateProjectScreen on form submission
- Returns Project object on success
- Throws exception with user-friendly messages on failure

---

### Step 3: Create Project Screen

**File**: `lib/features/projects/screens/create_project_screen.dart`

**Pattern**: Follows `lib/features/projects/widgets/project_data_tab.dart`

**Key Components**:
```dart
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

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

    // Auto-generate slug from name
    _nameController.addListener(_generateSlug);

    // Track dirty state
    _nameController.addListener(_onFieldChanged);
    _slugController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _generateSlug() {
    final name = _nameController.text;
    final generatedSlug = SlugGenerator.slugify(name);
    if (_slugController.text != generatedSlug) {
      _slugController.text = generatedSlug;
    }
  }

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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _projectService.createProject(
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Project')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'My Room',
                ),
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
                },
              ),
              const SizedBox(height: 16),

              // Slug field (auto-generated, but editable)
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'my-room',
                  helperText: 'Auto-generated from name (editable)',
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
              ),
              const SizedBox(height: 16),

              // Description field (optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop || !_isDirty) return;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (shouldPop == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
```

---

### Step 4: Wire Create Project Route

**File**: `lib/core/navigation/routes.dart`

**Change**:
```dart
// BEFORE (placeholder)
static const String createProject = '/create-project';

// Route setup in main.dart or router
'/create-project': (context) => const PlaceholderScreen(),

// AFTER (actual screen)
'/create-project': (context) => const CreateProjectScreen(),
```

---

### Step 5: Wire FAB on Home Screen

**File**: `lib/features/home/screens/home_screen.dart`

**Change**:
```dart
// Existing FAB onPressed
floatingActionButton: FloatingActionButton(
  onPressed: () {
    // OLD: Navigator.pushNamed(context, AppRoutes.createProject);

    // NEW: Handle navigation with refresh
    Navigator.pushNamed(context, AppRoutes.createProject).then((result) {
      if (result == true) {
        // Refresh project list if creation succeeded
        _refreshProjects();
      }
    });
  },
  child: const Icon(Icons.add),
),
```

---

## 2. Project Sorting Integration

### Step 1: Add ProjectSortOption Enum

**File**: `lib/features/home/models/project_sort_option.dart`

**Implementation**:
```dart
/// Sort options for project list
enum ProjectSortOption {
  nameAscending,
  nameDescending,
  dateNewest,
  dateOldest,
  status,
}

extension ProjectSortOptionExtension on ProjectSortOption {
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

---

### Step 2: Add Sort Logic to ProjectService

**File**: `lib/features/home/services/project_service.dart`

**Modify fetchProjects method**:
```dart
Future<List<Project>> fetchProjects({ProjectSortOption? sortBy}) async {
  // Existing fetch logic
  final projects = await _fetchFromAPI();

  // NEW: Apply sort if specified
  if (sortBy != null) {
    _sortProjects(projects, sortBy);
  }

  return projects;
}

void _sortProjects(List<Project> projects, ProjectSortOption sortBy) {
  switch (sortBy) {
    case ProjectSortOption.nameAscending:
      projects.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case ProjectSortOption.nameDescending:
      projects.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      break;
    case ProjectSortOption.dateNewest:
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case ProjectSortOption.dateOldest:
      projects.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case ProjectSortOption.status:
      projects.sort(_compareByStatus);
      break;
  }
}

int _compareByStatus(Project a, Project b) {
  const statusPriority = {
    'Live': 0,
    'Live (Trial)': 1,
    'Live (Inactive)': 2,
    'Not Live': 3,
  };

  final aPriority = statusPriority[a.statusLabel] ?? 999;
  final bPriority = statusPriority[b.statusLabel] ?? 999;

  final priorityCompare = aPriority.compareTo(bPriority);
  if (priorityCompare != 0) return priorityCompare;

  // Secondary sort by name
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
```

---

### Step 3: Create Sort Menu Widget

**File**: `lib/features/home/widgets/sort_menu.dart`

**Implementation**:
```dart
class SortMenu extends StatelessWidget {
  final ProjectSortOption currentSort;
  final ValueChanged<ProjectSortOption> onSortChanged;

  const SortMenu({
    Key? key,
    required this.currentSort,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProjectSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort projects',
      onSelected: onSortChanged,
      itemBuilder: (context) => ProjectSortOption.values.map((option) {
        return PopupMenuItem<ProjectSortOption>(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 20),
              const SizedBox(width: 8),
              Text(option.label),
              if (option == currentSort)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
```

---

### Step 4: Wire Sort Menu to Home Screen

**File**: `lib/features/home/screens/home_screen.dart`

**Add state variable**:
```dart
class _HomeScreenState extends State<HomeScreen> {
  ProjectSortOption _currentSort = ProjectSortOption.dateNewest;
  // ... existing state
}
```

**Add to AppBar actions**:
```dart
AppBar(
  title: const Text('Projects'),
  actions: [
    // NEW: Add sort menu
    SortMenu(
      currentSort: _currentSort,
      onSortChanged: (newSort) {
        setState(() {
          _currentSort = newSort;
        });
        _refreshProjects();
      },
    ),
    // ... existing actions (search, etc.)
  ],
)
```

**Update fetchProjects call**:
```dart
Future<void> _refreshProjects() async {
  final projects = await _projectService.fetchProjects(sortBy: _currentSort);
  setState(() {
    _projects = projects;
  });
}
```

---

## 3. Product Creation from Project Integration

### Step 1: Wire Product Creation Navigation

**File**: `lib/features/projects/widgets/project_products_tab.dart`

**Find existing FAB** (line ~107-108):
```dart
// BEFORE (TODO comment)
// TODO: Navigate to product creation with project context

// AFTER
floatingActionButton: FloatingActionButton(
  onPressed: () => _navigateToCreateProduct(),
  child: const Icon(Icons.add),
  tooltip: 'Add Product',
),
```

**Add navigation method**:
```dart
Future<void> _navigateToCreateProduct() async {
  final result = await Navigator.pushNamed(
    context,
    AppRoutes.createProduct,
    arguments: {
      'projectId': widget.project.id,
      'projectName': widget.project.name,
    },
  );

  if (result == true) {
    // Refresh products tab
    widget.onUpdate();
  }
}
```

---

### Step 2: Handle Project Context in Product Creation

**File**: `lib/features/products/screens/create_product_screen.dart`

**Receive project context**:
```dart
class CreateProductScreen extends StatefulWidget {
  final String? projectId;
  final String? projectName;

  const CreateProductScreen({
    Key? key,
    this.projectId,
    this.projectName,
  }) : super(key: key);

  // ...
}
```

**Pre-fill project field**:
```dart
@override
void initState() {
  super.initState();

  // Pre-fill project if context provided
  if (widget.projectId != null) {
    _selectedProjectId = widget.projectId;
    _projectController.text = widget.projectName ?? '';
  }
}
```

---

## 4. Product Search Integration

### Step 1: Add Search Field to Products Tab

**File**: `lib/features/projects/widgets/project_products_tab.dart`

**Add state variable**:
```dart
class _ProjectProductsTabState extends State<ProjectProductsTab> {
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

**Add search field to UI** (line ~153):
```dart
// Replace TODO comment with actual implementation
Padding(
  padding: const EdgeInsets.all(16),
  child: TextField(
    controller: _searchController,
    decoration: InputDecoration(
      hintText: 'Search products...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),
```

**Filter products list**:
```dart
Widget build(BuildContext context) {
  // Filter products based on search query
  final filteredProducts = _searchQuery.isEmpty
      ? widget.project.products
      : widget.project.products.where((product) {
          return product.name.toLowerCase().contains(_searchQuery) ||
              (product.description?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

  return Column(
    children: [
      // Search field
      _buildSearchField(),

      // Product list (use filteredProducts instead of widget.project.products)
      Expanded(
        child: ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            // ... build product card
          },
        ),
      ),
    ],
  );
}
```

---

## Testing Integration

### Unit Tests

**Slug Generator** (`test/core/utils/slug_generator_test.dart`):
```dart
group('SlugGenerator', () {
  test('generates valid slugs', () {
    expect(SlugGenerator.slugify('Hello World'), 'hello-world');
    expect(SlugGenerator.slugify('Café'), 'cafe');
  });

  test('validates slugs correctly', () {
    expect(SlugGenerator.isValidSlug('hello-world'), true);
    expect(SlugGenerator.isValidSlug('Hello-World'), false);
  });
});
```

**Sort Logic** (`test/features/home/services/project_service_test.dart`):
```dart
test('sorts projects by name ascending', () async {
  final projects = await projectService.fetchProjects(
    sortBy: ProjectSortOption.nameAscending,
  );

  for (int i = 0; i < projects.length - 1; i++) {
    expect(
      projects[i].name.toLowerCase().compareTo(projects[i + 1].name.toLowerCase()),
      lessThanOrEqualTo(0),
    );
  }
});
```

### Widget Tests

**Create Project Screen** (`test/features/projects/screens/create_project_screen_test.dart`):
```dart
testWidgets('auto-generates slug from name', (tester) async {
  await tester.pumpWidget(createTestApp(const CreateProjectScreen()));

  await tester.enterText(find.byKey(Key('name-field')), 'My Project');
  await tester.pump();

  expect(find.text('my-project'), findsOneWidget);
});
```

### Integration Tests

**Complete Create Flow** (`test/integration/create_project_flow_test.dart`):
```dart
testWidgets('creates project and shows in list', (tester) async {
  // Tap FAB
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // Fill form
  await tester.enterText(find.byKey(Key('name-field')), 'Test Project');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify navigation back and project appears
  expect(find.text('Test Project'), findsOneWidget);
});
```

---

## Summary

| Feature | Integration Points | Status |
|---------|-------------------|--------|
| **Create Project** | SlugGenerator, ProjectService, CreateProjectScreen, Routes | ✅ Specified |
| **Sort Projects** | ProjectSortOption, ProjectService, SortMenu, HomeScreen | ✅ Specified |
| **Product Creation** | ProductsTab, CreateProductScreen navigation | ✅ Specified |
| **Product Search** | ProductsTab search field and filtering | ✅ Specified |

**All patterns follow existing codebase conventions for consistency.**
