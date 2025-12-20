<!--
Sync Impact Report
==================
Version Change: 0.0.0 (initial template) → 1.0.0 (first ratified version)
Rationale: MAJOR bump - Initial adoption of comprehensive constitution for Flutter mobile project

Modified Principles:
- NEW: I. Test-First Development (NON-NEGOTIABLE)
- NEW: II. Simplicity & YAGNI
- NEW: III. Platform-Native Patterns

Added Sections:
- Security & Privacy Requirements
- Performance Standards
- Accessibility Requirements
- CI/CD & DevOps Practices
- Governance

Removed Sections: None (initial creation from template)

Templates Status:
✅ plan-template.md - Reviewed, Constitution Check section aligns with principles
✅ spec-template.md - Reviewed, requirements structure supports constitution compliance
✅ tasks-template.md - Reviewed, task organization supports TDD and story-driven development

Follow-up TODOs: None
-->

# VronMobile2 Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

Test-Driven Development (TDD) is mandatory for all feature implementation:

- Tests MUST be written before implementation code
- Tests MUST fail initially, demonstrating the feature gap
- Implementation proceeds only after test failure is confirmed
- Red-Green-Refactor cycle is strictly enforced:
  1. **Red**: Write a failing test that defines desired behavior
  2. **Green**: Write minimal code to make the test pass
  3. **Refactor**: Improve code quality while keeping tests green
- Widget tests are required for UI components
- Integration tests are required for user journeys spanning multiple screens
- Unit tests are required for business logic, services, and utilities

**Rationale**: TDD ensures code quality, prevents regression, provides living documentation, and gives confidence in refactoring. In mobile development where manual testing is time-intensive, automated tests are essential for rapid iteration.

### II. Simplicity & YAGNI

Start simple and avoid premature optimization or over-engineering:

- Implement only what is explicitly required by current user stories
- Reject abstractions until the need is proven by at least three concrete use cases
- Prefer Flutter's built-in widgets and patterns over custom implementations
- Avoid creating "framework" code for hypothetical future requirements
- Three similar code blocks are better than a premature abstraction
- Delete unused code completely—no commented-out code, no "just in case" utilities
- Question every dependency: do we truly need this package?

**Rationale**: Mobile apps must remain lightweight and maintainable. Every abstraction adds cognitive load and increases binary size. Simple code is easier to understand, debug, and modify. YAGNI (You Aren't Gonna Need It) prevents scope creep and keeps the codebase lean.

### III. Platform-Native Patterns

Embrace Flutter and Dart idioms while respecting platform conventions:

- Use Flutter's widget composition patterns (not inheritance)
- Follow Dart's effective style guide for naming and structure
- Respect platform-specific UI patterns:
  - Material Design for Android
  - Cupertino widgets for iOS where appropriate
  - Platform-adaptive widgets when cross-platform consistency matters
- State management should be explicit and predictable (Provider, Riverpod, Bloc, or built-in setState)
- Async operations must use Dart's Future/Stream/async-await patterns
- Handle platform differences explicitly (Platform.isIOS, Platform.isAndroid)
- File structure follows feature-based organization (not layer-based)

**Rationale**: Flutter provides powerful patterns that, when followed, lead to maintainable and performant apps. Fighting the framework leads to brittle code. Platform conventions ensure users feel at home on their device.

## Security & Privacy Requirements

Mobile applications handle sensitive user data and must prioritize security:

- **Secure Storage**: Use flutter_secure_storage for sensitive data (tokens, keys, credentials)
- **Network Security**: All API calls MUST use HTTPS with certificate pinning for critical endpoints
- **Input Validation**: Validate all user input and sanitize data before storage or transmission
- **Authentication**: Implement secure token management with automatic refresh and proper expiration against graphql endpoints
- **Permissions**: Request only necessary permissions with clear user-facing justification
- **Privacy**: Collect minimum data required; provide clear privacy disclosures
- **Code Obfuscation**: Enable code obfuscation for production builds
- **Secrets Management**: NEVER commit secrets, API keys, or credentials to version control
- **Dependency Auditing**: Regularly audit third-party packages for known vulnerabilities

**Compliance**: Follow OWASP Mobile Security guidelines and applicable privacy regulations (GDPR, CCPA).

## Performance Standards

Mobile apps must be responsive and efficient to provide good user experience:

- **App Launch**: Cold start < 3 seconds, warm start < 1 second
- **Frame Rate**: Maintain 60 fps (16ms frame budget) for all animations and scrolling
- **Build Size**: Monitor APK/IPA size; investigate if binary exceeds 50MB
- **Memory Usage**: Profile memory usage; avoid leaks and unnecessary allocations
- **Battery Efficiency**: Minimize background processing and network polling
- **Network Efficiency**: Implement caching, compression, and pagination for API calls
- **Image Optimization**: Use appropriate image formats and resolutions; implement lazy loading
- **Build Performance**: Development build times should remain under 30 seconds for hot reload

**Measurement**: Use Flutter DevTools for profiling. Performance regressions caught in code review are blockers.

## Accessibility Requirements

Apps must be usable by everyone, including users with disabilities:

- **Screen Reader Support**: All interactive widgets must have semantic labels
- **Contrast Ratios**: Text must meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
- **Touch Targets**: Minimum 44x44 logical pixels for all interactive elements
- **Keyboard Navigation**: Support external keyboard navigation where applicable
- **Dynamic Text**: Respect user's font size preferences (textScaleFactor)
- **Color Independence**: Never rely solely on color to convey information
- **Focus Management**: Logical focus order for screen readers
- **Testing**: Use Flutter's semantic tree for automated accessibility testing

**Compliance**: Target WCAG 2.1 Level AA compliance for all user-facing features.

## CI/CD & DevOps Practices

Automated pipelines ensure consistent quality and enable rapid delivery:

- **Version Control**: All code resides in Git; trunk-based development with feature branches
- **Branch Strategy**: Branch naming: `###-feature-name` where ### is issue/task number
- **Commit Discipline**: Atomic commits with clear messages; commit after each logical task
- **Build Automation**: CI pipeline runs on every to dev stage or main branch PR: 
  - Linting and code formatting checks
  - Unit and widget tests
  - Integration tests (if applicable)
  - Build verification for iOS and Android
- **Code Review**: All changes require peer review before merge
- **Release Management**: Semantic versioning (MAJOR.MINOR.PATCH+BUILD)
  - MAJOR: Breaking changes or major feature releases
  - MINOR: New features, backward compatible
  - PATCH: Bug fixes
  - BUILD: Incremental build number for stores
- **Deployment**: Automated deployment to TestFlight (iOS) and Internal Testing (Android) on main branch
- **Rollback Plan**: Maintain ability to roll back to previous version within 1 hour

## Governance

This constitution is the authoritative source of development standards for the VronMobile2 project.

### Amendment Procedure

1. Proposed amendments must be documented with rationale
2. Team review and discussion of impact
3. Update constitution with new version number following semantic versioning
4. Update all dependent templates and documentation
5. Communicate changes to all team members

### Versioning Policy

- **MAJOR**: Backward incompatible changes, principle removal, or fundamental redefinitions
- **MINOR**: New principles added, materially expanded guidance, new requirement sections
- **PATCH**: Clarifications, wording improvements, typo fixes, non-semantic refinements

### Compliance Review

- All pull requests MUST verify compliance with this constitution
- Code reviewers are empowered to block PRs that violate principles
- Any complexity or violation MUST be justified in plan.md (see Complexity Tracking section)
- Constitution review occurs quarterly to ensure relevance and effectiveness

### Guidance References

- Runtime development guidance: Refer to project README.md and Flutter best practices documentation
- Design workflows: Follow templates in `.specify/templates/`
- Planning: Use plan-template.md for feature planning and architecture decisions

**Version**: 1.0.0 | **Ratified**: 2025-12-20 | **Last Amended**: 2025-12-20
