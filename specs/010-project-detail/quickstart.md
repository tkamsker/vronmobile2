# Quickstart: Project Detail Screen

**Feature**: 010-project-detail | **Date**: 2025-12-21

## What This Feature Does

Displays detailed project information when a user taps "Enter project" from the projects list. Shows project name, description, status, subscription details, and provides navigation buttons to "Project Data" (edit screen) and "Products" (product list).

## Key Files

### New Files to Create
```
lib/features/project_detail/
├── screens/
│   └── project_detail_screen.dart      # Main detail screen
└── widgets/
    ├── project_header.dart             # Header with image and name
    ├── project_info_section.dart       # Info cards for details
    └── project_action_buttons.dart     # Navigation buttons

test/features/project_detail/
├── screens/
│   └── project_detail_screen_test.dart
└── widgets/
    ├── project_header_test.dart
    ├── project_info_section_test.dart
    └── project_action_buttons_test.dart

test/integration/
└── project_detail_navigation_test.dart
```

### Files to Modify
```
lib/features/home/services/project_service.dart  # Add fetchProjectDetail()
lib/core/i18n/en.json                           # Add projectDetail strings
lib/core/i18n/de.json                           # Add projectDetail strings
lib/core/i18n/pt.json                           # Add projectDetail strings
lib/main.dart                                   # Update projectDetail route
```

## Implementation Checklist

### Phase 1: Tests (TDD - Write First)
- [ ] Write `project_detail_screen_test.dart` - Test screen states (loading, success, error)
- [ ] Write `project_header_test.dart` - Test header widget rendering
- [ ] Write `project_info_section_test.dart` - Test info section rendering
- [ ] Write `project_action_buttons_test.dart` - Test button actions
- [ ] Write navigation integration test
- [ ] Run tests - **All should FAIL**

### Phase 2: Service Extension
- [ ] Add `fetchProjectDetail(String projectId)` to ProjectService
- [ ] Add GraphQL query constant `_getProjectDetailQuery`
- [ ] Handle error cases (not found, unauthorized, network)
- [ ] Run service tests - **Should PASS**

### Phase 3: Widgets
- [ ] Create `project_header.dart` - Display image, name, status badge
- [ ] Create `project_info_section.dart` - Display description, subscription, dates
- [ ] Create `project_action_buttons.dart` - "Project Data" and "Products" buttons
- [ ] Run widget tests - **Should PASS**

### Phase 4: Screen Composition
- [ ] Create `project_detail_screen.dart` - Compose all widgets
- [ ] Implement FutureBuilder for async data loading
- [ ] Add loading, error, and success states
- [ ] Add pull-to-refresh with RefreshIndicator
- [ ] Run screen tests - **Should PASS**

### Phase 5: Integration
- [ ] Update `main.dart` route to use ProjectDetailScreen
- [ ] Add i18n strings to en.json, de.json, pt.json
- [ ] Add semantic labels for accessibility
- [ ] Run integration tests - **Should PASS**

### Phase 6: Verification
- [ ] Run `flutter analyze` - No issues
- [ ] Run all tests - All pass
- [ ] Test on device - Navigation works, data loads
- [ ] Verify design matches Requirements/ProjectDetail.jpg

## GraphQL Query

```graphql
query GetProjectDetail($id: ID!, $lang: Language!) {
  project(id: $id) {
    id
    slug
    name { text(lang: $lang) }
    description { text(lang: $lang) }
    imageUrl
    isLive
    liveDate
    subscription {
      isActive
      isTrial
      status
      # ... all subscription fields
    }
  }
}
```

## Navigation Flow

```
HomeScreen
  → User taps "Enter project" on ProjectCard
  → Calls _handleProjectTap(projectId)
  → Navigator.pushNamed(AppRoutes.projectDetail, arguments: projectId)
  → ProjectDetailScreen loads
  → Fetches project data via ProjectService.fetchProjectDetail()
  → Displays detail UI
```

## i18n Keys to Add

```json
{
  "projectDetail": {
    "title": "Project Details",
    "loading": "Loading project...",
    "error": "Failed to load project",
    "retry": "Retry",
    "projectData": "Project Data",
    "products": "Products",
    "liveStatus": "Live Status",
    "subscription": "Subscription",
    "lastUpdated": "Last updated"
  }
}
```

## Testing Strategy

### Unit Tests
- ProjectService.fetchProjectDetail() success/failure cases
- Widget rendering with mock data
- Error handling

### Widget Tests
- ProjectDetailScreen with mock Future
- All child widgets with sample data
- Loading, error, and success states

### Integration Tests
- Full navigation flow from home to detail
- Real GraphQL query (with test data)
- Pull-to-refresh functionality

## Common Pitfalls

1. **Forgetting to pass projectId** - Route expects String argument
2. **Not handling null data** - Project might not exist
3. **Missing i18n keys** - Add all keys before testing
4. **Hardcoded strings** - Use .tr() for all text
5. **Missing semantic labels** - Add for accessibility

## Quick Commands

```bash
# Create directory structure
mkdir -p lib/features/project_detail/screens lib/features/project_detail/widgets
mkdir -p test/features/project_detail/screens test/features/project_detail/widgets

# Run tests
flutter test

# Run specific test file
flutter test test/features/project_detail/screens/project_detail_screen_test.dart

# Run on device
flutter run -d <device-id>

# Analyze code
flutter analyze
```

## Design Reference

See `Requirements/ProjectDetail.jpg` for visual design specification.

## Dependencies

- Existing: flutter, graphql_flutter, cached_network_image, intl
- No new dependencies needed

## Estimated Effort

- Tests: 2 hours
- Service extension: 30 minutes
- Widgets: 1.5 hours
- Screen composition: 1 hour
- Integration & polish: 1 hour
- **Total**: ~6 hours

## Related Features

- **011-project-data**: Edit project properties (accessed from this screen)
- **012-view-products**: View product list (accessed from this screen)
- **002-home-screen-projects**: Origin of navigation
