# Research: Project Detail and Data Management

**Date**: 2025-12-21
**Status**: Completed

## 1. GraphQL Schema Discovery

**Decision**: The `project(id: ID!)` query will return the same core fields as `getProjects` plus a `description` field. Based on the existing query pattern, the structure is:

```graphql
query getProjectDetail($id: ID!, $lang: Language!) {
  project(id: $id) {
    id
    slug
    imageUrl
    isLive
    liveDate
    name {
      text(lang: $lang)
    }
    description {
      text(lang: $lang)
    }
    subscription {
      isActive
      isTrial
      status
      canChoosePlan
      hasExpired
      currency
      price
      renewalInterval
      startedAt
      expiresAt
      renewsAt
      prices {
        currency
        monthly
        yearly
      }
    }
  }
}
```

**Rationale**: The existing `getProjects` query uses I18NField structures for name (with `text(lang: $lang)` accessor). Following the same pattern for description ensures consistency. The query returns all subscription details needed for status badges and display.

**Alternatives Considered**:
1. Fetch description separately with a second query - Rejected: Increases network requests and complexity
2. Use flat string fields instead of I18NField - Rejected: Inconsistent with existing API patterns
3. Create a new `getProjectWithDescription` query - Rejected: Unnecessary when backend likely supports description field on existing project query

**Implementation Note**: The existing Project model parser already handles I18NField structures (see project.dart:28-36), so extending it for description field is straightforward.

---

## 2. Update Mutation Schema

**Decision**: The `updateProject` mutation signature will follow this pattern:

```graphql
mutation updateProject($id: ID!, $data: UpdateProjectInput!) {
  updateProject(id: $id, data: $data) {
    id
    slug
    imageUrl
    name {
      text(lang: EN)
    }
    description {
      text(lang: EN)
    }
  }
}

input UpdateProjectInput {
  name: String
  slug: String
  description: String
}
```

**Rationale**: This follows RESTful/GraphQL best practices where update operations accept an input object with optional fields. Only provided fields will be updated. The mutation returns the updated project data to allow immediate UI refresh without a separate query.

**Alternatives Considered**:
1. Separate mutations for each field (`updateProjectName`, `updateProjectSlug`, etc.) - Rejected: Too granular, requires multiple network calls for multi-field updates
2. Positional parameters (`updateProject($id: ID!, $name: String, $slug: String, ...)`) - Rejected: Less flexible, harder to extend in future
3. Patch-style update with JSON object - Rejected: Less type-safe, harder to validate

**Backend Assumption**: The mutation will validate that slug is unique across projects for the authenticated user. Client-side validation will pre-check format but server will enforce uniqueness.

---

## 3. Form Validation Rules

**Decision**: Based on typical web app constraints and UI requirements from Figma, validation rules are:

| Field | Required | Min Length | Max Length | Format | Notes |
|-------|----------|------------|------------|--------|-------|
| Name | Yes | 1 | 100 | Any Unicode | User-facing project name |
| Slug | Yes | 3 | 50 | Lowercase alphanumeric + hyphens | Used in URLs, must be unique |
| Description | No | 0 | 500 | Any Unicode | Optional long-form text |

**Slug Format Rules**:
- Must start with a letter or number
- Can contain lowercase letters (a-z), numbers (0-9), and hyphens (-)
- Cannot start or end with a hyphen
- No consecutive hyphens
- Auto-converted to lowercase on blur

**Rationale**: These constraints balance user flexibility with system requirements:
- 100-char name limit prevents UI layout issues
- 50-char slug limit ensures URLs remain manageable
- 500-char description supports substantial context without becoming unwieldy
- Slug format ensures URL-safe and readable identifiers

**Alternatives Considered**:
1. No slug field (auto-generate from name) - Rejected: Users need control over URLs for SEO/branding
2. Allow uppercase in slugs - Rejected: Leads to case-sensitivity confusion in URLs
3. Allow spaces in slugs - Rejected: Requires URL encoding, less user-friendly

**Error Messages**:
- Name empty: "Project name is required"
- Name too long: "Project name must be 100 characters or less"
- Slug empty: "Slug is required"
- Slug too short: "Slug must be at least 3 characters"
- Slug too long: "Slug must be 50 characters or less"
- Slug invalid format: "Slug can only contain lowercase letters, numbers, and hyphens"
- Description too long: "Description must be 500 characters or less"

---

## 4. Tab Navigation Pattern

**Decision**: Use Flutter's TabBarView with TabController and AutomaticKeepAliveClientMixin for state preservation.

**Implementation Approach**:

```dart
class ProjectDetailScreen extends StatefulWidget {
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Viewer'),
            Tab(text: 'Project data'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProjectViewerTab(),
          ProjectDataTab(),
          ProjectProductsTab(),
        ],
      ),
    );
  }
}

// Each tab widget uses AutomaticKeepAliveClientMixin:
class ProjectDataTab extends StatefulWidget {
  @override
  State<ProjectDataTab> createState() => _ProjectDataTabState();
}

class _ProjectDataTabState extends State<ProjectDataTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;  // Preserves state across tab switches

  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required by AutomaticKeepAliveClientMixin
    // ... tab content
  }
}
```

**Rationale**:
- TabController manages tab state and provides smooth animations
- SingleTickerProviderStateMixin provides vsync for TabController animations
- AutomaticKeepAliveClientMixin preserves tab state when switching tabs (critical for edit form)
- This pattern prevents loss of unsaved edits when user switches tabs temporarily

**Alternatives Considered**:
1. Manual PageView with GestureDetector - Rejected: Reinventing Flutter's built-in tab system
2. Separate routes for each tab - Rejected: Breaks tab navigation UX, complicates state sharing
3. No state preservation (rebuild on tab switch) - Rejected: Loses unsaved form edits

**Testing Note**: Widget tests will verify tab switching preserves form state by:
1. Enter text in Project data tab
2. Switch to Viewer tab
3. Switch back to Project data tab
4. Verify entered text still present

---

## 5. Error Handling Patterns

**Decision**: Consistent error handling pattern based on existing implementation in project_service.dart:

```dart
Future<Project> getProjectDetail(String projectId) async {
  try {
    final result = await _graphqlService.query(
      _projectDetailQuery,
      variables: {'id': projectId, 'lang': _language},
    );

    if (result.hasException) {
      final exception = result.exception;
      if (exception?.graphqlErrors.isNotEmpty ?? false) {
        final error = exception!.graphqlErrors.first;
        throw Exception('Failed to fetch project: ${error.message}');
      }
      throw Exception('Failed to fetch project: ${exception.toString()}');
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
```

**UI Error Display**:
- Use SnackBar for transient errors: `ScaffoldMessenger.of(context).showSnackBar(...)`
- Show retry button for failed operations
- Preserve user edits on save failure
- Display user-friendly messages (not raw exceptions)

**User-Friendly Error Messages**:
- Network/timeout errors: "Unable to connect. Please check your internet connection and try again."
- Authentication errors: "Your session has expired. Please log in again."
- Validation errors from server: Display server message directly
- Generic errors: "Something went wrong. Please try again."
- Project not found: "This project could not be found. It may have been deleted."

**Rationale**: Consistency with existing error handling in project_service.dart ensures maintainability. SnackBar provides non-intrusive error feedback that doesn't block UI.

**Alternatives Considered**:
1. AlertDialog for all errors - Rejected: Too intrusive, requires user dismissal
2. Inline error text in form - Accepted for validation errors, but not for network errors
3. Toast library - Rejected: SnackBar is built into Material Design, no extra dependency

---

## 6. Navigation Integration

**Decision**: Extend existing routes.dart pattern and use Navigator.pushNamed with arguments:

**Route Updates** (`lib/core/navigation/routes.dart`):
```dart
class AppRoutes {
  // ... existing routes ...

  // Project routes (updated)
  static const String projectDetail = '/project-detail';  // Existing, now functional
  static const String createProject = '/create-project';  // Existing placeholder
}
```

**Navigation from Project List** (`project_card.dart`):
```dart
onTap: () {
  Navigator.pushNamed(
    context,
    AppRoutes.projectDetail,
    arguments: {'projectId': project.id},
  );
}
```

**Receiving Arguments** (`project_detail_screen.dart`):
```dart
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late String projectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    projectId = args['projectId'] as String;
  }

  // ... rest of implementation
}
```

**Route Registration** (`main.dart`):
```dart
MaterialApp(
  routes: {
    AppRoutes.main: (context) => const MainScreen(),
    AppRoutes.home: (context) => const HomeScreen(),
    AppRoutes.projectDetail: (context) => const ProjectDetailScreen(),
    AppRoutes.profile: (context) => const ProfileScreen(),
    AppRoutes.language: (context) => const LanguageScreen(),
    // ... other routes
  },
);
```

**Rationale**: Uses existing named route pattern. Arguments passed via Map allow flexible parameter passing. Tab navigation is internal to ProjectDetailScreen, not separate routes.

**Alternatives Considered**:
1. Generate routes with onGenerateRoute for parameter parsing - Rejected: Overkill for simple ID passing
2. Separate routes for each tab (`/project/:id/viewer`, `/project/:id/data`) - Rejected: Breaks tab UX, complicates state management
3. Global state for selected project - Rejected: Violates Flutter's reactive architecture, harder to test

**Back Navigation**:
- Android back button: Handled automatically by Navigator
- iOS back swipe: Handled automatically by Cupertino navigation
- AppBar back button: Uses Navigator.pop() (automatic)

---

## Summary & Implementation Readiness

All research questions have been resolved with concrete decisions:

✅ GraphQL schema patterns identified (I18NField structure for name/description)
✅ Update mutation signature defined (UpdateProjectInput with optional fields)
✅ Form validation rules specified (name: 1-100, slug: 3-50, description: 0-500)
✅ Tab navigation pattern selected (TabBarView with state preservation)
✅ Error handling standardized (consistent with existing service patterns)
✅ Navigation integration designed (named routes with arguments)

**No Blocking Issues**: All patterns follow existing codebase conventions. No new dependencies required. All Flutter APIs are well-documented and stable.

**Ready for Phase 1**: Data model design, API contracts, and component specifications can now proceed with confidence.
