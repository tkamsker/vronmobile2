import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_request.dart';

void main() {
  group('RoomStitchRequest', () {
    group('isValid()', () {
      test('returns false when less than 2 scans provided', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001'], // Only 1 scan
        );

        expect(request.isValid(), false);
      });

      test('returns false when scanIds is empty', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: [], // No scans
        );

        expect(request.isValid(), false);
      });

      test('returns false when projectId is empty', () {
        final request = RoomStitchRequest(
          projectId: '', // Empty project ID
          scanIds: ['scan-001', 'scan-002'],
        );

        expect(request.isValid(), false);
      });

      test('returns true when 2 or more scans provided with valid projectId', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
        );

        expect(request.isValid(), true);
      });

      test('returns true when 10 scans provided (maximum)', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: List.generate(10, (i) => 'scan-${i + 1}'),
        );

        expect(request.isValid(), true);
      });
    });

    group('generateFilename()', () {
      test('includes room names when provided', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Master Bedroom',
          },
        );

        final filename = request.generateFilename();

        expect(filename, contains('living-room'));
        expect(filename, contains('master-bedroom'));
        expect(filename, endsWith('.glb')); // Default format
      });

      test('sanitizes room names by replacing spaces with hyphens', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Kitchen Dining',
          },
        );

        final filename = request.generateFilename();

        expect(filename, contains('living-room'));
        expect(filename, contains('kitchen-dining'));
        expect(filename, isNot(contains('Living Room'))); // No spaces
      });

      test('includes scan count when no room names provided', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002', 'scan-003'],
        );

        final filename = request.generateFilename();

        expect(filename, contains('3-rooms'));
        expect(filename, contains('stitched-'));
      });

      test('includes current date in ISO format', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
        );

        final filename = request.generateFilename();
        final today = DateTime.now().toIso8601String().split('T')[0];

        expect(filename, contains(today)); // YYYY-MM-DD format
      });

      test('uses .usdz extension when outputFormat is USDZ', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          outputFormat: OutputFormat.usdz,
        );

        final filename = request.generateFilename();

        expect(filename, endsWith('.usdz'));
      });

      test('uses .glb extension when outputFormat is GLB (default)', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          outputFormat: OutputFormat.glb,
        );

        final filename = request.generateFilename();

        expect(filename, endsWith('.glb'));
      });

      test('removes special characters from room names', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          roomNames: {
            'scan-001': 'Kitchen/Dining',
            'scan-002': 'Master Bedroom #1',
          },
        );

        final filename = request.generateFilename();

        expect(filename, isNot(contains('/')));
        expect(filename, isNot(contains('#')));
      });
    });

    group('toGraphQLVariables()', () {
      test('converts request to GraphQL variables with all fields', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002', 'scan-003'],
          alignmentMode: AlignmentMode.auto,
          outputFormat: OutputFormat.glb,
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Master Bedroom',
            'scan-003': 'Kitchen',
          },
        );

        final variables = request.toGraphQLVariables();

        expect(variables, isA<Map<String, dynamic>>());
        expect(variables['input'], isNotNull);
        expect(variables['input']['projectId'], 'proj-001');
        expect(variables['input']['scanIds'], ['scan-001', 'scan-002', 'scan-003']);
        expect(variables['input']['alignmentMode'], 'AUTO');
        expect(variables['input']['outputFormat'], 'GLB');
      });

      test('includes roomNames array when provided', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Kitchen',
          },
        );

        final variables = request.toGraphQLVariables();

        expect(variables['input']['roomNames'], isNotNull);
        expect(variables['input']['roomNames'], isA<List>());
        expect(variables['input']['roomNames'].length, 2);

        final roomNamesArray = variables['input']['roomNames'] as List;
        expect(roomNamesArray[0]['scanId'], 'scan-001');
        expect(roomNamesArray[0]['name'], 'Living Room');
        expect(roomNamesArray[1]['scanId'], 'scan-002');
        expect(roomNamesArray[1]['name'], 'Kitchen');
      });

      test('omits roomNames when not provided', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
        );

        final variables = request.toGraphQLVariables();

        expect(variables['input']['roomNames'], isNull);
      });

      test('converts alignmentMode enum to uppercase string', () {
        final autoRequest = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          alignmentMode: AlignmentMode.auto,
        );

        final manualRequest = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          alignmentMode: AlignmentMode.manual,
        );

        expect(autoRequest.toGraphQLVariables()['input']['alignmentMode'], 'AUTO');
        expect(manualRequest.toGraphQLVariables()['input']['alignmentMode'], 'MANUAL');
      });

      test('converts outputFormat enum to uppercase string', () {
        final glbRequest = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          outputFormat: OutputFormat.glb,
        );

        final usdzRequest = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          outputFormat: OutputFormat.usdz,
        );

        expect(glbRequest.toGraphQLVariables()['input']['outputFormat'], 'GLB');
        expect(usdzRequest.toGraphQLVariables()['input']['outputFormat'], 'USDZ');
      });
    });

    group('JSON serialization', () {
      test('toJson() serializes all fields correctly', () {
        final request = RoomStitchRequest(
          projectId: 'proj-001',
          scanIds: ['scan-001', 'scan-002'],
          alignmentMode: AlignmentMode.auto,
          outputFormat: OutputFormat.glb,
          roomNames: {'scan-001': 'Living Room'},
        );

        final json = request.toJson();

        expect(json['projectId'], 'proj-001');
        expect(json['scanIds'], ['scan-001', 'scan-002']);
        expect(json['alignmentMode'], isNotNull);
        expect(json['outputFormat'], isNotNull);
        expect(json['roomNames'], isNotNull);
      });

      test('fromJson() deserializes correctly', () {
        final json = {
          'projectId': 'proj-001',
          'scanIds': ['scan-001', 'scan-002'],
          'alignmentMode': 'auto',
          'outputFormat': 'glb',
          'roomNames': {'scan-001': 'Living Room'},
        };

        final request = RoomStitchRequest.fromJson(json);

        expect(request.projectId, 'proj-001');
        expect(request.scanIds, ['scan-001', 'scan-002']);
        expect(request.alignmentMode, AlignmentMode.auto);
        expect(request.outputFormat, OutputFormat.glb);
        expect(request.roomNames, {'scan-001': 'Living Room'});
      });
    });
  });
}
