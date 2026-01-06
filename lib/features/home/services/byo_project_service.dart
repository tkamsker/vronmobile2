import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/services/token_storage.dart';

/// Service for creating BYO (Bring Your Own) projects
/// Uses VRonCreateProjectFromOwnWorld mutation to create project with GLB files
class BYOProjectService {
  final TokenStorage _tokenStorage;
  final String _graphqlEndpoint;

  BYOProjectService({
    TokenStorage? tokenStorage,
    String? graphqlEndpoint,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _graphqlEndpoint = graphqlEndpoint ?? EnvConfig.graphqlEndpoint;

  /// Creates a BYO project with world and mesh GLB files
  ///
  /// [worldFile] - GLB file for the 3D world model
  /// [meshFile] - GLB file for navigation mesh
  ///
  /// Returns the created project ID and world ID
  ///
  /// Throws Exception if creation fails
  ///
  /// Note: Backend auto-generates project name from uploaded files
  Future<BYOProjectResult> createProjectFromOwnWorld({
    required File worldFile,
    required File meshFile,
  }) async {
    try {
      if (kDebugMode) {
        print('📦 [BYO] Creating BYO project from GLB files');
        print('📦 [BYO] World file: ${worldFile.path} (${await worldFile.length()} bytes)');
        print('📦 [BYO] Mesh file: ${meshFile.path} (${await meshFile.length()} bytes)');
      }

      // Get auth code (base64 encoded auth payload)
      final authCode = await _tokenStorage.getAuthCode();
      if (authCode == null || authCode.isEmpty) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse(_graphqlEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // GraphQL mutation - matches backend VRonCreateProjectFromOwnWorldInput
      // Note: Backend only returns projectId (worldId not in response type)
      const mutation = '''
        mutation VRonCreateProjectFromOwnWorld(\$input: VRonCreateProjectFromOwnWorldInput!) {
          VRonCreateProjectFromOwnWorld(input: \$input) {
            projectId
          }
        }
      ''';

      // Variables - backend only expects world and mesh files
      final variables = {
        'input': {
          'world': null,
          'mesh': null,
        }
      };

      // Operations field (GraphQL query + variables)
      request.fields['operations'] = json.encode({
        'query': mutation,
        'variables': variables,
      });

      // Map field (maps files to variables)
      final map = {
        'world': ['variables.input.world'],
        'mesh': ['variables.input.mesh'],
      };
      request.fields['map'] = json.encode(map);

      // Add world file
      request.files.add(http.MultipartFile(
        'world',
        worldFile.readAsBytes().asStream(),
        await worldFile.length(),
        filename: worldFile.path.split('/').last,
        contentType: MediaType('model', 'gltf-binary'),
      ));

      // Add mesh file
      request.files.add(http.MultipartFile(
        'mesh',
        meshFile.readAsBytes().asStream(),
        await meshFile.length(),
        filename: meshFile.path.split('/').last,
        contentType: MediaType('model', 'gltf-binary'),
      ));

      // Add headers
      request.headers['Authorization'] = 'Bearer $authCode';
      request.headers['X-VRon-Platform'] = 'merchants';
      request.headers['apollo-require-preflight'] = 'true';

      // Send request
      if (kDebugMode) {
        print('📦 [BYO] Sending multipart request to $uri');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('📦 [BYO] Response status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to create project: ${response.statusCode} $responseBody',
        );
      }

      final jsonResponse = json.decode(responseBody);

      // Check for GraphQL errors
      if (jsonResponse['errors'] != null) {
        final errors = jsonResponse['errors'] as List;
        final errorMessage = errors.isNotEmpty
            ? errors[0]['message']
            : 'Unknown GraphQL error';

        if (kDebugMode) {
          print('❌ [BYO] GraphQL Error: $errorMessage');
          print('❌ [BYO] Full errors: ${json.encode(errors)}');
        }

        // Check if mutation doesn't exist
        if (errorMessage.toString().contains('Cannot query field') ||
            errorMessage.toString().contains('Unknown type')) {
          throw Exception(
            'VRonCreateProjectFromOwnWorld mutation not implemented on backend. '
            'Please contact backend team to implement this mutation.',
          );
        }

        throw Exception('GraphQL Error: $errorMessage');
      }

      // Extract result
      final data = jsonResponse['data'];
      if (data == null || data['VRonCreateProjectFromOwnWorld'] == null) {
        throw Exception('No data returned from mutation');
      }

      final result = data['VRonCreateProjectFromOwnWorld'];
      final projectId = result['projectId'] as String;

      if (kDebugMode) {
        print('✅ [BYO] Project created successfully');
        print('✅ [BYO] Project ID: $projectId');
      }

      return BYOProjectResult(
        projectId: projectId,
        worldId: null, // Backend doesn't return worldId
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [BYO] Error creating BYO project: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Validates a slug before creation
  /// Returns true if slug is valid, false otherwise
  bool validateSlug(String slug) {
    // Must be lowercase, alphanumeric with hyphens
    final slugRegex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
    return slugRegex.hasMatch(slug);
  }

  /// Generates a slug from a name
  String generateSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

/// Result from creating a BYO project
class BYOProjectResult {
  final String projectId;
  final String? worldId;

  const BYOProjectResult({
    required this.projectId,
    this.worldId,
  });

  @override
  String toString() => 'BYOProjectResult(projectId: $projectId, worldId: $worldId)';
}
