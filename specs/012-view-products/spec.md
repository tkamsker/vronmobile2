# Feature Specification: View Products

**Feature Branch**: `012-view-products`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Products List (Priority: P1)

User views list of products associated with project/merchant in grid or list view.

**Why this priority**: Core product browsing functionality.

**Independent Test**: Navigate to products, verify list displays in grid/list format.

**Acceptance Scenarios**:

1. **Given** user on project detail, **When** taps "Products", **Then** products list displayed
2. **Given** products exist, **When** list loads, **Then** each product shows name, price, image
3. **Given** user preference, **When** viewing, **Then** can toggle grid/list view

### Edge Cases

- No products exist
- Product images fail to load
- Large product catalog

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST call products/shopProducts query
- **FR-002**: System MUST display products in grid and list views
- **FR-003**: System MUST show product name, price, images
- **FR-004**: System MUST support pagination
- **FR-005**: System MUST provide "Create Product" button

### GraphQL Contract

```graphql
query productsByShop($shopId: ID!, $limit: Int, $offset: Int) {
  products(shopId: $shopId, limit: $limit, offset: $offset) {
    id name description price
    images { url }
  }
}
```

## Success Criteria *(mandatory)*

- **SC-001**: Products load within 2 seconds
- **SC-002**: View toggle works instantly
- **SC-003**: Smooth scrolling at 60fps

## Dependencies

- **Depends on**: UC10 (Project Detail)
- **Blocks**: UC13 (Create Product)
