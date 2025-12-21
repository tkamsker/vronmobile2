# Quickstart: Project Data Edit Screen

**Feature**: 011-project-data
**Branch**: `011-project-data`
**Dependencies**: Feature 010-project-detail must be complete

## Prerequisites

Before starting implementation:

1. **Feature 010-project-detail** must be implemented and merged
   - ProjectDetailScreen exists
   - ProjectService.fetchProjectDetail exists
   - Navigation to detail screen works

2. **Design reference** available:
   - `Requirements/ProjectDetailData.jpg` - UI layout reference

3. **Review planning artifacts**:
   - [plan.md](plan.md) - Technical context and structure
   - [research.md](research.md) - Technical decisions
   - [data-model.md](data-model.md) - Data structures and validation
   - [contracts/update-project-mutation.graphql](contracts/update-project-mutation.graphql) - API contract

## Implementation Checklist

### Phase 1: Tests (TDD - Write First) ⚠️

**CRITICAL**: Write tests FIRST, watch them FAIL, then implement.

- [ ] Write `project_data_screen_test.dart` - Test form rendering and state
  - Test initial values populated
  - Test form validation (empty name, too short, valid)
  - Test save button disabled during loading
  - Test error message display
  - **Run test - Should FAIL** ✋

- [ ] Write `project_form_test.dart` - Test form widget
  - Test name field validation
  - Test description field validation
  - Test field controllers
  - **Run test - Should FAIL** ✋

- [ ] Write `project_service_update_test.dart` - Test service method
  - Test successful update
  - Test error handling (not found, unauthorized, validation)
  - Mock GraphQL client
  - **Run test - Should FAIL** ✋

---

### Phase 2: Service Extension

- [ ] Add `updateProject` method to `ProjectService`
  - Location: `lib/features/home/services/project_service.dart`
  - Implement GraphQL mutation from contracts/
  - Error handling for all error types
  - **Run service tests - Should PASS** ✅

- [ ] Add i18n keys for project data edit
  - Update `lib/core/i18n/en.json`
  - Update `lib/core/i18n/de.json`
  - Update `lib/core/i18n/pt.json`
  - Keys: projectData.* (see data-model.md for full list)

---

### Phase 3: Widgets (Bottom-Up)

- [ ] Create `ProjectForm` widget
  - Location: `lib/features/project_data/widgets/project_form.dart`
  - Form with name and description fields
  - Validation logic
  - **Run widget tests - Should PASS** ✅

- [ ] Create `SaveButton` widget (optional - can use ElevatedButton directly)
  - Location: `lib/features/project_data/widgets/save_button.dart`
  - Loading state with spinner
  - Disabled state when form invalid

---

### Phase 4: Screen Implementation

- [ ] Create `ProjectDataScreen`
  - Location: `lib/features/project_data/screens/project_data_screen.dart`
  - Scaffold with AppBar
  - Form with TextFormFields
  - Save/Cancel buttons
  - Handle navigation arguments
  - **Run screen tests - Should PASS** ✅

- [ ] Implement save functionality
  - Call `ProjectService.updateProject`
  - Show loading state
  - Handle success (navigate back with result)
  - Handle errors (display appropriate message)

- [ ] Implement unsaved changes dialog
  - Detect if form has unsaved changes
  - Show confirmation on back navigation
  - Use WillPopScope widget

---

### Phase 5: Navigation Integration

- [ ] Add route to `lib/core/navigation/routes.dart`
  - Add `static const projectData = '/project-data';`

- [ ] Register route in `lib/main.dart`
  - Map AppRoutes.projectData → ProjectDataScreen

- [ ] Update `ProjectDetailScreen`
  - Add "Edit" button/icon to app bar
  - Navigate to ProjectDataScreen on tap
  - Pass projectId, name, description as arguments
  - Handle return result (refresh if data updated)

---

### Phase 6: Verification

- [ ] Verify design matches `Requirements/ProjectDetailData.jpg`
  - Form layout correct
  - Labels and placeholders correct
  - Buttons styled correctly

- [ ] Run all tests
  - `flutter test test/features/project_data/`
  - All tests should PASS ✅

- [ ] Manual testing
  - Navigate from ProjectDetailScreen to ProjectDataScreen
  - Test successful save (changes reflect in detail screen)
  - Test validation errors (empty name, too short)
  - Test cancel navigation
  - Test unsaved changes dialog
  - Test error scenarios (network error, unauthorized)

- [ ] Accessibility check
  - All form fields have semantic labels
  - Touch targets at least 44x44 px
  - Screen reader support

---

## Test Scenarios

### Happy Path
1. Navigate to ProjectDetailScreen for a project
2. Tap "Edit" button → ProjectDataScreen opens
3. Form pre-filled with current name and description
4. Edit name field → change "Marketing Analytics" to "Marketing Dashboard"
5. Edit description field → add more details
6. Tap "Save Changes" button
7. Loading spinner shows briefly
8. Success message appears
9. Screen navigates back to ProjectDetailScreen
10. Detail screen refreshes and shows updated data

### Validation Errors
1. Navigate to ProjectDataScreen
2. Clear name field (delete all text)
3. Tap "Save Changes"
4. Error message appears: "Project name is required"
5. Type "AB" (only 2 characters)
6. Tap "Save Changes"
7. Error message appears: "Project name must be at least 3 characters"
8. Type "ABC" (valid)
9. Error message disappears
10. Save proceeds successfully

### Unsaved Changes
1. Navigate to ProjectDataScreen
2. Edit name field
3. Tap back button (or system back)
4. Dialog appears: "You have unsaved changes. Are you sure you want to leave?"
5. Tap "Keep Editing" → dialog closes, stay on screen
6. Tap back button again
7. Tap "Discard" → navigate back without saving

### Error Scenarios
1. **Network Error**:
   - Disconnect internet
   - Edit project and tap Save
   - Error message: "Connection error. Please check your internet connection."
   - "Retry" button appears
   - Reconnect internet
   - Tap "Retry" → save succeeds

2. **Unauthorized**:
   - User token expired
   - Edit project and tap Save
   - Error: "You don't have permission to edit this project"
   - Navigate to login

3. **Project Not Found**:
   - Project deleted by another user
   - Edit and tap Save
   - Error: "Project not found"
   - Navigate back to home screen

---

## Implementation Tips

### 1. Form Validation
```dart
// In ProjectDataScreen
final _formKey = GlobalKey<FormState>();

TextFormField(
  controller: _nameController,
  validator: _validateName,
  decoration: InputDecoration(
    labelText: 'projectData.nameLabel'.tr(),
    errorMaxLines: 2,
  ),
);

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
  if (!_formKey.currentState!.validate()) {
    return; // Validation failed
  }
  // Proceed with save
}
```

### 2. Unsaved Changes Detection
```dart
bool get _hasUnsavedChanges {
  return _nameController.text.trim() != widget.initialName ||
         _descriptionController.text.trim() != widget.initialDescription;
}

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      if (!_hasUnsavedChanges) return true;

      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('projectData.unsavedChangesTitle'.tr()),
          content: Text('projectData.unsavedChangesMessage'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('projectData.keepEditingButton'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('projectData.discardButton'.tr()),
            ),
          ],
        ),
      );

      return shouldPop ?? false;
    },
    child: Scaffold(...),
  );
}
```

### 3. Error Message Parsing
```dart
String _parseErrorMessage(dynamic error) {
  final errorString = error.toString().toLowerCase();

  if (errorString.contains('not found')) {
    return 'projectData.errors.notFound'.tr();
  } else if (errorString.contains('unauthorized')) {
    return 'projectData.errors.unauthorized'.tr();
  } else if (errorString.contains('conflict')) {
    return 'projectData.errors.conflict'.tr();
  } else if (errorString.contains('network') ||
             errorString.contains('timeout') ||
             errorString.contains('connection')) {
    return 'projectData.errors.network'.tr();
  } else {
    return 'projectData.errors.unknown'.tr();
  }
}
```

### 4. Navigation with Result
```dart
// From ProjectDetailScreen
final wasUpdated = await Navigator.pushNamed(
  context,
  AppRoutes.projectData,
  arguments: {
    'projectId': widget.projectId,
    'initialName': project.name,
    'initialDescription': project.description,
  },
) as bool?;

if (wasUpdated == true) {
  setState(() {
    _projectFuture = _projectService.fetchProjectDetail(widget.projectId);
  });
}

// From ProjectDataScreen on success
Navigator.pop(context, true);
```

---

## Common Pitfalls

1. **❌ Implementing before writing tests**
   - ✅ Always write tests first, watch them fail, then implement

2. **❌ Not disposing TextEditingControllers**
   - ✅ Always call `controller.dispose()` in dispose() method

3. **❌ Forgetting to trim text input**
   - ✅ Always use `.trim()` before validation and submission

4. **❌ Not handling all error cases**
   - ✅ Handle: validation, network, server errors, not found, unauthorized

5. **❌ Not checking `mounted` before setState after async operations**
   - ✅ Always check `if (mounted)` before setState/Navigator after await

6. **❌ Hardcoding strings**
   - ✅ Use i18n with `.tr()` for all user-facing text

---

## Success Criteria

- ✅ All tests pass (`flutter test`)
- ✅ Form validates input correctly
- ✅ Save operation updates project successfully
- ✅ Errors display appropriate messages
- ✅ Unsaved changes dialog works
- ✅ Navigation returns result to detail screen
- ✅ Detail screen refreshes after update
- ✅ Design matches Requirements/ProjectDetailData.jpg
- ✅ No console warnings or errors
- ✅ Performance: save < 2 seconds, validation < 100ms

---

## Next Steps After Implementation

1. **Create PR**: Commit to branch `011-project-data`, create pull request to main
2. **Code Review**: Request review, address feedback
3. **Merge**: Merge to main after approval
4. **Verify**: Test on device/emulator after merge
5. **Document**: Update main README if needed
