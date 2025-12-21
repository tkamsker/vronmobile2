# Feature Specification: Create Product

**Feature Branch**: `013-create-product`
**Created**: 2025-12-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Product Creation Form (Priority: P1)

User fills form to create new product with name, description, price, images, categories.

**Why this priority**: Enables adding products to shop.

**Independent Test**: Open form, fill fields, submit, verify product created.

**Acceptance Scenarios**:

1. **Given** user on products list, **When** taps "Create Product", **Then** form displayed
2. **Given** form displayed, **When** user fills and submits, **Then** createProduct mutation called
3. **Given** images selected, **When** uploading, **Then** images uploaded and IDs included in mutation

### Edge Cases

- Image upload fails
- Form validation errors
- Very large images
- Network failure during creation

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display form per Figma design
- **FR-002**: System MUST validate per Zod schema from web app
- **FR-003**: System MUST upload images via multipart request
- **FR-004**: System MUST call createProduct mutation with form data
- **FR-005**: System MUST handle upload progress indication

### GraphQL Contract

```graphql
mutation createProduct($input: CreateProductInput!) {
  createProduct(data: $input) {
    id name
  }
}
```

## Success Criteria *(mandatory)*

- **SC-001**: Form submission completes within 10 seconds
- **SC-002**: Image uploads show progress
- **SC-003**: Validation prevents invalid submissions 100%

## Dependencies

- **Depends on**: UC12 (View Products)
- **Depends on**: Backend createProduct mutation, image upload endpoint
