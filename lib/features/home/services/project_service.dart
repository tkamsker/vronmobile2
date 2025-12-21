import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';

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

  /// GraphQL mutation to update project (actually a Product in backend)
  /// Per ProjectMutation.md: Projects are implemented as Products in the backend
  /// Uses VRonUpdateProduct mutation with title field (not name)
  static const String _updateProjectMutation = '''
    mutation UpdateProduct(\$input: VRonUpdateProductInput!) {
      VRonUpdateProduct(input: \$input)
    }
  ''';

  /// Fetch all projects for the authenticated user
  /// Returns a list of Project objects or throws an exception on error
  Future<List<Project>> fetchProjects() async {
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
        print('📦 [PROJECTS] Fetching VR project detail for ID: $projectId (language: $_language)...');
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

        throw Exception('Failed to fetch project detail: ${exception.toString()}');
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
        print('✅ [PROJECTS] Fetched VR project detail: ${project.name} (${project.id})');
        print('  - Status: ${project.statusLabel}');
        print('  - Description: ${project.description}');
      }

      return project;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error fetching project detail: ${e.toString()}');
      rethrow;
    }
  }

  /// Update project master data via VRonUpdateProduct mutation
  /// Per ProjectMutation.md: Projects are Products in backend, name→title mapping
  /// Returns updated Project object or throws an exception on error
  Future<Project> updateProject({
    required String projectId,
    required String name,
    required String description,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 [PROJECTS] Updating project/product $projectId (language: $_language)...');
        print('  - Title (name): $name');
        print('  - Description: $description');
      }

      // Try mutation with minimal fields first
      // Backend may support partial updates (only id, title, description)
      if (kDebugMode) {
        print('📦 [PROJECTS] Attempting update with minimal fields...');
      }

      final result = await _graphqlService.query(
        _updateProjectMutation,
        variables: {
          'input': {
            'id': projectId,
            'title': name, // name field maps to title in backend
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
        print('✅ [PROJECTS] Update mutation successful, refreshing project data...');
      }

      // Mutation returns just a success indicator, need to refetch the project
      final updatedProject = await getProjectDetail(projectId);

      if (kDebugMode) {
        print('✅ [PROJECTS] Project updated successfully: ${updatedProject.name}');
      }

      return updatedProject;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error updating project: ${e.toString()}');
      rethrow;
    }
  }
}
