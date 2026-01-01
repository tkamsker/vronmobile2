# PRD: Session Investigation API Endpoint

**Product Requirements Document**  
**Feature**: FR-006 - Session Investigation Capability  
**Status**: Proposed  
**Created**: 2025-12-30  
**Target**: Mobile App Integration & Support Team Diagnostics

---

## Executive Summary

This PRD proposes a new API endpoint `/sessions/{session_id}/investigate` that provides comprehensive diagnostic information about a session. This endpoint enables mobile applications (Flutter) and support teams to access session diagnostic data without requiring `kubectl` access or direct pod filesystem access.

### Problem Statement

Currently, session investigation requires:
- Direct Kubernetes cluster access (`kubectl`)
- Pod filesystem access via `kubectl exec`
- Knowledge of internal filesystem structure
- Manual script execution (`investigate_session.sh`)

This creates barriers for:
- **Mobile app developers**: Cannot access diagnostic data from Flutter apps
- **Support teams**: Require cluster credentials to investigate user issues
- **End users**: No self-service diagnostic capability

### Proposed Solution

A RESTful API endpoint with token-based authentication that returns comprehensive session diagnostic information, including:
- Session metadata and status
- File system structure
- Processing logs
- Error details
- Workspace contents

This solution provides the best security/usability balance by:
- ✅ Enabling mobile app access without `kubectl` credentials
- ✅ Maintaining security through existing API key authentication
- ✅ Allowing support teams to use the same diagnostic endpoint
- ✅ Avoiding complexity of separate support-only tools
- ✅ Keeping session data protected (API key ownership verification)

---

## User Stories

### User Story 1: Mobile App Developer (Priority: P1)

**As a** Flutter developer  
**I want to** query session diagnostic information via API  
**So that** I can display detailed error information to users and debug conversion issues

**Acceptance Criteria**:
- Mobile app can call `GET /sessions/{id}/investigate` with API key
- Response includes all diagnostic data in JSON format
- Response is parseable by Flutter `dart:convert`
- Error messages are user-friendly and actionable

**Why this priority**: Core functionality for mobile app integration. Enables self-service debugging and better user experience.

---

### User Story 2: Support Team Member (Priority: P1)

**As a** support team member  
**I want to** investigate session issues via API  
**So that** I can help users debug problems without requiring cluster access

**Acceptance Criteria**:
- Support can use same API endpoint with support API key
- Response includes all information currently in `investigate_session.sh`
- No `kubectl` access required
- Can be called from any HTTP client (curl, Postman, etc.)

**Why this priority**: Reduces operational overhead and enables faster support response times.

---

### User Story 3: End User Self-Service (Priority: P2)

**As an** end user experiencing a conversion failure  
**I want to** see detailed diagnostic information  
**So that** I can understand what went wrong and potentially fix the issue myself

**Acceptance Criteria**:
- User can request investigation data for their own sessions
- Response includes clear error messages and file structure
- No sensitive system information is exposed

**Why this priority**: Improves user experience but not blocking for core functionality.

---

## Requirements

### Functional Requirements

#### FR-INV-001: API Endpoint
**System MUST provide** `GET /sessions/{session_id}/investigate` endpoint that returns comprehensive session diagnostic information.

**Details**:
- Endpoint path: `/sessions/{session_id}/investigate`
- HTTP Method: `GET`
- Authentication: Required (X-API-Key header)
- Response format: JSON
- Response time: < 2 seconds (p95)

---

#### FR-INV-002: Authentication & Authorization
**System MUST** verify API key ownership of the session before returning diagnostic data.

**Details**:
- Only sessions owned by the authenticated API key are accessible
- Returns HTTP 404 if session doesn't exist or doesn't belong to API key
- Uses existing `APIKeyDep` dependency for consistency
- Follows same authorization pattern as other session endpoints

**Security**:
- Prevents unauthorized access to other users' session data
- Maintains data isolation between API keys
- No sensitive system paths or secrets exposed

---

#### FR-INV-003: Response Data Structure
**System MUST return** a structured JSON response containing:

**Required Fields**:
- `session_id`: Session identifier
- `session_status`: Current session status (active, processing, completed, failed, expired)
- `created_at`: Session creation timestamp
- `expires_at`: Session expiration timestamp
- `last_accessed`: Last access timestamp
- `workspace_exists`: Boolean indicating if workspace directory exists
- `files`: Object containing file structure information

**Optional Fields** (if available):
- `status_data`: Contents of `status.json` file
- `metadata`: Contents of `meta.json` file (if processing completed)
- `parameters`: Contents of `params.json` file (if processing started)
- `logs_summary`: Summary of log file (last N lines, total lines, error count)
- `file_list`: List of all files in workspace with sizes
- `error_details`: Detailed error information if processing failed

---

#### FR-INV-004: File System Information
**System MUST provide** information about session workspace structure.

**Details**:
- List all files in workspace directory
- Include file sizes and modification times
- Show directory structure (input/, output/, logs/)
- Indicate which files exist vs. missing
- Do NOT expose full filesystem paths (sanitize to relative paths)

**Example Structure**:
```json
{
  "files": {
    "workspace_exists": true,
    "directories": {
      "input": {
        "exists": true,
        "file_count": 1,
        "files": [
          {"name": "model.usdz", "size_bytes": 1234567, "modified_at": "2025-12-30T12:00:00Z"}
        ]
      },
      "output": {
        "exists": true,
        "file_count": 1,
        "files": [
          {"name": "model.glb", "size_bytes": 2345678, "modified_at": "2025-12-30T12:05:00Z"}
        ]
      },
      "logs": {
        "exists": true,
        "file_count": 1,
        "files": [
          {"name": "blender.log", "size_bytes": 45678, "modified_at": "2025-12-30T12:05:00Z"}
        ]
      }
    },
    "root_files": [
      {"name": "status.json", "size_bytes": 1234, "modified_at": "2025-12-30T12:00:00Z"},
      {"name": "params.json", "size_bytes": 567, "modified_at": "2025-12-30T12:01:00Z"}
    ]
  }
}
```

---

#### FR-INV-005: Log Information
**System MUST provide** summary information about processing logs.

**Details**:
- Total log lines count
- Last N log lines (configurable, default: 20)
- Error count (lines containing "ERROR" or "CRITICAL")
- Warning count (lines containing "WARNING")
- Log file size
- First and last log timestamps (if available)

**Note**: Full logs are available via existing `/sessions/{id}/logs` endpoint. This endpoint provides a summary for quick diagnosis.

---

#### FR-INV-006: Error Details
**System MUST provide** detailed error information if processing failed.

**Details**:
- Error message from status.json
- Blender exit code (if available)
- Last error log entries
- Processing stage where failure occurred
- Timestamp of failure

---

#### FR-INV-007: Performance Requirements
**System MUST** respond within performance targets.

**Details**:
- Response time: < 2 seconds (p95)
- Timeout: 5 seconds maximum
- File system operations should be non-blocking
- Large log files should be sampled (not fully read)

---

#### FR-INV-008: Error Handling
**System MUST** handle edge cases gracefully.

**Error Scenarios**:
- Session doesn't exist → HTTP 404 with standard error format
- Session belongs to different API key → HTTP 404 (don't reveal existence)
- Session expired → HTTP 404 with expiration information
- Workspace directory missing → Return `workspace_exists: false` with available metadata
- File read errors → Include error in response, don't fail entire request
- Permission errors → Return sanitized error message

---

#### FR-INV-009: Response Schema Validation
**System MUST** return validated Pydantic schema response.

**Details**:
- Use Pydantic models for response validation
- Consistent with existing API response patterns
- Type-safe response structure
- Auto-generated OpenAPI documentation

---

### Non-Functional Requirements

#### NFR-INV-001: Security
- **No sensitive data exposure**: Internal filesystem paths, secrets, or system configuration must not be exposed
- **API key isolation**: Users can only access their own sessions
- **Path traversal protection**: Session ID validation prevents directory traversal attacks
- **Error message sanitization**: Error messages must not leak internal system details

#### NFR-INV-002: Performance
- **Response time**: < 2 seconds (p95) for typical sessions
- **Resource usage**: Minimal memory footprint (sample logs, don't load full files)
- **Concurrent requests**: Support 10+ concurrent investigation requests

#### NFR-INV-003: Compatibility
- **API versioning**: Follow existing API versioning strategy
- **Backward compatibility**: New endpoint doesn't break existing clients
- **Mobile compatibility**: JSON response parseable by Flutter `dart:convert`

#### NFR-INV-004: Observability
- **Logging**: Log investigation requests for audit trail
- **Metrics**: Track endpoint usage and response times
- **Error tracking**: Monitor investigation endpoint errors

---

## Technical Design

### API Endpoint Specification

#### Endpoint
```
GET /sessions/{session_id}/investigate
```

#### Headers
```
X-API-Key: <api-key>
Content-Type: application/json
```

#### Path Parameters
- `session_id` (string, required): Session identifier (format: `sess_*`)

#### Query Parameters
- `log_lines` (integer, optional): Number of log lines to include in summary (default: 20, max: 100)

#### Response Schema

```python
class SessionInvestigationResponse(BaseModel):
    """Response for session investigation endpoint."""
    session_id: str
    session_status: SessionStatus
    created_at: datetime
    expires_at: datetime
    last_accessed: Optional[datetime]
    
    # Workspace information
    workspace_exists: bool
    workspace_path_sanitized: Optional[str]  # Relative path only
    
    # File structure
    files: Optional[WorkspaceFilesInfo]
    
    # Session data files
    status_data: Optional[dict]
    metadata: Optional[dict]
    parameters: Optional[dict]
    
    # Log summary
    logs_summary: Optional[LogSummary]
    
    # Error information
    error_details: Optional[ErrorDetails]
    
    # Timestamps
    investigation_timestamp: datetime


class WorkspaceFilesInfo(BaseModel):
    """Information about workspace file structure."""
    directories: Dict[str, DirectoryInfo]
    root_files: List[FileInfo]


class DirectoryInfo(BaseModel):
    """Information about a directory."""
    exists: bool
    file_count: int
    files: List[FileInfo]


class FileInfo(BaseModel):
    """Information about a file."""
    name: str
    size_bytes: int
    modified_at: Optional[datetime]


class LogSummary(BaseModel):
    """Summary of processing logs."""
    total_lines: int
    error_count: int
    warning_count: int
    file_size_bytes: int
    last_lines: List[str]  # Last N lines
    first_timestamp: Optional[datetime]
    last_timestamp: Optional[datetime]


class ErrorDetails(BaseModel):
    """Detailed error information."""
    error_message: str
    error_code: Optional[str]
    processing_stage: Optional[str]
    failed_at: Optional[datetime]
    blender_exit_code: Optional[int]
    last_error_logs: List[str]
```

#### Response Example

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

#### Error Response Example

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

### Implementation Details

#### File Location
- Route: `src/api/routes/investigate.py` (new file)
- Schema: `src/models/schemas.py` (add `SessionInvestigationResponse` and related models)
- Service: `src/services/investigation_service.py` (new file, optional - can be in route handler)

#### Implementation Steps

1. **Create Response Schemas** (`src/models/schemas.py`)
   - Add `SessionInvestigationResponse`
   - Add `WorkspaceFilesInfo`, `DirectoryInfo`, `FileInfo`
   - Add `LogSummary`, `ErrorDetails`

2. **Create Investigation Service** (`src/services/investigation_service.py`)
   - `investigate_session(session: Session, log_lines: int = 20) -> SessionInvestigationResponse`
   - Helper methods for file system inspection
   - Log file sampling (read last N lines efficiently)
   - Error handling and sanitization

3. **Create API Route** (`src/api/routes/investigate.py`)
   - `GET /sessions/{session_id}/investigate` endpoint
   - Use `APIKeyDep` for authentication
   - Verify session ownership
   - Call investigation service
   - Return structured response

4. **Register Route** (`src/api/main.py`)
   - Import and include investigation router

5. **Add Tests** (`tests/unit/test_investigate_route.py`)
   - Unit tests for investigation service
   - Integration tests for API endpoint
   - Error case tests

6. **Update Documentation**
   - Add endpoint to `FLUTTER_API_PRD.md`
   - Update OpenAPI spec
   - Add usage examples

---

### Security Considerations

1. **API Key Verification**: Only sessions owned by the authenticated API key are accessible
2. **Path Sanitization**: No absolute filesystem paths exposed, only relative workspace paths
3. **Error Message Sanitization**: Internal errors sanitized before returning to client
4. **Log Sampling**: Only last N lines returned, not full log files (prevents memory issues)
5. **File Size Limits**: Large files are not read into memory, only metadata returned

---

### Performance Considerations

1. **Lazy Loading**: Only read files that exist, handle missing files gracefully
2. **Log Sampling**: Use efficient tail reading (seek to end, read backwards) instead of loading full file
3. **Async Operations**: Use async file I/O where possible
4. **Caching**: Consider caching session metadata (but respect TTL)
5. **Timeout Protection**: Set maximum operation time to prevent hanging

---

## Success Criteria

### Measurable Outcomes

- **SC-INV-001**: API endpoint responds within 2 seconds (p95) for typical sessions
- **SC-INV-002**: Mobile app can successfully retrieve diagnostic data for 100% of accessible sessions
- **SC-INV-003**: Support team can investigate issues without `kubectl` access in 100% of cases
- **SC-INV-004**: Zero security incidents from exposed sensitive data
- **SC-INV-005**: API endpoint handles 10+ concurrent requests without performance degradation

### Acceptance Criteria

- ✅ Endpoint returns all diagnostic information currently available via `investigate_session.sh`
- ✅ Response is parseable by Flutter `dart:convert` library
- ✅ Only sessions owned by authenticated API key are accessible
- ✅ No sensitive system information (paths, secrets) exposed
- ✅ Error cases handled gracefully with appropriate HTTP status codes
- ✅ Response schema validated with Pydantic
- ✅ OpenAPI documentation auto-generated and accurate

---

## Migration Plan

### Phase 1: Implementation (Week 1)
- Create response schemas
- Implement investigation service
- Create API endpoint
- Add unit tests

### Phase 2: Testing (Week 1-2)
- Integration tests
- Security review
- Performance testing
- Mobile app integration testing

### Phase 3: Documentation (Week 2)
- Update Flutter PRD
- Add usage examples
- Update OpenAPI spec
- Create migration guide for `investigate_session.sh` users

### Phase 4: Deployment (Week 2-3)
- Deploy to stage environment
- Test with mobile app
- Gather feedback
- Deploy to production

### Phase 5: Deprecation (Optional, Future)
- Consider deprecating `investigate_session.sh` in favor of API endpoint
- Provide migration guide for support team

---

## Alternatives Considered

### Alternative 1: Separate Support-Only Endpoint
**Approach**: Create a separate endpoint with different authentication for support team only.

**Rejected because**:
- ❌ Duplicates functionality
- ❌ Requires separate authentication mechanism
- ❌ Mobile apps still can't access diagnostic data
- ❌ More complex to maintain

### Alternative 2: WebSocket/SSE for Real-Time Diagnostics
**Approach**: Use WebSocket or SSE to stream diagnostic data in real-time.

**Rejected because**:
- ❌ Overkill for diagnostic use case (not real-time monitoring)
- ❌ More complex to implement
- ❌ Mobile app integration more complex
- ❌ Existing `/logs/stream` endpoint already provides real-time logs

### Alternative 3: kubectl Proxy with Authentication
**Approach**: Expose kubectl functionality via authenticated proxy.

**Rejected because**:
- ❌ Requires cluster access infrastructure
- ❌ Security concerns (exposing kubectl)
- ❌ Not suitable for mobile apps
- ❌ Complex to implement and maintain

### Alternative 4: GraphQL Endpoint
**Approach**: Use GraphQL for flexible diagnostic queries.

**Rejected because**:
- ❌ Adds new technology stack
- ❌ REST API already established and working
- ❌ Overkill for simple diagnostic use case
- ❌ Mobile app integration more complex

---

## Open Questions

1. **Log Line Limit**: Should there be a maximum limit on `log_lines` query parameter? (Proposed: max 100)
2. **Caching**: Should session metadata be cached? (Proposed: No, always fresh data)
3. **Rate Limiting**: Should investigation endpoint have separate rate limits? (Proposed: Use existing session rate limits)
4. **Historical Data**: Should expired sessions be queryable? (Proposed: No, only active/expired but not cleaned up)

---

## References

- Existing API endpoints: `src/api/routes/sessions.py`, `src/api/routes/status.py`, `src/api/routes/logs.py`
- Investigation script: `investigate_session.sh`
- Authentication: `src/api/dependencies.py`, `src/core/security.py`
- Session management: `src/services/session_manager.py`
- Response schemas: `src/models/schemas.py`
- Flutter PRD: `FLUTTER_API_PRD.md`
- API Specification: `specs/002-session-3d-api/spec.md`

---

## Approval

**Status**: Proposed  
**Next Steps**: Review and approval for implementation

**Stakeholders**:
- Mobile App Team (Flutter developers)
- Support Team
- DevOps Team
- Security Team

**Approval Required From**:
- [ ] Product Owner
- [ ] Technical Lead
- [ ] Security Team
- [ ] Mobile App Team Lead

