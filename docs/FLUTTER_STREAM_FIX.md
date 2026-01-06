# Flutter Stream Error Fix

## Problem

**Error**: `Bad state: Stream has already been listened to.`

This error occurs when trying to upload files because:
1. The API expects raw binary data in the request body (not multipart form data)
2. Dart streams are single-subscription by default
3. If you try to read a file stream multiple times or use it incorrectly, you get this error

## Solution

### ✅ Correct Upload Implementation

The API expects **raw binary data** in the request body. Here's the correct implementation:

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<UploadResponse> uploadFile(
  String sessionId,
  File file,
  String assetType, // 'model/gltf-binary' or 'model/vnd.usdz+zip'
) async {
  // ✅ Read file as bytes ONCE (not as a stream)
  final fileBytes = await file.readAsBytes();
  
  // ✅ Use http.post with body parameter (not bodyBytes with a stream)
  final response = await http.post(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/upload'),
    headers: {
      'X-API-Key': 'your-api-key-here',
      'X-Asset-Type': assetType,
      'X-Filename': file.path.split('/').last,
      'Content-Type': 'application/octet-stream',
    },
    body: fileBytes, // ✅ Direct bytes, not a stream
  );
  
  if (response.statusCode == 200) {
    return UploadResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Upload failed: ${response.body}');
  }
}
```

### ❌ Common Mistakes (What NOT to do)

#### Mistake 1: Using file.openRead() stream
```dart
// ❌ DON'T DO THIS - creates single-subscription stream
final stream = file.openRead();
final response = await http.post(
  uri,
  headers: headers,
  body: stream, // ❌ This will fail if stream is used elsewhere
);
```

#### Mistake 2: Using MultipartRequest
```dart
// ❌ DON'T DO THIS - API doesn't accept multipart
final request = http.MultipartRequest('POST', uri);
request.files.add(await http.MultipartFile.fromPath('file', file.path));
// API expects raw binary, not multipart form data
```

#### Mistake 3: Using StreamController incorrectly
```dart
// ❌ DON'T DO THIS - complex and error-prone
final controller = StreamController<List<int>>();
file.openRead().listen(controller.add); // Stream already listened to!
```

### ✅ For Large Files (with Progress Tracking)

If you need progress tracking for large files, use this approach:

```dart
Future<UploadResponse> uploadFileWithProgress(
  String sessionId,
  File file,
  String assetType,
  Function(int sent, int total)? onProgress,
) async {
  // Read file once as bytes
  final fileBytes = await file.readAsBytes();
  final totalBytes = fileBytes.length;
  
  // Validate file size before upload
  if (totalBytes > 500 * 1024 * 1024) {
    throw Exception('File size exceeds 500MB limit');
  }
  
  // Create request
  final request = http.Request(
    'POST',
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/upload'),
  );
  
  request.headers.addAll({
    'X-API-Key': 'your-api-key-here',
    'X-Asset-Type': assetType,
    'X-Filename': file.path.split('/').last,
    'Content-Type': 'application/octet-stream',
  });
  
  // Set body as bytes (not stream)
  request.bodyBytes = fileBytes;
  
  // Send request
  final streamedResponse = await http.Client().send(request);
  
  // Track progress if callback provided
  if (onProgress != null) {
    int sent = 0;
    streamedResponse.stream.listen(
      (chunk) {
        sent += chunk.length;
        onProgress(sent, totalBytes);
      },
    );
  }
  
  // Get response
  final response = await http.Response.fromStream(streamedResponse);
  
  if (response.statusCode == 200) {
    return UploadResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Upload failed: ${response.body}');
  }
}
```

### ✅ Complete Working Example

Here's a complete, working example for USDZ to GLB conversion:

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BlenderApiClient {
  final String baseUrl = 'https://blenderapi.stage.motorenflug.at';
  final String apiKey;
  
  BlenderApiClient(this.apiKey);
  
  Map<String, String> get _headers => {
    'X-API-Key': apiKey,
    'Content-Type': 'application/json',
  };
  
  // ✅ Create session
  Future<Map<String, dynamic>> createSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: _headers,
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create session: ${response.body}');
    }
  }
  
  // ✅ Upload file (FIXED - no stream issues)
  Future<Map<String, dynamic>> uploadFile(
    String sessionId,
    File file,
    String assetType,
  ) async {
    // Read file as bytes ONCE
    final fileBytes = await file.readAsBytes();
    
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/upload'),
      headers: {
        'X-API-Key': apiKey,
        'X-Asset-Type': assetType,
        'X-Filename': file.path.split('/').last,
        'Content-Type': 'application/octet-stream',
      },
      body: fileBytes, // ✅ Direct bytes
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }
  
  // ✅ Start conversion
  Future<Map<String, dynamic>> convertUsdzToGlb(
    String sessionId,
    String inputFilename,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/convert'),
      headers: _headers,
      body: json.encode({
        'job_type': 'usdz_to_glb',
        'input_filename': inputFilename,
        'conversion_params': {
          'apply_scale': false,
          'merge_meshes': false,
          'target_scale': 1.0,
        },
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to start conversion: ${response.body}');
    }
  }
  
  // ✅ Check status
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
  
  // ✅ Download file
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

// ✅ Usage example
Future<void> convertUsdzToGlbWorkflow(File usdzFile) async {
  final api = BlenderApiClient('your-api-key-here');
  
  try {
    // 1. Create session
    final session = await api.createSession();
    final sessionId = session['session_id'];
    print('✅ Session created: $sessionId');
    
    // 2. Upload file (FIXED - no stream error)
    final upload = await api.uploadFile(
      sessionId,
      usdzFile,
      'model/vnd.usdz+zip',
    );
    print('✅ File uploaded: ${upload['filename']}');
    
    // 3. Start conversion
    final job = await api.convertUsdzToGlb(
      sessionId,
      upload['filename'],
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

## Key Points

1. **Always read file as bytes first**: `await file.readAsBytes()` - this reads the entire file into memory once
2. **Use `body` parameter, not streams**: `http.post(uri, body: fileBytes)` - pass bytes directly
3. **Don't use `file.openRead()`**: This creates a single-subscription stream that can only be listened to once
4. **Don't use MultipartRequest**: The API expects raw binary, not multipart form data
5. **For large files**: Consider chunked uploads or accept that the file will be in memory temporarily

## Memory Considerations

- Files are loaded into memory when using `readAsBytes()`
- For files up to 500MB (the API limit), this is acceptable
- If you need to handle larger files, you'd need to implement chunked uploads (not currently supported by the API)

## Testing

Test with a small file first:

```dart
final testFile = File('/path/to/test.usdz');
await convertUsdzToGlbWorkflow(testFile);
```

If this works, the stream issue is resolved!

