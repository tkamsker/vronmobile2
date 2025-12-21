# Research: Project Detail Screen

**Phase 0 Output** | **Date**: 2025-12-21

## Research Tasks

Since all technical context is known (existing Flutter app with established patterns), research focuses on:
1. GraphQL query structure for project details
2. Flutter detail screen patterns
3. Image loading best practices

## Findings

### 1. GraphQL Query for Project Details

**Decision**: Extend existing ProjectService with a `project(id: ID!)` query

**Rationale**:
- The spec defines a simple GraphQL contract: `query project($id: ID!) { project(id: $id) { id name description } }`
- The existing `getProjects` query fetches list data; we need a single-project query
- The VRon API already has the project query based on the spec

**Implementation**:
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
    # Additional fields may be available - check Requirements/ReadProjects.md
  }
}
```

**Alternatives considered**:
- Using the existing `getProjects` query and filtering client-side - **Rejected**: Inefficient, fetches unnecessary data
- Creating a separate service - **Rejected**: YAGNI violation, extend existing ProjectService

---

### 2. Flutter Detail Screen Pattern

**Decision**: Use StatefulWidget with FutureBuilder pattern

**Rationale**:
- Consistent with existing home_screen.dart implementation
- FutureBuilder handles async data loading and loading states naturally
- StatefulWidget allows for local state management (loading, error, data)
- Fits Flutter's composition model

**Pattern**:
```dart
class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<Project> _projectFuture;

  @override
  void initState() {
    super.initState();
    _projectFuture = _projectService.fetchProjectDetail(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Project Detail')),
      body: FutureBuilder<Project>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error);
          }
          return _buildDetailContent(snapshot.data!);
        },
      ),
    );
  }
}
```

**Alternatives considered**:
- Provider/Riverpod for state management - **Rejected**: Overkill for simple fetch-and-display
- Bloc pattern - **Rejected**: Too heavy for this simple screen, violates YAGNI
- StatelessWidget with dependency injection - **Rejected**: Less clear for async operations

---

### 3. Image Loading Best Practices

**Decision**: Use cached_network_image with progressive placeholders

**Rationale**:
- Already in use in project_card.dart (home screen)
- Provides automatic caching, placeholder, and error handling
- Optimizes network usage and improves perceived performance
- Consistent with existing patterns

**Implementation**:
```dart
CachedNetworkImage(
  imageUrl: project.imageUrl,
  placeholder: (context, url) => Container(
    color: Colors.grey[200],
    child: Center(child: CircularProgressIndicator()),
  ),
  errorWidget: (context, url, error) => Container(
    color: Colors.grey[200],
    child: Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
  ),
  fit: BoxFit.cover,
)
```

**Alternatives considered**:
- Image.network directly - **Rejected**: No caching, poor UX during load
- Custom caching solution - **Rejected**: Reinventing the wheel, YAGNI violation

---

### 4. Navigation Integration

**Decision**: Update existing home_screen.dart navigation handler

**Rationale**:
- Navigation is already wired up via `_handleProjectTap(String projectId)`
- Route is already defined in routes.dart as `AppRoutes.projectDetail`
- Just need to replace PlaceholderScreen with ProjectDetailScreen in main.dart

**Implementation**:
```dart
// In main.dart routes:
AppRoutes.projectDetail: (context) {
  final projectId = ModalRoute.of(context)?.settings.arguments as String?;
  if (projectId == null) {
    return const PlaceholderScreen(title: 'Project Detail - Missing ID');
  }
  return ProjectDetailScreen(projectId: projectId);
},
```

**Alternatives considered**:
- Named routes with parameters - **Current implementation is sufficient**
- GoRouter or other routing package - **Rejected**: YAGNI, built-in routing works fine

---

### 5. Internationalization

**Decision**: Follow existing i18n pattern with .tr() extension

**Rationale**:
- i18n_service already implemented and working
- Consistent with home screen and profile screen implementations
- Translation keys follow predictable structure: `projectDetail.title`, `projectDetail.noData`, etc.

**New Translation Keys Required**:
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

---

## Summary

All research complete. No unknowns or clarifications needed:

✅ **GraphQL Query**: Extend ProjectService with `project(id: ID!)` query
✅ **Screen Pattern**: StatefulWidget + FutureBuilder (consistent with existing code)
✅ **Image Loading**: cached_network_image (already in use)
✅ **Navigation**: Update main.dart route handler (already wired)
✅ **i18n**: Follow existing .tr() pattern (add new keys)

**No blocking issues. Ready to proceed to Phase 1: Design & Contracts.**
