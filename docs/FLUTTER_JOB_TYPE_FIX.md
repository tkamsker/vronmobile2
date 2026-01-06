# Flutter Job Type Field Fix

## Problem

**Error**: `422 Unprocessable Entity`
```json
{
  "detail": [{
    "type": "missing",
    "loc": ["body", "job_type"],
    "msg": "Field required"
  }]
}
```

The request body is missing the required `job_type` field when calling the convert endpoint.

## Solution

The `/sessions/{session_id}/convert` endpoint **requires** the `job_type` field in the request body. It must be set to `"usdz_to_glb"` for USDZ to GLB conversion.

### ✅ Correct Implementation

```dart
Future<Map<String, dynamic>> convertUsdzToGlb(
  String sessionId,
  String inputFilename, {
  String? outputFilename,
  Map<String, dynamic>? conversionParams,
}) async {
  final response = await http.post(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/convert'),
    headers: {
      'X-API-Key': apiKey,
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'job_type': 'usdz_to_glb', // ✅ REQUIRED FIELD
      'input_filename': inputFilename,
      if (outputFilename != null) 'output_filename': outputFilename,
      if (conversionParams != null) 'conversion_params': conversionParams,
    }),
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to start conversion: ${response.body}');
  }
}
```

### ❌ Common Mistake

```dart
// ❌ WRONG - Missing job_type field
body: json.encode({
  'input_filename': inputFilename,
  'output_filename': outputFilename,
  'conversion_params': conversionParams,
}),
```

### ✅ Correct Request Body Format

```json
{
  "job_type": "usdz_to_glb",
  "input_filename": "scan_scan-1767021054366-54366.usdz",
  "output_filename": "scan_scan-1767021054366-54366.glb",
  "conversion_params": {
    "apply_scale": false,
    "merge_meshes": false,
    "target_scale": 1.0
  }
}
```

## Complete Working Example

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BlenderApiClient {
  final String baseUrl = 'https://blenderapi.stage.motorenflug.at';
  final String apiKey;
  
  BlenderApiClient(this.apiKey);
  
  // Create session
  Future<Map<String, dynamic>> createSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create session: ${response.body}');
    }
  }
  
  // Upload file
  Future<Map<String, dynamic>> uploadFile(
    String sessionId,
    File file,
    String assetType,
  ) async {
    final fileBytes = await file.readAsBytes();
    
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/upload'),
      headers: {
        'X-API-Key': apiKey,
        'X-Asset-Type': assetType,
        'X-Filename': file.path.split('/').last,
        'Content-Type': 'application/octet-stream',
      },
      body: fileBytes,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }
  
  // ✅ Convert USDZ to GLB (FIXED - includes job_type)
  Future<Map<String, dynamic>> convertUsdzToGlb(
    String sessionId,
    String inputFilename, {
    String? outputFilename,
    Map<String, dynamic>? conversionParams,
  }) async {
    // Build request body with REQUIRED job_type field
    final requestBody = <String, dynamic>{
      'job_type': 'usdz_to_glb', // ✅ REQUIRED
      'input_filename': inputFilename,
    };
    
    // Add optional fields
    if (outputFilename != null) {
      requestBody['output_filename'] = outputFilename;
    }
    
    if (conversionParams != null) {
      requestBody['conversion_params'] = conversionParams;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/convert'),
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody), // ✅ Includes job_type
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to start conversion: ${response.body}');
    }
  }
  
  // Check status
  Future<Map<String, dynamic>> checkStatus(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/status'),
      headers: {
        'X-API-Key': apiKey,
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get status: ${response.body}');
    }
  }
  
  // Download file
  Future<File> downloadFile(
    String sessionId,
    String filename,
    String savePath,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/download/$filename'),
      headers: {
        'X-API-Key': apiKey,
      },
    );
    
    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Download failed: ${response.body}');
    }
  }
}

// ✅ Complete workflow example
Future<void> convertUsdzToGlbWorkflow(File usdzFile) async {
  final api = BlenderApiClient('your-api-key-here');
  
  try {
    // 1. Create session
    final session = await api.createSession();
    final sessionId = session['session_id'];
    print('✅ Session created: $sessionId');
    
    // 2. Upload file
    final upload = await api.uploadFile(
      sessionId,
      usdzFile,
      'model/vnd.usdz+zip',
    );
    print('✅ File uploaded: ${upload['filename']}');
    
    // 3. Start conversion (FIXED - includes job_type)
    final job = await api.convertUsdzToGlb(
      sessionId,
      upload['filename'],
      outputFilename: '${upload['filename'].replaceAll('.usdz', '.glb')}',
      conversionParams: {
        'apply_scale': false,
        'merge_meshes': false,
        'target_scale': 1.0,
      },
    );
    print('✅ Conversion started: ${job['started_at']}');
    
    // 4. Poll for completion
    Map<String, dynamic> status;
    do {
      await Future.delayed(Duration(seconds: 2));
      status = await api.checkStatus(sessionId);
      print('Progress: ${status['progress']}%');
    } while (status['session_status'] == 'processing');
    
    // 5. Download result
    if (status['session_status'] == 'completed') {
      final result = status['result'];
      final outputFile = await api.downloadFile(
        sessionId,
        result['filename'],
        '/path/to/save/${result['filename']}',
      );
      print('✅ Download complete: ${outputFile.path}');
    } else {
      throw Exception('Conversion failed: ${status['error_message']}');
    }
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}
```

## Request Body Reference

### For USDZ to GLB Conversion

```json
{
  "job_type": "usdz_to_glb",  // ✅ REQUIRED - Must be exactly "usdz_to_glb"
  "input_filename": "file.usdz",  // ✅ REQUIRED
  "output_filename": "file.glb",  // Optional
  "conversion_params": {  // Optional
    "apply_scale": false,
    "merge_meshes": false,
    "target_scale": 1.0
  }
}
```

### For Navigation Mesh Generation

```json
{
  "job_type": "navmesh_generation",  // ✅ REQUIRED - Must be exactly "navmesh_generation"
  "input_filename": "file.glb",  // ✅ REQUIRED
  "output_filename": "file_navmesh.glb",  // Optional
  "navmesh_params": {  // Optional
    "cell_size": 0.3,
    "cell_height": 0.2,
    "agent_height": 2.0,
    "agent_radius": 0.6,
    "agent_max_climb": 0.9,
    "agent_max_slope": 45.0
  }
}
```

## Key Points

1. **`job_type` is REQUIRED** - Always include it in the request body
2. **Value must match exactly**: 
   - `"usdz_to_glb"` for conversion
   - `"navmesh_generation"` for navmesh
3. **Field name is `job_type`** (not `jobType` or `type`)
4. **Always use lowercase with underscores** for the job type value

## Testing

Test with a simple request:

```dart
final response = await http.post(
  Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/convert'),
  headers: {
    'X-API-Key': apiKey,
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'job_type': 'usdz_to_glb', // ✅ Don't forget this!
    'input_filename': 'test.usdz',
  }),
);
```

If you get a 422 error, check that `job_type` is included and spelled correctly.

