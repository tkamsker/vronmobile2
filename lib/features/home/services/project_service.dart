import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_sort_option.dart';

/// Service for managing project data via GraphQL API
/// Based on the VRon API specification
class ProjectService {
  final GraphQLService _graphqlService;
  final String _language;

  ProjectService({GraphQLService? graphqlService, String language = 'EN'})
    : _graphqlService = graphqlService ?? GraphQLService(),
      _language = language;

  /// GraphQL query to fetch all projects for the authenticated user
  /// Based on the getProjects query from the VRon API
  /// NOTE: Project type doesn't have Product fields (status, tracksInventory, etc.)
  static const String _projectsQuery = '''
    query GetProjects(\$lang: Language!) {
      getProjects(input: {}) {
        id
        slug
        imageUrl
        isLive
        liveDate
        name {
          text(lang: \$lang)
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
  ''';

  /// GraphQL query to fetch single VR project detail
  /// Use this for project detail screen instead of filtering getProjects
  static const String _getVRProjectQuery = '''
    query GetVRProject(\$input: VRGetProjectInput!, \$lang: Language!) {
      getVRProject(input: \$input) {
        id
        slug
        name {
          text(lang: \$lang)
        }
        description {
          text(lang: \$lang)
        }
        liveDate
        isOwner
        subscription {
          isTrial
          status
          canChoosePlan
          renewalInterval
          prices {
            currency
            monthly
            yearly
          }
        }
      }
    }
  ''';

  /// GraphQL mutation to update project details
  /// Uses UpdateProject mutation with UpdateProjectDetailsInput
  static const String _updateProjectMutation = '''
    mutation UpdateProject(\$input: UpdateProjectDetailsInput!) {
      updateProjectDetails(input: \$input)
    }
  ''';

  /// GraphQL mutation to create a new project
  /// Uses createProject mutation with CreateProjectInput
  static const String _createProjectMutation = '''
    mutation CreateProject(\$data: CreateProjectInput!) {
      createProject(data: \$data) {
        id
        slug
        name {
          text(lang: EN)
        }
        description {
          text(lang: EN)
        }
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
      }
    }
  ''';

  /// Fetch all projects for the authenticated user
  /// Returns a list of Project objects or throws an exception on error
  ///
  /// [sortBy] - Optional sort option to order the results
  Future<List<Project>> fetchProjects({ProjectSortOption? sortBy}) async {
    try {
      if (kDebugMode) {
        print('📦 [PROJECTS] Fetching projects (language: $_language)...');
      }

      final result = await _graphqlService.query(
        _projectsQuery,
        variables: {'lang': _language},
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to fetch projects: ${error.message}');
        }

        throw Exception('Failed to fetch projects: ${exception.toString()}');
      }

      if (result.data == null || result.data!['getProjects'] == null) {
        if (kDebugMode) print('⚠️ [PROJECTS] No projects data in response');
        return [];
      }

      final projectsData = result.data!['getProjects'] as List;
      final projects = projectsData
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('✅ [PROJECTS] Fetched ${projects.length} projects');
        for (final project in projects) {
          print('  - ${project.name} (${project.id}) - ${project.statusLabel}');
        }
      }

      // Apply sorting if requested
      if (sortBy != null) {
        _sortProjects(projects, sortBy);
        if (kDebugMode) {
          print('📊 [PROJECTS] Applied sort: ${sortBy.name}');
        }
      }

      return projects;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch projects filtered by live status
  Future<List<Project>> fetchProjectsByLiveStatus(bool isLive) async {
    final allProjects = await fetchProjects();
    return allProjects.where((project) => project.isLive == isLive).toList();
  }

  /// Fetch projects filtered by subscription status
  Future<List<Project>> fetchProjectsBySubscriptionStatus(String status) async {
    final allProjects = await fetchProjects();
    return allProjects
        .where((project) => project.subscription.status == status)
        .toList();
  }

  /// Fetch active projects (live and with active subscription)
  Future<List<Project>> fetchActiveProjects() async {
    final allProjects = await fetchProjects();
    return allProjects
        .where((project) => project.isLive && project.subscription.isActive)
        .toList();
  }

  /// Search projects by name
  Future<List<Project>> searchProjects(String query) async {
    final allProjects = await fetchProjects();
    final lowerQuery = query.toLowerCase();
    return allProjects
        .where((project) => project.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Fetch a single project by ID with full details using getVRProject query
  /// Returns a Project object or throws an exception on error
  Future<Project> getProjectDetail(String projectId) async {
    try {
      if (kDebugMode) {
        print(
          '📦 [PROJECTS] Fetching VR project detail for ID: $projectId (language: $_language)...',
        );
      }

      // Use getVRProject query for detailed project data
      final result = await _graphqlService.query(
        _getVRProjectQuery,
        variables: {
          'input': {'id': projectId},
          'lang': _language,
        },
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to fetch project detail: ${error.message}');
        }

        throw Exception(
          'Failed to fetch project detail: ${exception.toString()}',
        );
      }

      if (result.data == null || result.data!['getVRProject'] == null) {
        if (kDebugMode) print('⚠️ [PROJECTS] No VR project data in response');
        throw Exception('Project not found: $projectId');
      }

      final projectData = result.data!['getVRProject'] as Map<String, dynamic>;

      // Convert VRProject response to Project model
      // Note: VRProject doesn't have imageUrl or isLive at root level
      final project = Project.fromJson({
        'id': projectData['id'],
        'slug': projectData['slug'],
        'name': projectData['name'],
        'description': projectData['description'],
        'imageUrl': '', // VRProject doesn't have this field
        'isLive': projectData['liveDate'] != null, // Infer from liveDate
        'liveDate': projectData['liveDate'],
        'subscription': projectData['subscription'],
      });

      if (kDebugMode) {
        print(
          '✅ [PROJECTS] Fetched VR project detail: ${project.name} (${project.id})',
        );
        print('  - Status: ${project.statusLabel}');
        print('  - Description: ${project.description}');
      }

      return project;
    } catch (e) {
      if (kDebugMode)
        print('❌ [PROJECTS] Error fetching project detail: ${e.toString()}');
      rethrow;
    }
  }

  /// Update project master data via UpdateProject mutation
  /// Uses updateProjectDetails with projectId, name, slug, and description
  /// Returns updated Project object or throws an exception on error
  Future<Project> updateProject({
    required String projectId,
    required String name,
    required String slug,
    required String description,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '📝 [PROJECTS] Updating project $projectId (language: $_language)...',
        );
        print('  - Name: $name');
        print('  - Slug: $slug');
        print('  - Description: $description');
      }

      final result = await _graphqlService.query(
        _updateProjectMutation,
        variables: {
          'input': {
            'projectId': projectId,
            'name': name,
            'slug': slug,
            'description': description,
          },
        },
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to update project: ${error.message}');
        }

        throw Exception('Failed to update project: ${exception.toString()}');
      }

      if (kDebugMode) {
        print(
          '✅ [PROJECTS] Update mutation successful, refreshing project data...',
        );
      }

      // Mutation returns just a success indicator, need to refetch the project
      final updatedProject = await getProjectDetail(projectId);

      if (kDebugMode) {
        print(
          '✅ [PROJECTS] Project updated successfully: ${updatedProject.name}',
        );
      }

      return updatedProject;
    } catch (e) {
      if (kDebugMode)
        print('❌ [PROJECTS] Error updating project: ${e.toString()}');
      rethrow;
    }
  }

  /// Create a new project
  ///
  /// [name] - Project name (required, 3-100 characters)
  /// [slug] - URL-friendly slug (required, unique)
  /// [description] - Optional project description
  ///
  /// Returns the created Project object or throws an exception on error
  ///
  /// Throws:
  /// - Exception with "already exists" if slug is duplicate (DUPLICATE_SLUG error)
  /// - Exception with validation message if input validation fails (VALIDATION_ERROR)
  /// - Exception with network/server error message for other failures
  Future<Project> createProject({
    required String name,
    required String slug,
    String? description,
  }) async {
    try {
      if (kDebugMode) {
        print('🆕 [PROJECTS] Creating project...');
        print('  - Name: $name');
        print('  - Slug: $slug');
        print('  - Description: ${description ?? "(none)"}');
      }

      final result = await _graphqlService.mutate(
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
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        // Handle duplicate slug error
        if (exception?.graphqlErrors.any(
              (e) => e.extensions?['code'] == 'DUPLICATE_SLUG',
            ) ??
            false) {
          if (kDebugMode) {
            print('❌ [PROJECTS] Duplicate slug error');
          }
          throw Exception('A project with this slug already exists');
        }

        // Handle validation errors
        if (exception?.graphqlErrors.any(
              (e) => e.extensions?['code'] == 'VALIDATION_ERROR',
            ) ??
            false) {
          final errorMessage = exception!.graphqlErrors.first.message;
          if (kDebugMode) {
            print('❌ [PROJECTS] Validation error: $errorMessage');
          }
          throw Exception(errorMessage);
        }

        // Generic error
        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to create project: ${error.message}');
        }

        throw Exception('Failed to create project: ${exception.toString()}');
      }

      if (result.data == null || result.data!['createProject'] == null) {
        if (kDebugMode)
          print('⚠️ [PROJECTS] No createProject data in response');
        throw Exception('Failed to create project: No data returned');
      }

      final projectData = result.data!['createProject'] as Map<String, dynamic>;
      final project = Project.fromJson(projectData);

      if (kDebugMode) {
        print(
          '✅ [PROJECTS] Project created successfully: ${project.name} (${project.id})',
        );
      }

      return project;
    } catch (e) {
      if (kDebugMode)
        print('❌ [PROJECTS] Error creating project: ${e.toString()}');
      rethrow;
    }
  }

  /// Sort projects list in-place according to the specified sort option
  void _sortProjects(List<Project> projects, ProjectSortOption sortBy) {
    switch (sortBy) {
      case ProjectSortOption.nameAscending:
        projects.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProjectSortOption.nameDescending:
        projects.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case ProjectSortOption.dateNewest:
        // Sort by liveDate (most recent first), treating null as oldest
        projects.sort((a, b) {
          if (a.liveDate == null && b.liveDate == null) return 0;
          if (a.liveDate == null) return 1; // null dates go last
          if (b.liveDate == null) return -1; // null dates go last
          return b.liveDate!.compareTo(a.liveDate!); // Descending
        });
        break;
      case ProjectSortOption.dateOldest:
        // Sort by liveDate (oldest first), treating null as newest
        projects.sort((a, b) {
          if (a.liveDate == null && b.liveDate == null) return 0;
          if (a.liveDate == null) return 1; // null dates go last
          if (b.liveDate == null) return -1; // null dates go last
          return a.liveDate!.compareTo(b.liveDate!); // Ascending
        });
        break;
      case ProjectSortOption.status:
        projects.sort(_compareByStatus);
        break;
    }
  }

  /// Compare projects by status priority with secondary sort by name
  ///
  /// Status priority order:
  /// 1. Live (with active subscription)
  /// 2. Live (Trial)
  /// 3. Live (Inactive)
  /// 4. Not Live
  ///
  /// Projects with same status are sorted alphabetically by name
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

    // Secondary sort by name (case-insensitive)
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
