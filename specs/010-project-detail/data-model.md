# Data Model: Project Detail Screen

**Phase 1 Output** | **Date**: 2025-12-21

## Entities

### Project (Existing - Reused)

**Location**: `lib/features/home/models/project.dart`

**Status**: Already exists, no modifications needed

**Fields**:
```dart
class Project {
  final String id;
  final String slug;
  final String name;              // I18NField text
  final String imageUrl;
  final bool isLive;
  final DateTime? liveDate;
  final ProjectSubscription subscription;

  // Computed properties
  String get statusLabel;
  String get statusColorHex;
  String get shortDescription;
  String get teamInfo;
}
```

**Relationships**:
- Has one `ProjectSubscription`

**Validation**: None (read-only data from API)

**State Transitions**: N/A (no local state changes)

---

### ProjectSubscription (Existing - Reused)

**Location**: `lib/features/home/models/project_subscription.dart`

**Status**: Already exists, no modifications needed

**Fields**:
```dart
class ProjectSubscription {
  final bool isActive;
  final bool isTrial;
  final String status;
  final bool canChoosePlan;
  final bool hasExpired;
  final String? currency;
  final double? price;
  final String? renewalInterval;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? renewsAt;
  final ProjectSubscriptionPrices prices;

  // Computed properties
  String get statusLabel;
  String get statusColorHex;
}
```

**Relationships**:
- Has one `ProjectSubscriptionPrices`

**Validation**: None (read-only data from API)

---

## Screen State

### ProjectDetailScreen State

**State Variables**:
```dart
class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<Project> _projectFuture;

  // Navigation state (no local storage)
  String get projectId => widget.projectId;
}
```

**State Flow**:
1. **Initial**: `initState()` calls `_projectService.fetchProjectDetail(projectId)`
2. **Loading**: FutureBuilder shows CircularProgressIndicator
3. **Success**: FutureBuilder builds detail UI with project data
4. **Error**: FutureBuilder shows error UI with retry button
5. **Retry**: Pressing retry button calls `setState()` and re-fetches

**State Diagram**:
```
[Initial] → [Loading] → [Success] ↔ [Error]
                            ↓           ↓
                        [Navigate]  [Retry] → [Loading]
```

---

## Service Extension

### ProjectService.fetchProjectDetail

**Location**: `lib/features/home/services/project_service.dart`

**New Method**:
```dart
Future<Project> fetchProjectDetail(String projectId) async {
  final queryOptions = QueryOptions(
    document: gql(_getProjectDetailQuery),
    variables: {
      'id': projectId,
      'lang': 'EN', // TODO: Use i18n service current language
    },
  );

  final result = await _graphQLService.query(queryOptions);

  if (result.hasException) {
    throw result.exception!;
  }

  final projectData = result.data?['project'];
  if (projectData == null) {
    throw Exception('Project not found');
  }

  return Project.fromJson(projectData);
}
```

**Error Handling**:
- GraphQL exception → throws exception (caught by FutureBuilder)
- Null data → throws "Project not found" exception
- Network timeout → throws GraphQL timeout exception

---

## No New Models Required

All data models already exist and are sufficient for this feature:
- ✅ Project model has all needed fields
- ✅ ProjectSubscription model has all needed fields
- ✅ No new entities needed per spec requirements

**Rationale**: The spec only requires displaying project name, description, and details. The existing Project model already contains all this data from the getProjects query. The detail query returns the same structure, just for a single project.
