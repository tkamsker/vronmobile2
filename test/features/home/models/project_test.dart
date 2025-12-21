import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_status.dart';

void main() {
  group('Project Model', () {
    final testDate = DateTime.parse('2025-12-20T10:30:00Z');

    test('creates Project from valid JSON', () {
      final json = {
        'id': 'proj_123',
        'title': 'Marketing Analytics',
        'description': 'Realtime overview of campaign performance.',
        'status': 'active',
        'imageUrl': 'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
        'updatedAt': '2025-12-20T10:30:00Z',
        'teamInfo': '4 teammates',
      };

      final project = Project.fromJson(json);

      expect(project.id, 'proj_123');
      expect(project.title, 'Marketing Analytics');
      expect(project.description, 'Realtime overview of campaign performance.');
      expect(project.status, ProjectStatus.active);
      expect(
        project.imageUrl,
        'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
      );
      expect(project.updatedAt, testDate);
      expect(project.teamInfo, '4 teammates');
    });

    test('creates Project from JSON with missing optional fields', () {
      final json = {'id': 'proj_456', 'title': 'Product Roadmap'};

      final project = Project.fromJson(json);

      expect(project.id, 'proj_456');
      expect(project.title, 'Product Roadmap');
      expect(project.description, '');
      expect(project.status, ProjectStatus.active);
      expect(project.imageUrl, '');
      expect(project.teamInfo, '');
    });

    test('converts Project to JSON', () {
      final project = Project(
        id: 'proj_789',
        title: 'Mobile UX Refresh',
        description: 'Iterating on onboarding and nav patterns.',
        status: ProjectStatus.paused,
        imageUrl: 'https://cdn.vron.one/projects/proj_789/thumbnail.jpg',
        updatedAt: testDate,
        teamInfo: 'Solo',
      );

      final json = project.toJson();

      expect(json['id'], 'proj_789');
      expect(json['title'], 'Mobile UX Refresh');
      expect(json['description'], 'Iterating on onboarding and nav patterns.');
      expect(json['status'], 'paused');
      expect(
        json['imageUrl'],
        'https://cdn.vron.one/projects/proj_789/thumbnail.jpg',
      );
      expect(json['updatedAt'], '2025-12-20T10:30:00.000Z');
      expect(json['teamInfo'], 'Solo');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Project(
        id: 'proj_001',
        title: 'Original Title',
        description: 'Original description',
        status: ProjectStatus.active,
        imageUrl: 'https://example.com/image.jpg',
        updatedAt: testDate,
        teamInfo: '5 teammates',
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        status: ProjectStatus.archived,
      );

      expect(updated.id, 'proj_001');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Original description');
      expect(updated.status, ProjectStatus.archived);
      expect(updated.imageUrl, 'https://example.com/image.jpg');
      expect(updated.updatedAt, testDate);
      expect(updated.teamInfo, '5 teammates');
    });

    test('equality works correctly', () {
      final project1 = Project(
        id: 'proj_001',
        title: 'Test Project',
        description: 'Description',
        status: ProjectStatus.active,
        imageUrl: 'https://example.com/image.jpg',
        updatedAt: testDate,
        teamInfo: '3 teammates',
      );

      final project2 = Project(
        id: 'proj_001',
        title: 'Test Project',
        description: 'Description',
        status: ProjectStatus.active,
        imageUrl: 'https://example.com/image.jpg',
        updatedAt: testDate,
        teamInfo: '3 teammates',
      );

      final project3 = Project(
        id: 'proj_002',
        title: 'Different Project',
        description: 'Description',
        status: ProjectStatus.active,
        imageUrl: 'https://example.com/image.jpg',
        updatedAt: testDate,
        teamInfo: '3 teammates',
      );

      expect(project1, equals(project2));
      expect(project1, isNot(equals(project3)));
      expect(project1.hashCode, equals(project2.hashCode));
    });

    test('toString returns readable format', () {
      final project = Project(
        id: 'proj_123',
        title: 'Test Project',
        description: 'Description',
        status: ProjectStatus.active,
        imageUrl: 'https://example.com/image.jpg',
        updatedAt: testDate,
        teamInfo: '2 teammates',
      );

      final result = project.toString();

      expect(result, contains('proj_123'));
      expect(result, contains('Test Project'));
      expect(result, contains('Active'));
    });
  });
}
