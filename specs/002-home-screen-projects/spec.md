# Feature Specification: Home Screen - Project List

**Feature Branch**: `002-home-screen-projects`
**Created**: 2025-12-21
**Status**: Draft
**Input**: User requirement: "Home screen showing project list with search, filters, and navigation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Project List (Priority: P1) 🎯 MVP

A logged-in user is presented with their project workspace showing all projects they have access to, with the ability to view project details and navigate to different sections.

**Why this priority**: This is the primary screen users see after logging in. It provides access to all user projects and is the main navigation hub of the application.

**Independent Test**: Can be fully tested by logging in and verifying the project list displays with all UI elements matching the design.

**Acceptance Scenarios**:

1. **Given** user has successfully logged in, **When** authentication completes, **Then** home screen displays with "Your projects" heading
2. **Given** home screen is displayed, **When** user views the screen, **Then** search bar is visible at the top
3. **Given** home screen is displayed, **When** user views the screen, **Then** filter tabs (All, Active, Archived, Sort) are visible
4. **Given** home screen is displayed, **When** projects exist, **Then** "Recent projects" section shows project count (e.g., "6 total")
5. **Given** home screen is displayed, **When** user views project cards, **Then** each card shows: image, title, status, description, metadata, and "Enter project" button
6. **Given** home screen is displayed, **When** user views the screen, **Then** bottom navigation bar is visible with Home, Projects, LiDAR, Profile tabs
7. **Given** home screen is displayed, **When** user views the screen, **Then** floating action button (+) is visible in bottom-right

---

### User Story 2 - Search and Filter Projects (Priority: P2)

Users can search for projects by name and filter the project list by status (All, Active, Archived) to quickly find the projects they need.

**Why this priority**: Essential for users with many projects to efficiently navigate their workspace. Depends on P1 but provides significant UX improvement.

**Independent Test**: Can be tested by entering search queries and toggling filter tabs, verifying the project list updates accordingly.

**Acceptance Scenarios**:

1. **Given** user is on home screen, **When** user taps search bar, **Then** keyboard appears and user can type search query
2. **Given** user enters search query, **When** typing, **Then** project list filters in real-time to show matching projects
3. **Given** user is on home screen, **When** user taps "Active" filter, **Then** only active projects are displayed
4. **Given** user is on home screen, **When** user taps "Archived" filter, **Then** only archived projects are displayed
5. **Given** user is on home screen, **When** user taps "All" filter, **Then** all projects are displayed
6. **Given** user has filtered projects, **When** user clears search or selects "All", **Then** full project list is restored

---

### User Story 3 - Navigate to Project and App Sections (Priority: P2)

Users can tap on project cards to enter specific projects and use the bottom navigation to access different app sections (Projects, LiDAR, Profile).

**Why this priority**: Core navigation functionality that enables users to access all app features. Required for app usability.

**Independent Test**: Can be tested by tapping project cards and navigation tabs, verifying correct screen transitions.

**Acceptance Scenarios**:

1. **Given** user is viewing project list, **When** user taps "Enter project" button, **Then** navigate to project detail screen
2. **Given** user is on home screen, **When** user taps "Projects" tab in bottom nav, **Then** stay on current screen (already on projects)
3. **Given** user is on home screen, **When** user taps "LiDAR" tab in bottom nav, **Then** navigate to LiDAR scanning screen
4. **Given** user is on home screen, **When** user taps "Profile" tab in bottom nav, **Then** navigate to user profile screen
5. **Given** user is on home screen, **When** user taps floating action button (+), **Then** navigate to create new project screen
6. **Given** user is on home screen, **When** user taps profile icon (top-right), **Then** show user menu or navigate to profile

---

### User Story 4 - Internationalization (Priority: P3)

All text on the home screen is displayed in the user's preferred language (de, en, pt) based on authentication settings or device locale.

**Why this priority**: Important for user experience but can be added after core functionality is working.

**Independent Test**: Can be tested by changing language settings and verifying all text updates correctly.

**Acceptance Scenarios**:

1. **Given** user's language preference is English, **When** home screen loads, **Then** all text displays in English
2. **Given** user's language preference is German, **When** home screen loads, **Then** all text displays in German
3. **Given** user's language preference is Portuguese, **When** home screen loads, **Then** all text displays in Portuguese
4. **Given** language is changed, **When** user returns to home screen, **Then** text updates to new language without restart

---

### Edge Cases

- What happens when user has no projects yet?
- What happens when search returns no results?
- What happens when API request fails or times out?
- What happens when user has hundreds of projects (pagination)?
- What happens when project image fails to load?
- What happens when user taps "Enter project" while offline?
- What happens when user rapidly switches between filter tabs?
- What happens when user rotates device?

## Requirements *(mandatory)*

### Functional Requirements

#### Display & Layout
- **FR-001**: Screen MUST display "Your projects" heading with subtitle "Jump back into your workspace"
- **FR-002**: Screen MUST display user profile icon in top-right corner
- **FR-003**: Screen MUST display search bar with placeholder text localized to user's language
- **FR-004**: Screen MUST display filter tabs: All, Active, Archived, Sort
- **FR-005**: Screen MUST display "Recent projects" section header with total count
- **FR-006**: Screen MUST display bottom navigation bar with Home, Projects, LiDAR, Profile tabs
- **FR-007**: Screen MUST display floating action button (+) in bottom-right corner
- **FR-008**: Screen MUST match provided design screenshot for layout, spacing, colors, and typography

#### Project Cards
- **FR-009**: Each project card MUST display project thumbnail image
- **FR-010**: Each project card MUST display project title
- **FR-011**: Each project card MUST display status badge (Active/Paused/Archived) with appropriate color
- **FR-012**: Each project card MUST display project description (2-3 lines max)
- **FR-013**: Each project card MUST display metadata (updated time, team info)
- **FR-014**: Each project card MUST display "Enter project →" button

#### Data & Authentication
- **FR-015**: Screen MUST fetch projects using authenticated GraphQL API request
- **FR-016**: Screen MUST use access token from login authentication
- **FR-017**: Screen MUST handle authentication errors and redirect to login if token invalid
- **FR-018**: Screen MUST display loading state while fetching projects
- **FR-019**: Screen MUST handle API errors gracefully with user-friendly messages

#### Search & Filtering
- **FR-020**: Search MUST filter projects by matching project title
- **FR-021**: Search MUST be case-insensitive
- **FR-022**: Search MUST update results in real-time as user types
- **FR-023**: "All" filter MUST show all projects regardless of status
- **FR-024**: "Active" filter MUST show only projects with status "Active"
- **FR-025**: "Archived" filter MUST show only projects with status "Archived"
- **FR-026**: Active filter tab MUST be visually highlighted

#### Navigation
- **FR-027**: Tapping "Enter project" button MUST navigate to project detail screen with project ID
- **FR-028**: Tapping "Home" tab MUST navigate to home screen (if not already there)
- **FR-029**: Tapping "Projects" tab MUST stay on current screen
- **FR-030**: Tapping "LiDAR" tab MUST navigate to scanning screen
- **FR-031**: Tapping "Profile" tab MUST navigate to user profile screen
- **FR-032**: Tapping floating action button MUST navigate to create project screen
- **FR-033**: Tapping profile icon (top-right) MUST show user menu or profile

#### Internationalization
- **FR-034**: All static text MUST be internationalized (de, en, pt)
- **FR-035**: Language MUST be determined from user authentication settings or device locale
- **FR-036**: Dynamic content (project titles, descriptions) MUST display in original language
- **FR-037**: Metadata (time stamps) MUST be formatted according to user's locale

#### Accessibility & UX
- **FR-038**: Screen MUST be accessible with proper semantic labels for screen readers
- **FR-039**: All interactive elements MUST meet minimum touch target size of 44x44 logical pixels
- **FR-040**: Screen MUST handle keyboard appearance without obscuring content
- **FR-041**: Empty state MUST be shown when no projects exist
- **FR-042**: No results state MUST be shown when search returns empty
- **FR-043**: Screen MUST support pull-to-refresh for updating project list

### Key Entities

- **Project**: Contains id, title, description, status, image, updatedAt, teamInfo
- **User**: Authenticated user with access token and language preference
- **ProjectStatus**: Enum of Active, Paused, Archived

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Project list loads within 2 seconds of authentication completing
- **SC-002**: Search results update within 300ms of user typing
- **SC-003**: Filter changes apply instantly (< 100ms)
- **SC-004**: Screen maintains 60fps performance with smooth scrolling
- **SC-005**: All interactive elements are tappable without precision issues (measured by successful tap rate >98%)
- **SC-006**: 100% of interactive elements are discoverable by screen readers with meaningful labels
- **SC-007**: Project images load progressively without blocking UI
- **SC-008**: Empty and error states provide clear next actions for users

## Assumptions

- Design screenshot (Requirements/Projectlist.jpg) is the single source of truth for visual design
- GraphQL API provides projects query with authentication
- User access token is stored securely and available from AuthService
- Projects have required fields: id, title, description, status, imageUrl, updatedAt
- Language preference is stored with user account or derived from device locale
- Bottom navigation destinations (LiDAR, Profile, Project Detail) exist or will be created
- Standard iOS/Flutter scrolling and keyboard behavior is sufficient
- App supports iOS devices running version 15.0 or later
- Project images are served from CDN with appropriate caching headers
- Initial implementation shows all projects without pagination (pagination added later if needed)

## Dependencies

- **Depends on**: Authentication (UC2) must be complete to provide access token
- **Depends on**: GraphQL API must provide projects query
- **Blocks**: Project detail screen, Create project screen, LiDAR screen, Profile screen navigation
- **External**: Backend API must be available at configured endpoint
- **External**: i18n strings must be defined for all supported languages (de, en, pt)
