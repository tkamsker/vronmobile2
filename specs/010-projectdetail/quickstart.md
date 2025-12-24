# Quickstart Guide: Project Detail and Data Management

**Feature**: UC10 (Project Detail) and UC11 (Project Data)
**Branch**: `003-projectdetail`
**Estimated Time**: 8-12 hours (TDD approach)

## Prerequisites

✅ Branch `003-projectdetail` checked out
✅ All dependencies already installed (no new packages required)
✅ Familiarized with:
- Existing `Project` model (`lib/features/home/models/project.dart`)
- Existing `ProjectService` (`lib/features/home/services/project_service.dart`)
- Flutter TabBar/TabBarView widgets
- GraphQL mutation/query patterns in this codebase

## Implementation Phases

This guide follows Test-Driven Development (TDD) principles. Each phase follows the Red-Green-Refactor cycle:
1. **Red**: Write a failing test
2. **Green**: Write minimal code to pass the test
3. **Refactor**: Improve code quality while keeping tests green

---

## Phase 1: Extend Project Model (60 min)

### Step 1.1: Write Failing Tests (Red)

**File**: `test/features/home/models/project_test.dart`

Add tests for the new `description` field:

```dart
group('Project with description field', () {
  test('fromJson should parse description from I18NField', () {
    final json = {
      'id': 'test-id',
      'slug': 'test-slug',
      'name': {'text': 'Test Project'},
      'description': {'text': 'Test description'},  // NEW
      'imageUrl': 'https://example.com/image.jpg',
      'isLive': true,
      'subscription': {},
    };

    final project = Project.fromJson(json);

    expect(project.description, 'Test description');
  });

  test('fromJson should handle missing description', () {
    final json = {
      'id': 'test-id',
      'slug': 'test-slug',
      'name': {'text': 'Test Project'},
      // description field omitted
      'imageUrl': 'https://example.com/image.jpg',
      'isLive': true,
      'subscription': {},
    };

    final project = Project.fromJson(json);

    expect(project.description, '');  // Should default to empty string
  });

  test('copyWith should update description', () {
    final original = Project(
      id: '1',
      slug: 'test',
      name: 'Test',
      description: 'Original description',
      imageUrl: 'url',
      isLive: false,
      subscription: ProjectSubscription(...),
    );

    final updated = original.copyWith(description: 'Updated description');

    expect(updated.description, 'Updated description');
    expect(updated.name, 'Test');  // Other fields unchanged
  });

  test('equality operator should include description', () {
    final project1 = Project(..., description: 'Desc A');
    final project2 = Project(..., description: 'Desc B');

    expect(project1 == project2, false);
  });
});
```

**Run tests**: `flutter test test/features/home/models/project_test.dart`
**Expected**: Tests fail (Red) - description field doesn't exist yet

### Step 1.2: Implement Description Field (Green)

**File**: `lib/features/home/models/project.dart`

1. Add `description` field to constructor
2. Add description parsing in `fromJson`
3. Update `copyWith` method
4. Update equality operator and hashCode

See `specs/003-projectdetail/data-model.md` for complete implementation.

**Run tests**: `flutter test test/features/home/models/project_test.dart`
**Expected**: All tests pass (Green)

### Step 1.3: Refactor

- Extract description parsing logic if duplicated with name parsing
- Add doc comments for new field
- Verify no breaking changes to existing code

**Run all tests**: `flutter test`
**Commit**: `git commit -m "feat(models): Add description field to Project model"`

---

## Phase 2: Implement GraphQL Operations (90 min)

### Step 2.1: Write Failing Service Tests (Red)

**File**: `test/features/home/services/project_service_test.dart`

```dart
group('getProjectDetail', () {
  test('should fetch project with description', () async {
    // Arrange: Mock GraphQL response
    when(mockGraphQLService.query(any, variables: anyNamed('variables')))
        .thenAnswer((_) async => mockSuccessResult);

    // Act
    final project = await projectService.getProjectDetail('proj-123');

    // Assert
    expect(project.id, 'proj-123');
    expect(project.description, isNotEmpty);
  });

  test('should throw exception when project not found', () async {
    // Arrange: Mock error response
    when(mockGraphQLService.query(any, variables: anyNamed('variables')))
        .thenAnswer((_) async => mockNotFoundResult);

    // Act & Assert
    expect(
      () => projectService.getProjectDetail('invalid-id'),
      throwsException,
    );
  });
});

group('updateProject', () {
  test('should update project fields', () async {
    // Arrange
    final updateData = {
      'name': 'New Name',
      'slug': 'new-slug',
      'description': 'New description',
    };

    when(mockGraphQLService.mutate(any, variables: anyNamed('variables')))
        .thenAnswer((_) async => mockSuccessResult);

    // Act
    final updatedProject = await projectService.updateProject('proj-123', updateData);

    // Assert
    expect(updatedProject.name, 'New Name');
    expect(updatedProject.slug, 'new-slug');
    expect(updatedProject.description, 'New description');
  });

  test('should handle server validation errors', () async {
    // Arrange: Mock validation error response
    when(mockGraphQLService.mutate(any, variables: anyNamed('variables')))
        .thenAnswer((_) async => mockValidationErrorResult);

    // Act & Assert
    expect(
      () => projectService.updateProject('proj-123', {}),
      throwsException,
    );
  });
});
```

**Run tests**: `flutter test test/features/home/services/project_service_test.dart`
**Expected**: Tests fail (Red) - methods don't exist yet

### Step 2.2: Implement GraphQL Methods (Green)

**File**: `lib/features/home/services/project_service.dart`

Add two methods:

```dart
static const String _projectDetailQuery = '''
  query GetProjectDetail(\$id: ID!, \$lang: Language!) {
    project(id: \$id) {
      id
      slug
      imageUrl
      isLive
      liveDate
      name {
        text(lang: \$lang)
      }
      description {
        text(lang: \$lang)
      }
      subscription {
        # ... same fields as getProjects
      }
    }
  }
''';

Future<Project> getProjectDetail(String projectId) async {
  try {
    final result = await _graphqlService.query(
      _projectDetailQuery,
      variables: {'id': projectId, 'lang': _language},
    );

    if (result.hasException) {
      // Handle errors (see research.md for pattern)
    }

    if (result.data == null || result.data!['project'] == null) {
      throw Exception('Project not found');
    }

    return Project.fromJson(result.data!['project'] as Map<String, dynamic>);
  } catch (e) {
    if (kDebugMode) print('❌ [PROJECT DETAIL] Error: ${e.toString()}');
    rethrow;
  }
}

static const String _updateProjectMutation = '''
  mutation UpdateProject(\$id: ID!, \$data: UpdateProjectInput!) {
    updateProject(id: \$id, data: \$data) {
      id
      slug
      name {
        text(lang: EN)
      }
      description {
        text(lang: EN)
      }
      imageUrl
    }
  }
''';

Future<Project> updateProject(String projectId, Map<String, dynamic> data) async {
  try {
    final result = await _graphqlService.mutate(
      _updateProjectMutation,
      variables: {'id': projectId, 'data': data},
    );

    if (result.hasException) {
      // Handle errors
    }

    if (result.data == null || result.data!['updateProject'] == null) {
      throw Exception('Failed to update project');
    }

    return Project.fromJson(result.data!['updateProject'] as Map<String, dynamic>);
  } catch (e) {
    if (kDebugMode) print('❌ [UPDATE PROJECT] Error: ${e.toString()}');
    rethrow;
  }
}
```

**Run tests**: `flutter test test/features/home/services/project_service_test.dart`
**Expected**: All tests pass (Green)

### Step 2.3: Refactor

- Extract error handling to helper method if duplicated
- Add debug logging consistency

**Commit**: `git commit -m "feat(services): Add getProjectDetail and updateProject methods"`

---

## Phase 3: Create Project Detail Screen (120 min)

### Step 3.1: Write Failing Widget Tests (Red)

**File**: `test/features/projects/screens/project_detail_screen_test.dart`

```dart
void main() {
  testWidgets('ProjectDetailScreen shows loading state initially', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectDetailScreen(),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ProjectDetailScreen displays project data after load', (tester) async {
    // Arrange: Mock project service
    when(mockProjectService.getProjectDetail(any))
        .thenAnswer((_) async => mockProject);

    await tester.pumpWidget(MaterialApp(
      home: ProjectDetailScreen(),
    ));

    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Test Project'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);
    expect(find.text('Project data'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('ProjectDetailScreen shows error message on failure', (tester) async {
    // Arrange: Mock error
    when(mockProjectService.getProjectDetail(any))
        .thenThrow(Exception('Failed to load'));

    await tester.pumpWidget(MaterialApp(
      home: ProjectDetailScreen(),
    ));

    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Failed to load project'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);  // Retry button
  });
}
```

**Run tests**: `flutter test test/features/projects/screens/project_detail_screen_test.dart`
**Expected**: Tests fail (Red) - screen doesn't exist yet

### Step 3.2: Implement ProjectDetailScreen (Green)

**File**: `lib/features/projects/screens/project_detail_screen.dart`

```dart
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProjectService _projectService;
  Project? _project;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _projectService = ProjectService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final projectId = args['projectId'] as String;
    _loadProject(projectId);
  }

  Future<void> _loadProject(String projectId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final project = await _projectService.getProjectDetail(projectId);
      setState(() {
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load project';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              ElevatedButton(
                onPressed: () => _loadProject(_project?.id ?? ''),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Viewer'),
            Tab(text: 'Project data'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProjectViewerTab(project: _project!),
          ProjectDataTab(project: _project!),
          ProjectProductsTab(project: _project!),
        ],
      ),
    );
  }
}
```

**Run tests**: `flutter test test/features/projects/screens/project_detail_screen_test.dart`
**Expected**: All tests pass (Green)

### Step 3.3: Implement Stub Tab Widgets

Create placeholder widgets for the three tabs:
- `lib/features/projects/widgets/project_viewer_tab.dart`
- `lib/features/projects/widgets/project_data_tab.dart`
- `lib/features/projects/widgets/project_products_tab.dart`

**Commit**: `git commit -m "feat(screens): Implement ProjectDetailScreen with tab navigation"`

---

## Phase 4: Implement Project Data Edit Form (180 min)

### Step 4.1: Write Validator Tests (Red)

**File**: `test/features/projects/utils/project_validator_test.dart`

```dart
void main() {
  group('validateName', () {
    test('returns null for valid name', () {
      expect(ProjectValidator.validateName('Valid Name'), null);
    });

    test('returns error for empty name', () {
      expect(ProjectValidator.validateName(''), isNotNull);
      expect(ProjectValidator.validateName(null), isNotNull);
    });

    test('returns error for name over 100 characters', () {
      final longName = 'a' * 101;
      expect(ProjectValidator.validateName(longName), isNotNull);
    });
  });

  group('validateSlug', () {
    test('returns null for valid slug', () {
      expect(ProjectValidator.validateSlug('valid-slug-123'), null);
    });

    test('returns error for slug with uppercase', () {
      expect(ProjectValidator.validateSlug('Invalid-Slug'), isNotNull);
    });

    test('returns error for slug with spaces', () {
      expect(ProjectValidator.validateSlug('invalid slug'), isNotNull);
    });

    test('returns error for slug under 3 characters', () {
      expect(ProjectValidator.validateSlug('ab'), isNotNull);
    });
  });

  // ... tests for validateDescription
}
```

### Step 4.2: Implement Validator (Green)

**File**: `lib/features/projects/utils/project_validator.dart`

See data-model.md for validation rules.

### Step 4.3: Write ProjectDataTab Widget Tests (Red)

**File**: `test/features/projects/widgets/project_data_tab_test.dart`

Test form rendering, validation, dirty state tracking, save operation, error handling.

### Step 4.4: Implement ProjectDataTab (Green)

**File**: `lib/features/projects/widgets/project_data_tab.dart`

Implement the editable form with:
- TextFormField for name, slug, description
- Real-time validation on blur
- Save button (disabled until valid and dirty)
- Loading state during save
- Success/error messages via SnackBar

### Step 4.5: Refactor

- Extract form field widgets if duplicated
- Ensure proper controller disposal
- Verify AutomaticKeepAliveClientMixin preserves state

**Commit**: `git commit -m "feat(widgets): Implement ProjectDataTab with validation and save"`

---

## Phase 5: Integration Testing (60 min)

### Step 5.1: Write Integration Test (Red)

**File**: `test/integration/project_edit_journey_test.dart`

```dart
void main() {
  testWidgets('Full project edit journey', (tester) async {
    // 1. Navigate to project detail
    // 2. Wait for project to load
    // 3. Tap "Project data" tab
    // 4. Enter text in name field
    // 5. Enter text in slug field
    // 6. Enter text in description field
    // 7. Verify save button enabled
    // 8. Tap save button
    // 9. Verify success message
    // 10. Verify form returns to clean state
  });

  testWidgets('Tab switching preserves form state', (tester) async {
    // 1. Navigate to project detail
    // 2. Tap "Project data" tab
    // 3. Enter text in form
    // 4. Switch to "Viewer" tab
    // 5. Switch back to "Project data" tab
    // 6. Verify entered text still present
  });
}
```

### Step 5.2: Verify Integration Test Passes (Green)

Run integration tests and fix any issues.

**Commit**: `git commit -m "test(integration): Add project edit journey tests"`

---

## Phase 6: Navigation Integration (30 min)

### Step 6.1: Update Routes

**File**: `lib/core/navigation/routes.dart`

Route already exists (`AppRoutes.projectDetail`), no changes needed.

### Step 6.2: Update ProjectCard Navigation

**File**: `lib/features/home/widgets/project_card.dart`

Update `onTap` to navigate to ProjectDetailScreen with project ID:

```dart
onTap: () {
  Navigator.pushNamed(
    context,
    AppRoutes.projectDetail,
    arguments: {'projectId': project.id},
  );
}
```

### Step 6.3: Register Route in Main

**File**: `lib/main.dart`

Add route to MaterialApp:

```dart
routes: {
  // ... existing routes
  AppRoutes.projectDetail: (context) => const ProjectDetailScreen(),
}
```

**Commit**: `git commit -m "feat(navigation): Connect project detail screen to project list"`

---

## Phase 7: Final Testing & Review (60 min)

### Step 7.1: Run All Tests

```bash
flutter test
```

Verify all tests pass.

### Step 7.2: Manual UI Testing

1. Run app: `flutter run`
2. Login with test credentials
3. Navigate to projects list
4. Tap "Enter project" on a project card
5. Verify project detail screen loads
6. Verify tabs work correctly
7. Tap "Project data" tab
8. Modify form fields
9. Verify validation messages
10. Save changes
11. Verify success message
12. Verify changes persist

### Step 7.3: Code Review Checklist

- [ ] All tests pass
- [ ] No compiler warnings
- [ ] Code follows Dart style guide (run `flutter analyze`)
- [ ] All new files have proper documentation
- [ ] No console errors during manual testing
- [ ] Tab navigation preserves state
- [ ] Form validation works correctly
- [ ] Save operation succeeds and updates UI
- [ ] Error states display appropriate messages
- [ ] Back navigation works correctly
- [ ] No memory leaks (controllers disposed)

### Step 7.4: Create Pull Request

```bash
git push origin 003-projectdetail
```

Create PR with:
- Summary of changes
- Reference to specs/003-projectdetail/spec.md
- Screenshots of UI
- Test coverage report

---

## Troubleshooting

### Issue: Tests fail with "No MaterialLocalizations found"

**Solution**: Wrap widget in MaterialApp in test:
```dart
await tester.pumpWidget(MaterialApp(home: YourWidget()));
```

### Issue: Tab state not preserved

**Solution**: Ensure tab widgets use `AutomaticKeepAliveClientMixin` and call `super.build(context)` in build method.

### Issue: GraphQL errors in manual testing

**Solution**: Check GraphQL endpoint configuration in `.env` file. Verify backend supports `project` query and `updateProject` mutation.

### Issue: Form validation not triggering

**Solution**: Ensure `onChanged` or `onEditingComplete` callbacks are wired to validation functions.

---

## Estimated Time Breakdown

- Phase 1: 60 min (Model extension)
- Phase 2: 90 min (GraphQL operations)
- Phase 3: 120 min (Detail screen)
- Phase 4: 180 min (Edit form)
- Phase 5: 60 min (Integration tests)
- Phase 6: 30 min (Navigation)
- Phase 7: 60 min (Testing & review)

**Total**: 600 min (10 hours)

With refactoring and unexpected issues, expect 8-12 hours total.

---

## Next Steps After Completion

After this feature is merged:
1. Monitor production for errors
2. Gather user feedback on edit flow
3. Consider adding:
   - Undo/redo for edits
   - Autosave draft
   - Field-level history/audit log
   - Real-time collaboration warnings

**For questions or issues, refer to**:
- Specification: `specs/003-projectdetail/spec.md`
- Implementation plan: `specs/003-projectdetail/plan.md`
- Data model: `specs/003-projectdetail/data-model.md`
- Research notes: `specs/003-projectdetail/research.md`
