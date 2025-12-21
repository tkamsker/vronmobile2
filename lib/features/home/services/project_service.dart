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
  /// NOTE: Backend doesn't support 'description' field yet - it will default to empty string
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

  /// Fetch a single project by ID with full details
  /// Returns a Project object or throws an exception on error
  /// Note: Backend doesn't have a single project query, so we fetch all and filter
  Future<Project> getProjectDetail(String projectId) async {
    try {
      if (kDebugMode) {
        print('📦 [PROJECTS] Fetching project detail for ID: $projectId (language: $_language)...');
      }

      // Backend doesn't have project(id) query, use getProjects and filter
      final allProjects = await fetchProjects();

      final project = allProjects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found: $projectId'),
      );

      if (kDebugMode) {
        print('✅ [PROJECTS] Fetched project detail: ${project.name} (${project.id})');
        print('  - Status: ${project.statusLabel}');
        print('  - Description: ${project.description}');
      }

      return project;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error fetching project detail: ${e.toString()}');
      rethrow;
    }
  }

  /// Update project master data (NOT AVAILABLE - backend doesn't support it)
  /// This is a placeholder method - backend doesn't have updateProject mutation
  /// Throws exception indicating feature is not available
  Future<Project> updateProject({
    required String projectId,
    required String name,
    required String description,
  }) async {
    if (kDebugMode) {
      print('⚠️ [PROJECTS] Update project called but NOT AVAILABLE in backend');
      print('  - Project ID: $projectId');
      print('  - Requested name: $name');
      print('  - Requested description: $description');
    }

    // Backend doesn't support project updates yet
    throw Exception(
      'Project updates are not available yet. '
      'The backend API doesn\'t support the updateProject mutation. '
      'Please contact support to enable this feature.'
    );
  }
}
