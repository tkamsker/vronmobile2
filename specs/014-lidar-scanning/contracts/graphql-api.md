# GraphQL API Contract: LiDAR Scanning

**Feature**: `014-lidar-scanning`
**Date**: 2025-12-25
**Status**: Phase 1 Design

## Overview

This document specifies the GraphQL API contract between the mobile app and backend for LiDAR scanning functionality. The backend must implement these mutations and types to support scan file uploads, USDZ→GLB conversion, and scan metadata management.

**Backend GraphQL Endpoint**: `https://api.vron.stage.motorenflug.at/graphql`

---

## Mutations

### 1. uploadProjectScan

Uploads a USDZ or GLB scan file to a project and triggers automatic USDZ→GLB conversion if USDZ format is uploaded.

**Signature**:
```graphql
mutation uploadProjectScan(
  $projectId: ID!
  $scanFile: Upload!
  $format: ScanFormat!
  $metadata: JSON
) {
  uploadProjectScan(
    projectId: $projectId
    scanFile: $scanFile
    format: $format
    metadata: $metadata
  ) {
    scan {
      id
      projectId
      format
      usdzUrl
      glbUrl
      fileSizeBytes
      capturedAt
      metadata
      conversionStatus
      createdAt
    }
    success
    message
  }
}
```

**Input Parameters**:

| Parameter | Type | Required | Description | Constraints |
|-----------|------|----------|-------------|-------------|
| `projectId` | ID | Yes | Target project UUID | Must be existing project owned by authenticated user |
| `scanFile` | Upload | Yes | USDZ or GLB file | Max 250 MB (262,144,000 bytes) |
| `format` | ScanFormat | Yes | File format enum | USDZ or GLB |
| `metadata` | JSON | No | Scan metadata | RoomPlan metadata (wall count, dimensions, etc.) |

**Return Type**: `UploadProjectScanPayload`

**Success Response**:
```graphql
{
  "data": {
    "uploadProjectScan": {
      "scan": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "projectId": "123e4567-e89b-12d3-a456-426614174000",
        "format": "USDZ",
        "usdzUrl": "https://s3.amazonaws.com/vron-scans/projects/123e4567/scans/550e8400.usdz?signature=...",
        "glbUrl": "https://s3.amazonaws.com/vron-scans/projects/123e4567/scans/550e8400.glb?signature=...",
        "fileSizeBytes": 15728640,
        "capturedAt": "2025-12-25T14:30:00Z",
        "metadata": {
          "wallCount": 4,
          "doorCount": 1,
          "windowCount": 2,
          "roomDimensions": {
            "width": 5.2,
            "height": 2.8,
            "depth": 4.1
          }
        },
        "conversionStatus": "COMPLETED",
        "createdAt": "2025-12-25T14:35:22Z"
      },
      "success": true,
      "message": "Scan uploaded and converted successfully"
    }
  }
}
```

**Error Responses**:

1. **File Size Exceeded**:
```graphql
{
  "errors": [
    {
      "message": "File size exceeds maximum limit of 250 MB",
      "extensions": {
        "code": "FILE_SIZE_EXCEEDED",
        "fileSizeBytes": 300000000,
        "maxSizeBytes": 262144000
      }
    }
  ]
}
```

2. **Invalid Format**:
```graphql
{
  "errors": [
    {
      "message": "Unsupported file format. Only USDZ and GLB files are allowed.",
      "extensions": {
        "code": "INVALID_FORMAT",
        "detectedFormat": "OBJ"
      }
    }
  ]
}
```

3. **Project Not Found**:
```graphql
{
  "errors": [
    {
      "message": "Project not found or you don't have permission to access it",
      "extensions": {
        "code": "PROJECT_NOT_FOUND",
        "projectId": "123e4567-e89b-12d3-a456-426614174000"
      }
    }
  ]
}
```

4. **Conversion Failed**:
```graphql
{
  "data": {
    "uploadProjectScan": {
      "scan": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "format": "USDZ",
        "usdzUrl": "https://s3.amazonaws.com/...",
        "glbUrl": null,
        "conversionStatus": "FAILED",
        "createdAt": "2025-12-25T14:35:22Z"
      },
      "success": false,
      "message": "File uploaded but GLB conversion failed: Unsupported geometry detected"
    }
  }
}
```

**Backend Responsibilities**:
1. Validate file size (≤250 MB)
2. Validate file format (USDZ or GLB)
3. Validate user authentication and project ownership
4. Store file in S3 (or equivalent): `projects/{projectId}/scans/{scanId}.{format}`
5. Generate signed URL with 7-day expiration
6. If format == USDZ, trigger asynchronous USDZ→GLB conversion:
   - Option A: Call Sirv API (https://sirv.com/help/articles/convert-usdz-to-glb-via-api/)
   - Option B: Trigger AWS Lambda with usd2gltf container
7. Store both USDZ and GLB URLs in database
8. Return scan entity with conversion status

**Performance SLA**:
- File upload: <30 seconds for 50 MB file on 10 Mbps connection
- USDZ→GLB conversion: 5-30 seconds (depends on file complexity)
- Total end-to-end: <60 seconds for typical room scan

---

### 2. getScanStatus (Optional - for polling)

Retrieves the current conversion status of a scan. Useful if conversion is asynchronous and client needs to poll for completion.

**Signature**:
```graphql
query getScanStatus($scanId: ID!) {
  scan(id: $scanId) {
    id
    format
    conversionStatus
    glbUrl
    error {
      code
      message
    }
  }
}
```

**Input Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scanId` | ID | Yes | Scan UUID |

**Return Type**: `Scan`

**Success Response** (conversion completed):
```graphql
{
  "data": {
    "scan": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "format": "USDZ",
      "conversionStatus": "COMPLETED",
      "glbUrl": "https://s3.amazonaws.com/vron-scans/.../550e8400.glb?signature=...",
      "error": null
    }
  }
}
```

**Success Response** (conversion in progress):
```graphql
{
  "data": {
    "scan": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "format": "USDZ",
      "conversionStatus": "IN_PROGRESS",
      "glbUrl": null,
      "error": null
    }
  }
}
```

**Error Response** (conversion failed):
```graphql
{
  "data": {
    "scan": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "format": "USDZ",
      "conversionStatus": "FAILED",
      "glbUrl": null,
      "error": {
        "code": "UNSUPPORTED_PRIM",
        "message": "USDZ contains geometry types not supported in glTF (NURBS, volumes)"
      }
    }
  }
}
```

---

### 3. deleteScan

Deletes a scan from a project and removes associated files from storage.

**Signature**:
```graphql
mutation deleteScan($scanId: ID!) {
  deleteScan(id: $scanId) {
    success
    message
  }
}
```

**Input Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scanId` | ID | Yes | Scan UUID to delete |

**Return Type**: `DeleteScanPayload`

**Success Response**:
```graphql
{
  "data": {
    "deleteScan": {
      "success": true,
      "message": "Scan and associated files deleted successfully"
    }
  }
}
```

**Error Response**:
```graphql
{
  "errors": [
    {
      "message": "Scan not found or you don't have permission to delete it",
      "extensions": {
        "code": "SCAN_NOT_FOUND",
        "scanId": "550e8400-e29b-41d4-a716-446655440000"
      }
    }
  ]
}
```

**Backend Responsibilities**:
1. Validate user authentication and scan ownership
2. Delete USDZ file from S3
3. Delete GLB file from S3 (if exists)
4. Delete scan record from database
5. Return success confirmation

---

## Types

### ScanFormat (Enum)

```graphql
enum ScanFormat {
  USDZ
  GLB
}
```

**Values**:
- `USDZ`: Apple RoomPlan native output format
- `GLB`: Binary glTF 2.0 format

---

### ConversionStatus (Enum)

```graphql
enum ConversionStatus {
  PENDING      # Conversion queued
  IN_PROGRESS  # Conversion running
  COMPLETED    # Conversion successful
  FAILED       # Conversion failed
  NOT_APPLICABLE # GLB file uploaded (no conversion needed)
}
```

---

### Scan (Type)

```graphql
type Scan {
  id: ID!
  projectId: ID!
  format: ScanFormat!
  usdzUrl: String
  glbUrl: String
  fileSizeBytes: Int!
  capturedAt: DateTime!
  metadata: JSON
  conversionStatus: ConversionStatus!
  error: ConversionError
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

**Fields**:

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | ID | No | Unique scan identifier (UUID) |
| `projectId` | ID | No | Associated project UUID |
| `format` | ScanFormat | No | File format (USDZ or GLB) |
| `usdzUrl` | String | Yes | S3 signed URL for USDZ file (null if GLB upload) |
| `glbUrl` | String | Yes | S3 signed URL for GLB file (null if conversion pending/failed) |
| `fileSizeBytes` | Int | No | Original file size in bytes |
| `capturedAt` | DateTime | No | Timestamp when scan was captured (from mobile app) |
| `metadata` | JSON | Yes | RoomPlan metadata (wall count, dimensions, etc.) |
| `conversionStatus` | ConversionStatus | No | Current conversion status |
| `error` | ConversionError | Yes | Error details if conversion failed |
| `createdAt` | DateTime | No | Backend record creation timestamp |
| `updatedAt` | DateTime | No | Backend record last update timestamp |

---

### ConversionError (Type)

```graphql
type ConversionError {
  code: String!
  message: String!
}
```

**Error Codes** (matching mobile app `ConversionErrorCode`):
- `UNSUPPORTED_PRIM`: USDZ contains geometry types not supported in glTF
- `MISSING_TEXTURE`: Referenced texture file not found in USDZ bundle
- `READ_ERROR`: Cannot read USDZ file (corrupted)
- `MEMORY_EXCEEDED`: Conversion requires too much memory
- `TIMEOUT`: Conversion exceeded 30 second timeout
- `SERVER_ERROR`: Internal conversion service error

---

### UploadProjectScanPayload (Type)

```graphql
type UploadProjectScanPayload {
  scan: Scan
  success: Boolean!
  message: String
}
```

---

### DeleteScanPayload (Type)

```graphql
type DeleteScanPayload {
  success: Boolean!
  message: String
}
```

---

### Project Extension

The existing `Project` type should be extended to include scans:

```graphql
type Project {
  id: ID!
  name: String!
  # ... existing fields ...
  scans: [Scan!]!
}
```

---

## Query Examples

### Example 1: Upload USDZ Scan to Project

**Mobile App (Dart)**:
```dart
final mutation = gql(r'''
  mutation UploadProjectScan(
    $projectId: ID!
    $scanFile: Upload!
    $format: ScanFormat!
    $metadata: JSON
  ) {
    uploadProjectScan(
      projectId: $projectId
      scanFile: $scanFile
      format: $format
      metadata: $metadata
    ) {
      scan {
        id
        usdzUrl
        glbUrl
        conversionStatus
      }
      success
      message
    }
  }
''');

final result = await graphQLService.client.mutate(
  MutationOptions(
    document: mutation,
    variables: {
      'projectId': projectId,
      'scanFile': scanFile, // MultipartFile from file_picker
      'format': 'USDZ',
      'metadata': {
        'wallCount': 4,
        'doorCount': 1,
        'windowCount': 2,
        'roomDimensions': {'width': 5.2, 'height': 2.8, 'depth': 4.1},
      },
    },
  ),
);
```

---

### Example 2: Get Project Scans

**Mobile App (Dart)**:
```dart
final query = gql(r'''
  query GetProjectScans($projectId: ID!) {
    project(id: $projectId) {
      id
      name
      scans {
        id
        format
        usdzUrl
        glbUrl
        fileSizeBytes
        capturedAt
        conversionStatus
      }
    }
  }
''');

final result = await graphQLService.client.query(
  QueryOptions(
    document: query,
    variables: {'projectId': projectId},
  ),
);
```

---

### Example 3: Poll Conversion Status

**Mobile App (Dart)**:
```dart
Future<ConversionStatus> pollConversionStatus(String scanId) async {
  final query = gql(r'''
    query GetScanStatus($scanId: ID!) {
      scan(id: $scanId) {
        id
        conversionStatus
        glbUrl
        error {
          code
          message
        }
      }
    }
  ''');

  while (true) {
    final result = await graphQLService.client.query(
      QueryOptions(
        document: query,
        variables: {'scanId': scanId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    final status = result.data!['scan']['conversionStatus'] as String;

    if (status == 'COMPLETED' || status == 'FAILED') {
      return ConversionStatus.values.byName(status.toLowerCase());
    }

    // Poll every 2 seconds
    await Future.delayed(Duration(seconds: 2));
  }
}
```

---

## Authentication

All mutations and queries require **authenticated user** via Bearer token:

```
Authorization: Bearer <access_token>
```

**Validation**:
- User must be authenticated (valid JWT token)
- User must own the project (for `uploadProjectScan`, `deleteScan`)
- User must have permission to view project (for scan queries)

**Error Response** (unauthenticated):
```graphql
{
  "errors": [
    {
      "message": "Unauthorized: Invalid or missing authentication token",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ]
}
```

---

## File Upload Mechanism

**Protocol**: GraphQL Multipart Request (https://github.com/jaydenseric/graphql-multipart-request-spec)

**Flutter Implementation**:
```dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<void> uploadScan(File scanFile, String projectId) async {
  final bytes = await scanFile.readAsBytes();
  final multipartFile = http.MultipartFile.fromBytes(
    'scanFile',
    bytes,
    filename: path.basename(scanFile.path),
    contentType: MediaType('model', 'vnd.usdz+zip'), // For USDZ
  );

  final mutation = gql(r'''
    mutation UploadProjectScan(
      $projectId: ID!
      $scanFile: Upload!
      $format: ScanFormat!
    ) {
      uploadProjectScan(
        projectId: $projectId
        scanFile: $scanFile
        format: $format
      ) {
        scan { id usdzUrl glbUrl }
        success
      }
    }
  ''');

  final result = await graphQLService.client.mutate(
    MutationOptions(
      document: mutation,
      variables: {
        'projectId': projectId,
        'scanFile': multipartFile,
        'format': 'USDZ',
      },
    ),
  );
}
```

**Backend Implementation** (Node.js example with Apollo Server):
```javascript
const { GraphQLUpload } = require('graphql-upload');

const resolvers = {
  Upload: GraphQLUpload,

  Mutation: {
    uploadProjectScan: async (_, { projectId, scanFile, format, metadata }, context) => {
      // Validate authentication
      if (!context.user) {
        throw new AuthenticationError('User not authenticated');
      }

      // Validate project ownership
      const project = await db.projects.findById(projectId);
      if (!project || project.userId !== context.user.id) {
        throw new ForbiddenError('Project not found or access denied');
      }

      // Process file upload
      const { createReadStream, filename, mimetype, encoding } = await scanFile;
      const stream = createReadStream();

      // Validate file size
      const chunks = [];
      for await (const chunk of stream) {
        chunks.push(chunk);
      }
      const buffer = Buffer.concat(chunks);
      if (buffer.length > 262144000) { // 250 MB
        throw new UserInputError('File size exceeds 250 MB limit');
      }

      // Upload to S3
      const scanId = uuidv4();
      const s3Key = `projects/${projectId}/scans/${scanId}.${format.toLowerCase()}`;
      await s3.upload({ Bucket: BUCKET_NAME, Key: s3Key, Body: buffer }).promise();

      // Create scan record
      const scan = await db.scans.create({
        id: scanId,
        projectId,
        format,
        usdzUrl: format === 'USDZ' ? getSignedUrl(s3Key) : null,
        glbUrl: null,
        fileSizeBytes: buffer.length,
        metadata,
        conversionStatus: format === 'USDZ' ? 'PENDING' : 'NOT_APPLICABLE',
      });

      // Trigger conversion if USDZ
      if (format === 'USDZ') {
        triggerConversionJob(scanId, s3Key);
      }

      return { scan, success: true, message: 'Scan uploaded successfully' };
    },
  },
};
```

---

## Conversion Service Integration

### Option A: Sirv API

**Backend Integration**:
```javascript
const axios = require('axios');

async function triggerConversionJob(scanId, usdzS3Key) {
  try {
    // Download USDZ from S3
    const usdzBuffer = await downloadFromS3(usdzS3Key);

    // Upload to Sirv for conversion
    const sirvResponse = await axios.post(
      'https://api.sirv.com/v2/files/convert',
      usdzBuffer,
      {
        headers: {
          'Authorization': `Bearer ${SIRV_API_KEY}`,
          'Content-Type': 'model/vnd.usdz+zip',
        },
        params: {
          to: 'glb',
        },
      }
    );

    // Download converted GLB from Sirv
    const glbBuffer = await axios.get(sirvResponse.data.url, { responseType: 'arraybuffer' });

    // Upload GLB to S3
    const glbS3Key = usdzS3Key.replace('.usdz', '.glb');
    await s3.upload({ Bucket: BUCKET_NAME, Key: glbS3Key, Body: glbBuffer.data }).promise();

    // Update scan record
    await db.scans.update({
      id: scanId,
      glbUrl: getSignedUrl(glbS3Key),
      conversionStatus: 'COMPLETED',
    });
  } catch (error) {
    await db.scans.update({
      id: scanId,
      conversionStatus: 'FAILED',
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
}
```

### Option B: AWS Lambda

**Lambda Trigger** (via EventBridge on S3 upload):
```javascript
// Lambda function code
const { execSync } = require('child_process');
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
  const bucket = event.Records[0].s3.bucket.name;
  const usdzKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

  try {
    // Download USDZ from S3
    const usdzFile = await s3.getObject({ Bucket: bucket, Key: usdzKey }).promise();

    // Convert using usd2gltf (Python tool in Docker container)
    execSync(`python3 -m usd2gltf /tmp/input.usdz /tmp/output.glb`);

    // Upload GLB to S3
    const glbKey = usdzKey.replace('.usdz', '.glb');
    const glbFile = fs.readFileSync('/tmp/output.glb');
    await s3.putObject({ Bucket: bucket, Key: glbKey, Body: glbFile }).promise();

    // Update scan status in database (via API call or direct DB connection)
    await updateScanStatus(extractScanId(usdzKey), 'COMPLETED', glbKey);
  } catch (error) {
    await updateScanStatus(extractScanId(usdzKey), 'FAILED', null, error.message);
  }
};
```

---

## Testing Requirements

### Contract Tests (Mobile App)

1. **Test successful USDZ upload**: Verify mutation returns scan with `usdzUrl`, `conversionStatus: PENDING`
2. **Test GLB upload**: Verify mutation returns scan with `glbUrl`, `conversionStatus: NOT_APPLICABLE`
3. **Test file size validation**: Upload 300 MB file, expect `FILE_SIZE_EXCEEDED` error
4. **Test invalid format**: Upload OBJ file, expect `INVALID_FORMAT` error
5. **Test conversion completion**: Poll `getScanStatus`, verify `conversionStatus: COMPLETED` and `glbUrl` populated
6. **Test conversion failure**: Simulate corrupted USDZ, verify `conversionStatus: FAILED` and `error` populated
7. **Test unauthorized access**: Upload to project user doesn't own, expect `PROJECT_NOT_FOUND` error
8. **Test delete scan**: Verify `deleteScan` mutation succeeds and file is removed

### Backend Integration Tests

1. **Test S3 upload**: Verify file stored in correct bucket path
2. **Test signed URL generation**: Verify URLs are valid and expire after 7 days
3. **Test Sirv API integration**: Mock Sirv response, verify GLB stored correctly
4. **Test AWS Lambda trigger**: Upload USDZ to S3, verify Lambda executes and GLB created
5. **Test conversion timeout**: Simulate 30+ second conversion, verify `TIMEOUT` error
6. **Test concurrent uploads**: Upload multiple scans simultaneously, verify no conflicts

---

## Performance SLA

| Operation | Target | Maximum |
|-----------|--------|---------|
| File upload (50 MB) | <20 seconds | <30 seconds |
| Conversion (typical room) | <10 seconds | <30 seconds |
| Get scan status query | <500 ms | <1 second |
| Delete scan | <2 seconds | <5 seconds |
| Signed URL generation | <100 ms | <500 ms |

---

## References

- [GraphQL Multipart Request Spec](https://github.com/jaydenseric/graphql-multipart-request-spec)
- [Apollo Server File Upload](https://www.apollographql.com/docs/apollo-server/data/file-uploads/)
- [Sirv USDZ to GLB API](https://sirv.com/help/articles/convert-usdz-to-glb-via-api/)
- [AWS Lambda with Docker Containers](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [Data Model: ScanData Entity](../data-model.md#1-scandata)
- [Research: USDZ→GLB Conversion Strategy](../research.md#decision-3-usdzglb-conversion-strategy)
