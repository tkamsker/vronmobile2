# Feature Specification: Enhanced Backend Error Handling

**Feature Branch**: `015-backend-error-handling`
**Created**: 2025-12-30
**Status**: ✅ Complete
**Completed**: 2026-01-10
**Input**: User description: "increase backend error handling using scripts/investigate_session.sh"

## Clarifications

### Session 2025-12-30

- Q: The investigate_session.sh script currently uses `kubectl exec` to access session diagnostics directly from the pod filesystem. For mobile app integration (FR-006: session investigation capability), how should the app access session diagnostic data? → A: API endpoint with authentication token - BlenderAPI exposes `/sessions/{id}/investigate` endpoint requiring user authentication (per Requirements/PRD_SESSION_INVESTIGATION_API.md)
- Q: FR-008 requires distinguishing between "recoverable errors (automatic retry)" and "non-recoverable errors (user action required)". What specific criteria should the system use to classify an error as recoverable vs. non-recoverable? → A: Predefined error code mapping - Maintain lookup table mapping specific BlenderAPI error codes and HTTP statuses to retry eligibility (e.g., 503→retry, 400→no retry, timeout→retry, invalid_file→no retry)
- Q: FR-009 requires persisting error logs locally on device. What storage format and structure should be used for local error log persistence? → A: Structured JSON log entries - Store each error as JSON object in array/file with schema (timestamp, sessionId, httpStatus, errorCode, message, retryCount, userId), enables filtering and analysis
- Q: FR-004 requires displaying user-friendly error messages that map technical errors to actionable guidance. How should this error message mapping be implemented and maintained? → A: Centralized mapping service/class - Create dedicated error mapping service (e.g., ErrorMessageService) with lookup methods that translate error codes to user messages, supports future localization
- Q: When an error occurs while the device is completely offline (no network connectivity), how should the system handle error reporting, logging, and retry behavior? → A: Queue errors, show offline indicator - Log error locally to JSON, display offline banner with "Will retry when online", queue automatic retry for when connectivity restored

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Detailed Error Diagnostics for Failed Conversions (Priority: P1)

When a USDZ to GLB conversion fails, users receive detailed diagnostic information that helps them understand what went wrong and how to resolve the issue, reducing support tickets and improving user satisfaction.

**Why this priority**: Core functionality - failed conversions currently provide minimal feedback, leading to user confusion and increased support burden. Enhanced diagnostics enable self-service troubleshooting.

**Independent Test**: Trigger a conversion failure (invalid USDZ, timeout, or server error), verify that users receive detailed error messages with specific failure reasons, session information, and recommended actions.

**Acceptance Scenarios**:

1. **Given** user uploads USDZ and conversion fails due to invalid file format, **When** error is displayed, **Then** message includes specific format validation error and suggests valid file requirements
2. **Given** user uploads USDZ and conversion times out, **When** error occurs, **Then** message indicates timeout with session ID and suggests reducing file complexity or retrying
3. **Given** user uploads USDZ and BlenderAPI service is unavailable, **When** error occurs, **Then** message indicates service unavailability with retry guidance and estimated resolution time
4. **Given** user encounters session expiration during polling, **When** session no longer exists, **Then** message explains session cleanup policy (1 hour TTL) and provides session investigation option
5. **Given** authenticated user experiences conversion failure, **When** viewing error details, **Then** session ID is displayed with "View Session Details" option that calls `/sessions/{session_id}/investigate` API endpoint for comprehensive diagnostics

---

### User Story 2 - Automatic Error Recovery and Retry Logic (Priority: P2)

System automatically detects recoverable errors (network failures, temporary service unavailability) and implements intelligent retry logic with exponential backoff, minimizing user-visible failures for transient issues.

**Why this priority**: Improves user experience by handling temporary failures transparently - users shouldn't need to manually retry for issues that resolve automatically within seconds.

**Independent Test**: Simulate network interruption during upload or status polling, verify that system automatically retries with exponential backoff and succeeds without user intervention when connectivity is restored.

**Acceptance Scenarios**:

1. **Given** user uploads USDZ and network drops during upload, **When** connectivity is restored within 30 seconds, **Then** upload automatically resumes from last checkpoint without user action
2. **Given** user polls conversion status and BlenderAPI returns 503 Service Unavailable, **When** service recovers within retry window, **Then** polling continues automatically with exponential backoff (2s, 4s, 8s intervals)
3. **Given** user initiates conversion and BlenderAPI returns 429 Rate Limit, **When** rate limit resets, **Then** request is automatically retried after backoff period without user intervention
4. **Given** automatic retry fails after maximum attempts (3 retries over 1 minute), **When** all retries exhausted, **Then** user receives detailed error with manual retry option and support contact information
5. **Given** user encounters network error while device is completely offline, **When** error is detected, **Then** error is logged locally, offline banner displays "Will retry when online", and retry is queued for when connectivity restored

---

### User Story 3 - Session Investigation and Support Integration (Priority: P3)

Support team and advanced users can access detailed session investigation tools directly from error messages via BlenderAPI `/sessions/{session_id}/investigate` endpoint, enabling rapid diagnosis of conversion failures and backend issues without requiring kubectl or direct server access.

**Why this priority**: Empowers support team to quickly diagnose and resolve user issues without backend access - reduces resolution time from hours to minutes.

**Independent Test**: Generate error with session ID, verify that session investigation link/button launches diagnostic view showing session state, logs, file status, and recommended next steps retrieved from `/sessions/{session_id}/investigate` API endpoint.

**Acceptance Scenarios**:

1. **Given** user receives conversion error with session ID, **When** tapping "View Session Details" button, **Then** diagnostic screen displays session status, processing stage, file information, and error logs
2. **Given** support team receives session ID from user, **When** calling `/sessions/{session_id}/investigate` API endpoint with support API key, **Then** comprehensive session report shows session status, workspace files, log summary, error details, and processing metadata per PRD_SESSION_INVESTIGATION_API.md
3. **Given** session investigation reveals expired session (>1 hour), **When** viewing diagnostic report, **Then** explanation of TTL policy is displayed with guidance on re-uploading file
4. **Given** session investigation reveals BlenderAPI processing failure, **When** viewing error logs, **Then** specific Blender error messages are decoded into user-friendly explanations (geometry issues, texture problems, memory limits)

---

### Edge Cases

- User uploads file immediately before session expiration (59 minutes after session creation)
- Multiple concurrent errors occur (network failure + service timeout simultaneously)
- Session investigation requested for very old session IDs (cleaned up weeks ago)
- BlenderAPI returns unexpected status codes not documented in API spec (e.g., 418, 451)
- Pod restarts during active conversion causing session state loss
- User navigates away from app during automatic retry sequence
- Device goes offline during active retry sequence (connectivity lost mid-retry)
- Multiple errors queued while offline, then connectivity restored (retry queue processing)
- Session directory exists but is corrupted or partially deleted
- BlenderAPI `/sessions/{session_id}/investigate` endpoint returns timeout or 5xx errors
- User attempts session investigation in guest mode (unauthenticated)
- Conversion completes successfully but GLB download fails
- Multiple identical error conditions trigger rapid retry storms
- Session status polling encounters infinite loop due to stuck "processing" state

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST capture and log detailed error context for all BlenderAPI failures including HTTP status code, error message, session ID, timestamp, and user ID
- **FR-002**: System MUST implement automatic retry logic for transient failures (network errors, 503 service unavailable, 429 rate limits) with exponential backoff starting at 2 seconds
- **FR-003**: System MUST limit automatic retries to maximum 3 attempts over 1 minute window to prevent infinite retry loops
- **FR-004**: System MUST display user-friendly error messages via centralized error mapping service (e.g., ErrorMessageService) that translates technical error codes and HTTP statuses to actionable guidance (e.g., "File too complex, try scanning a smaller area" instead of "Memory limit exceeded"), with support for future localization
- **FR-005**: System MUST provide session ID in all error messages to enable support team investigation using diagnostic tools
- **FR-006**: System MUST implement session investigation capability via BlenderAPI `/sessions/{session_id}/investigate` endpoint (per Requirements/PRD_SESSION_INVESTIGATION_API.md) that retrieves session state, processing logs, file status, and error details when given a session ID using API key authentication
- **FR-007**: System MUST handle session expiration gracefully by detecting 404 errors on status polling and explaining 1-hour TTL policy to users
- **FR-008**: System MUST distinguish between recoverable errors (automatic retry) and non-recoverable errors (user action required) using predefined error code mapping table that maps HTTP status codes and BlenderAPI error codes to retry eligibility (e.g., 503/timeout→retry, 400/invalid_file→no retry)
- **FR-009**: System MUST persist error logs locally on device as structured JSON log entries (schema: timestamp, sessionId, httpStatus, errorCode, message, retryCount, userId) stored in app Documents directory, enabling offline viewing, filtering, and support diagnostics
- **FR-010**: System MUST validate BlenderAPI responses against expected schema and handle malformed responses without app crashes
- **FR-011**: System MUST handle offline errors gracefully by logging error to local JSON storage, displaying offline banner with "Will retry when online" message, and queueing automatic retry for when network connectivity is restored

### Key Entities

- **ErrorContext**: JSON-serializable object capturing complete error state with fields: timestamp (ISO 8601), sessionId (string), httpStatus (integer), errorCode (string), message (user-friendly string), retryCount (integer), userId (string), and stacktrace (string, for debugging)
- **ErrorMessageService**: Centralized service that translates technical error codes and HTTP statuses into user-friendly, actionable error messages with recommended next steps, maintaining lookup table of error code → message mappings with localization support
- **SessionDiagnostics**: Represents investigation results including session status (active/expired/failed), processing stage (pending/uploading/processing/completed), file information (sizes, locations), log excerpts, and recommended actions
- **RetryPolicy**: Defines retry behavior including max attempts (3), backoff strategy (exponential), base interval (2 seconds), error code mapping table that classifies HTTP statuses and BlenderAPI error codes as recoverable (e.g., 503, 429, network timeout, connection refused) or non-recoverable (e.g., 400, 401, 413, invalid_file, malformed_usdz), and offline queue handling that defers retry until connectivity restored

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 80% reduction in support tickets related to "conversion failed" errors within 30 days of deployment (baseline: current ticket volume)
- **SC-002**: 90% of transient errors (network failures, temporary service unavailability) are automatically recovered without user-visible failures
- **SC-003**: Users can identify and resolve 60% of conversion errors independently using enhanced error messages without contacting support
- **SC-004**: Support team resolves user-reported conversion issues 70% faster (from average 2 hours to under 35 minutes) using session investigation tools
- **SC-005**: Zero app crashes caused by unhandled BlenderAPI errors or malformed API responses
- **SC-006**: 95% of users receive actionable error guidance (specific problem explanation + recommended solution) for conversion failures
- **SC-007**: Automatic retry logic successfully recovers from 85% of network interruptions and temporary service outages without user awareness

## Dependencies

- **Depends on**:
  - Feature 014 (LiDAR Scanning) - BlenderAPI integration and conversion workflow
  - Requirements/PRD_SESSION_INVESTIGATION_API.md - BlenderAPI `/sessions/{session_id}/investigate` endpoint for session diagnostics (FR-006)
- **Blocks**: None
- **Enables**: Improved user self-service, reduced support burden, faster issue resolution

## Assumptions

- BlenderAPI service maintains current error response format and status codes documented in Requirements/FLUTTER_API_PRD.md
- Session investigation requires authenticated users for security (session IDs may contain sensitive information)
- BlenderAPI provides `/sessions/{session_id}/investigate` endpoint per Requirements/PRD_SESSION_INVESTIGATION_API.md for API-based diagnostics (no kubectl access required for mobile app or support team)
- Users have reasonable expectation to retry failed conversions immediately (not rate-limited by business logic)
- Support team can use same API endpoint as mobile app for session investigation with support API key (kubectl access optional for advanced debugging only)
- Error logs stored locally on device as JSON file are cleaned up after 7 days to prevent excessive storage usage (estimated max size: ~10MB for 1000 error entries)
- Exponential backoff intervals (2s, 4s, 8s) are acceptable latency for automatic retry from user perspective
