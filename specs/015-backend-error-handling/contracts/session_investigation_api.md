# API Contract: Session Investigation Endpoint

**Feature**: 015-backend-error-handling
**Date**: 2025-12-30
**API Type**: REST (JSON)
**Base URL**: `${EnvConfig.blenderApiBaseUrl}` (from `.env`: `BLENDER_API_BASE_URL`)

---

## Endpoint: Get Session Diagnostics

### Request

**Method**: `GET`

**Path**: `/sessions/{session_id}/investigate`

**Headers**:
```
X-API-Key: ${EnvConfig.blenderApiKey}
Content-Type: application/json
```

**Path Parameters**:

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `session_id` | String | Yes | Session identifier | `sess_SLuZEI3FpOk6R-a3u0DfBA` |

**Query Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `log_lines` | Integer | No | 20 | Number of log lines to include in summary (max: 100) |

**Example Request**:
```
GET https://blenderapi.stage.motorenflug.at/sessions/sess_SLuZEI3FpOk6R-a3u0DfBA/investigate?log_lines=20
X-API-Key: dev-test-key-1234567890
Content-Type: application/json
```

---

### Response: Success (200 OK)

**Content-Type**: `application/json`

**Schema**:
```json
{
  "session_id": "string",
  "session_status": "string (enum: active|processing|completed|failed|expired)",
  "created_at": "string (ISO 8601 datetime)",
  "expires_at": "string (ISO 8601 datetime)",
  "last_accessed": "string (ISO 8601 datetime) | null",
  "workspace_exists": "boolean",
  "workspace_path_sanitized": "string (relative path) | null",
  "files": {
    "directories": {
      "input": {
        "exists": "boolean",
        "file_count": "integer",
        "files": [
          {
            "name": "string",
            "size_bytes": "integer",
            "modified_at": "string (ISO 8601 datetime) | null"
          }
        ]
      },
      "output": { "..." },
      "logs": { "..." }
    },
    "root_files": [
      {
        "name": "string",
        "size_bytes": "integer",
        "modified_at": "string (ISO 8601 datetime) | null"
      }
    ]
  } | null,
  "status_data": {
    "processing_stage": "string",
    "progress": "integer",
    "started_at": "string (ISO 8601 datetime)",
    "completed_at": "string (ISO 8601 datetime) | null"
  } | null,
  "metadata": {
    "filename": "string",
    "size_bytes": "integer",
    "format": "string",
    "polygon_count": "integer | null"
  } | null,
  "parameters": {
    "job_type": "string",
    "conversion_params": { "..." }
  } | null,
  "logs_summary": {
    "total_lines": "integer",
    "error_count": "integer",
    "warning_count": "integer",
    "file_size_bytes": "integer",
    "last_lines": ["string"],
    "first_timestamp": "string (ISO 8601 datetime) | null",
    "last_timestamp": "string (ISO 8601 datetime) | null"
  } | null,
  "error_details": {
    "error_message": "string",
    "error_code": "string | null",
    "processing_stage": "string | null",
    "failed_at": "string (ISO 8601 datetime) | null",
    "blender_exit_code": "integer | null",
    "last_error_logs": ["string"]
  } | null,
  "investigation_timestamp": "string (ISO 8601 datetime)"
}
```

**Example Response** (Completed Session):
```json
{
  "session_id": "sess_SLuZEI3FpOk6R-a3u0DfBA",
  "session_status": "completed",
  "created_at": "2025-12-30T12:00:00Z",
  "expires_at": "2025-12-30T13:00:00Z",
  "last_accessed": "2025-12-30T12:10:00Z",
  "workspace_exists": true,
  "workspace_path_sanitized": "sess_SLuZEI3FpOk6R-a3u0DfBA",
  "files": {
    "directories": {
      "input": {
        "exists": true,
        "file_count": 1,
        "files": [
          {
            "name": "scan_scan-1767108249945-249945.usdz",
            "size_bytes": 1234567,
            "modified_at": "2025-12-30T12:01:00Z"
          }
        ]
      },
      "output": {
        "exists": true,
        "file_count": 1,
        "files": [
          {
            "name": "scan_scan-1767108249945-249945.glb",
            "size_bytes": 2345678,
            "modified_at": "2025-12-30T12:05:00Z"
          }
        ]
      },
      "logs": {
        "exists": true,
        "file_count": 1,
        "files": [
          {
            "name": "blender.log",
            "size_bytes": 45678,
            "modified_at": "2025-12-30T12:05:00Z"
          }
        ]
      }
    },
    "root_files": [
      {
        "name": "status.json",
        "size_bytes": 1234,
        "modified_at": "2025-12-30T12:00:00Z"
      },
      {
        "name": "params.json",
        "size_bytes": 567,
        "modified_at": "2025-12-30T12:01:00Z"
      }
    ]
  },
  "status_data": {
    "processing_stage": "completed",
    "progress": 100,
    "started_at": "2025-12-30T12:01:00Z",
    "completed_at": "2025-12-30T12:05:00Z"
  },
  "metadata": {
    "filename": "scan_scan-1767108249945-249945.glb",
    "size_bytes": 2345678,
    "format": "glb",
    "polygon_count": 12345
  },
  "parameters": {
    "job_type": "usdz_to_glb",
    "conversion_params": {
      "apply_scale": false,
      "merge_meshes": false,
      "target_scale": 1.0
    }
  },
  "logs_summary": {
    "total_lines": 150,
    "error_count": 0,
    "warning_count": 2,
    "file_size_bytes": 45678,
    "last_lines": [
      "{\"timestamp\": \"2025-12-30T12:05:00Z\", \"level\": \"INFO\", \"message\": \"Conversion completed successfully\"}"
    ],
    "first_timestamp": "2025-12-30T12:01:00Z",
    "last_timestamp": "2025-12-30T12:05:00Z"
  },
  "error_details": null,
  "investigation_timestamp": "2025-12-30T12:10:00Z"
}
```

**Example Response** (Failed Session):
```json
{
  "session_id": "sess_ABC123xyz",
  "session_status": "failed",
  "created_at": "2025-12-30T11:00:00Z",
  "expires_at": "2025-12-30T12:00:00Z",
  "last_accessed": "2025-12-30T11:05:00Z",
  "workspace_exists": true,
  "workspace_path_sanitized": "sess_ABC123xyz",
  "files": {
    "directories": {
      "input": {
        "exists": true,
        "file_count": 1,
        "files": [
          {
            "name": "invalid_file.usdz",
            "size_bytes": 5000000,
            "modified_at": "2025-12-30T11:01:00Z"
          }
        ]
      },
      "output": {
        "exists": false,
        "file_count": 0,
        "files": []
      },
      "logs": {
        "exists": true,
        "file_count": 1,
        "files": [
          {
            "name": "blender.log",
            "size_bytes": 12345,
            "modified_at": "2025-12-30T11:03:00Z"
          }
        ]
      }
    },
    "root_files": [
      {
        "name": "status.json",
        "size_bytes": 456,
        "modified_at": "2025-12-30T11:03:00Z"
      }
    ]
  },
  "status_data": {
    "processing_stage": "failed",
    "progress": 0,
    "started_at": "2025-12-30T11:01:00Z",
    "completed_at": null
  },
  "metadata": null,
  "parameters": {
    "job_type": "usdz_to_glb",
    "conversion_params": {
      "apply_scale": false,
      "merge_meshes": false,
      "target_scale": 1.0
    }
  },
  "logs_summary": {
    "total_lines": 45,
    "error_count": 5,
    "warning_count": 0,
    "file_size_bytes": 12345,
    "last_lines": [
      "{\"timestamp\": \"2025-12-30T11:03:00Z\", \"level\": \"ERROR\", \"message\": \"Failed to load USDZ: Invalid geometry data\"}",
      "{\"timestamp\": \"2025-12-30T11:03:00Z\", \"level\": \"ERROR\", \"message\": \"Conversion aborted due to invalid input file\"}"
    ],
    "first_timestamp": "2025-12-30T11:01:00Z",
    "last_timestamp": "2025-12-30T11:03:00Z"
  },
  "error_details": {
    "error_message": "Failed to load USDZ: Invalid geometry data",
    "error_code": "malformed_usdz",
    "processing_stage": "upload_validation",
    "failed_at": "2025-12-30T11:03:00Z",
    "blender_exit_code": 1,
    "last_error_logs": [
      "ERROR: USD file contains invalid mesh references",
      "ERROR: Geometry validation failed",
      "ERROR: Conversion aborted"
    ]
  },
  "investigation_timestamp": "2025-12-30T11:10:00Z"
}
```

---

### Response: Not Found (404)

**When**: Session doesn't exist, expired, or doesn't belong to authenticated API key

**Content-Type**: `application/json`

**Schema**:
```json
{
  "error_code": "NOT_FOUND",
  "message": "string",
  "details": {
    "session_id": "string"
  }
}
```

**Example**:
```json
{
  "error_code": "NOT_FOUND",
  "message": "Session not found or has expired. Please create a new session with POST /sessions.",
  "details": {
    "session_id": "sess_SLuZEI3FpOk6R-a3u0DfBA"
  }
}
```

---

### Response: Unauthorized (401)

**When**: Missing or invalid X-API-Key header

**Content-Type**: `application/json`

**Schema**:
```json
{
  "error_code": "UNAUTHORIZED",
  "message": "string"
}
```

**Example**:
```json
{
  "error_code": "UNAUTHORIZED",
  "message": "Invalid or missing API key. Please provide a valid X-API-Key header."
}
```

---

### Response: Too Many Requests (429)

**When**: Rate limit exceeded for API key

**Content-Type**: `application/json`

**Headers**:
```
Retry-After: 60
```

**Schema**:
```json
{
  "error_code": "RATE_LIMIT_EXCEEDED",
  "message": "string",
  "retry_after_seconds": "integer"
}
```

**Example**:
```json
{
  "error_code": "RATE_LIMIT_EXCEEDED",
  "message": "API rate limit exceeded. Please wait 60 seconds before retrying.",
  "retry_after_seconds": 60
}
```

---

### Response: Internal Server Error (500)

**When**: Server-side error during investigation

**Content-Type**: `application/json`

**Schema**:
```json
{
  "error_code": "INTERNAL_ERROR",
  "message": "string"
}
```

**Example**:
```json
{
  "error_code": "INTERNAL_ERROR",
  "message": "An unexpected error occurred while investigating the session. Please try again later."
}
```

---

## Error Handling by Client

| HTTP Status | Error Code | Client Action |
|-------------|------------|---------------|
| 200 | N/A | Display diagnostics in UI |
| 404 | NOT_FOUND | Show "Session expired or not found" message with TTL explanation |
| 401 | UNAUTHORIZED | Log authentication error, prompt user to check API key configuration |
| 429 | RATE_LIMIT_EXCEEDED | Retry after `retry_after_seconds` with exponential backoff |
| 500 | INTERNAL_ERROR | Show generic error, log to ErrorLogService, offer manual retry |
| 503 | SERVICE_UNAVAILABLE | Retry with exponential backoff (recoverable error) |
| Network Error | N/A | Queue operation for offline retry |

---

## Flutter Implementation

### Service Method

```dart
// lib/features/scanning/services/session_investigation_service.dart
class SessionInvestigationService {
  final http.Client _client;
  final String _baseUrl;
  final String _apiKey;
  final RetryPolicyService _retryPolicy;

  SessionInvestigationService({
    required http.Client client,
    required String baseUrl,
    required String apiKey,
    required RetryPolicyService retryPolicy,
  }) : _client = client,
       _baseUrl = baseUrl,
       _apiKey = apiKey,
       _retryPolicy = retryPolicy;

  /// Fetches comprehensive diagnostic information for a session
  Future<SessionDiagnostics> investigate(
    String sessionId, {
    int logLines = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/sessions/$sessionId/investigate')
        .replace(queryParameters: {'log_lines': logLines.toString()});

    final response = await _retryPolicy.executeWithRetry(
      operation: () => _client.get(
        uri,
        headers: {
          'X-API-Key': _apiKey,
          'Content-Type': 'application/json',
        },
      ),
      isRecoverableError: (error) {
        if (error is http.Response) {
          return _retryPolicy.isRecoverable(error.statusCode, null);
        }
        return true; // Network errors are recoverable
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return SessionDiagnostics.fromJson(json);
    } else if (response.statusCode == 404) {
      throw SessionNotFoundException(sessionId);
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Invalid API key');
    } else if (response.statusCode == 429) {
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '60') ?? 60;
      throw RateLimitException(retryAfter);
    } else {
      throw BlenderApiException(
        statusCode: response.statusCode,
        message: 'Failed to investigate session: ${response.body}',
      );
    }
  }
}
```

---

## Testing Scenarios

### Unit Tests

1. **Successful investigation (200)** - Verify SessionDiagnostics deserialization
2. **Session not found (404)** - Verify SessionNotFoundException thrown
3. **Unauthorized (401)** - Verify UnauthorizedException thrown
4. **Rate limit (429)** - Verify retry after delay
5. **Server error (500)** - Verify retry with exponential backoff
6. **Network error** - Verify operation queued for offline retry
7. **Malformed JSON response** - Verify graceful error handling

### Integration Tests

1. **End-to-end investigation flow** - Mock BlenderAPI, verify full request/response cycle
2. **Offline → Online transition** - Verify queued investigation processed when connectivity restored
3. **Retry exhaustion** - Verify error displayed after 3 failed retries

---

**End of API Contract Document**
