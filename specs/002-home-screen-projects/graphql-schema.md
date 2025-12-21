# GraphQL Schema Documentation - Projects

This document describes the GraphQL queries and mutations used for the home screen project list feature.

## Authentication

All queries require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer <AUTH_CODE>
```

The AUTH_CODE is automatically added by the GraphQLService after user login.

## Platform Header

All requests include the platform identifier:
```
X-VRon-Platform: merchants
```

---

## Queries

### GetProjects

Fetches all projects for the authenticated user.

**Query:**
```graphql
query GetProjects {
  projects {
    id
    title
    description
    status
    imageUrl
    updatedAt
    teamInfo
  }
}
```

**Response:**
```json
{
  "data": {
    "projects": [
      {
        "id": "proj_123",
        "title": "Marketing Analytics",
        "description": "Realtime overview of campaign performance.",
        "status": "active",
        "imageUrl": "https://cdn.vron.one/projects/proj_123/thumbnail.jpg",
        "updatedAt": "2025-12-20T10:30:00Z",
        "teamInfo": "4 teammates"
      },
      {
        "id": "proj_456",
        "title": "Product Roadmap",
        "description": "Plan feature releases across quarters.",
        "status": "paused",
        "imageUrl": "https://cdn.vron.one/projects/proj_456/thumbnail.jpg",
        "updatedAt": "2025-12-19T15:45:00Z",
        "teamInfo": "7 teammates"
      }
    ]
  }
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique project identifier |
| title | String | Yes | Project name/title |
| description | String | No | Short project description (2-3 lines max) |
| status | String | No | Project status: "active", "paused", or "archived" (default: "active") |
| imageUrl | String | No | URL to project thumbnail image |
| updatedAt | String | No | ISO 8601 timestamp of last update |
| teamInfo | String | No | Team information (e.g., "4 teammates", "Solo") |

**Error Responses:**

1. **Unauthenticated:**
```json
{
  "errors": [
    {
      "message": "Authentication required",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ]
}
```

2. **Invalid Token:**
```json
{
  "errors": [
    {
      "message": "Invalid or expired token",
      "extensions": {
        "code": "INVALID_TOKEN"
      }
    }
  ]
}
```

3. **Server Error:**
```json
{
  "errors": [
    {
      "message": "Internal server error",
      "extensions": {
        "code": "INTERNAL_SERVER_ERROR"
      }
    }
  ]
}
```

---

## Client-Side Filtering

The mobile app performs client-side filtering for:
- **Search**: Filter projects by title (case-insensitive substring match)
- **Status Filter**: Filter by status (All, Active, Paused, Archived)

Server-side filtering may be added in future iterations for better performance with large datasets.

---

## Future Enhancements

Planned GraphQL additions:
1. **Pagination**: Add `first`, `after`, `last`, `before` arguments for cursor-based pagination
2. **Sorting**: Add `orderBy` and `orderDirection` arguments
3. **Server-side filtering**: Add `where` argument for complex filters
4. **Subscriptions**: Real-time updates when projects change
5. **Project mutations**: Create, update, delete projects

Example future query:
```graphql
query GetProjects(
  $first: Int
  $after: String
  $orderBy: ProjectOrderField
  $orderDirection: OrderDirection
  $where: ProjectWhereInput
) {
  projects(
    first: $first
    after: $after
    orderBy: $orderBy
    orderDirection: $orderDirection
    where: $where
  ) {
    edges {
      node {
        id
        title
        description
        status
        imageUrl
        updatedAt
        teamInfo
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
    totalCount
  }
}
```

---

## Testing

For development/testing, ensure the backend API supports:
1. Mock data with diverse project statuses
2. Projects with and without images
3. Projects with various team sizes
4. Projects with different update timestamps
5. Error scenarios (auth failures, network errors)

Test credentials from 001-main-screen-login can be used to authenticate and fetch projects.
