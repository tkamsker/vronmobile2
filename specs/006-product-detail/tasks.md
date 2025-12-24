# Tasks: Product Detail and Management

**Input**: Design documents from `/specs/004-product-detail/`
**Prerequisites**: plan.md, spec.md, data-model.md
**Based on**: Products list feature (003-projectdetail)

**Tests**: TDD is MANDATORY per constitution - tests must be written FIRST and FAIL before implementation

**Organization**: Tasks are grouped by phase to enable sequential implementation

---

## Format: `[ID] [P?] [Phase] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Phase]**: Which phase this task belongs to (e.g., P1, P2, P3)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile project with feature-based organization:
- `lib/features/products/` - Existing products feature (extended)
- `test/features/products/` - Product tests
- Follow patterns from `003-projectdetail`

---

## Phase 1: Foundation (Models & Service)

**Purpose**: Create data models and service layer for product details

### Tests for Models (TDD - Write First, Ensure FAIL)

- [ ] T001 [P] [P1] Write failing test for MediaFile model fromJson parsing in test/features/products/models/media_file_test.dart
- [ ] T002 [P] [P1] Write failing test for MediaFile.isImage helper in test/features/products/models/media_file_test.dart
- [ ] T003 [P] [P1] Write failing test for MediaFile.formattedSize helper in test/features/products/models/media_file_test.dart
- [ ] T004 [P] [P1] Write failing test for ProductVariant model fromJson in test/features/products/models/product_variant_test.dart
- [ ] T005 [P] [P1] Write failing test for ProductVariant.hasDiscount calculation in test/features/products/models/product_variant_test.dart
- [ ] T006 [P] [P1] Write failing test for ProductVariant.inventoryStatusLabel in test/features/products/models/product_variant_test.dart
- [ ] T007 [P] [P1] Write failing test for ProductDetail model fromJson in test/features/products/models/product_detail_test.dart
- [ ] T008 [P] [P1] Write failing test for ProductDetail parsing with null fields in test/features/products/models/product_detail_test.dart

### Implementation for Models

- [ ] T009 [P] [P1] Create MediaFile model class in lib/features/products/models/media_file.dart
- [ ] T010 [P] [P1] Implement MediaFile.fromJson factory in lib/features/products/models/media_file.dart
- [ ] T011 [P] [P1] Implement MediaFile helper methods (isImage, formattedSize) in lib/features/products/models/media_file.dart
- [ ] T012 [P1] Run MediaFile tests - T001-T003 should now PASS

- [ ] T013 [P] [P1] Create ProductVariant model class in lib/features/products/models/product_variant.dart
- [ ] T014 [P] [P1] Implement ProductVariant.fromJson factory in lib/features/products/models/product_variant.dart
- [ ] T015 [P] [P1] Implement ProductVariant helper methods (hasDiscount, inventoryStatusLabel) in lib/features/products/models/product_variant.dart
- [ ] T016 [P1] Run ProductVariant tests - T004-T006 should now PASS

- [ ] T017 [P] [P1] Create ProductDetail model class in lib/features/products/models/product_detail.dart
- [ ] T018 [P] [P1] Implement ProductDetail.fromJson factory in lib/features/products/models/product_detail.dart
- [ ] T019 [P1] Run ProductDetail tests - T007-T008 should now PASS

**Checkpoint**: ✅ All model tests passing - Foundation models ready

### Tests for Service (TDD - Write First, Ensure FAIL)

- [ ] T020 [P] [P1] Write failing test for getProductDetail success in test/features/products/services/product_detail_service_test.dart
- [ ] T021 [P] [P1] Write failing test for getProductDetail with 404 error in test/features/products/services/product_detail_service_test.dart
- [ ] T022 [P] [P1] Write failing test for getProductDetail with network error in test/features/products/services/product_detail_service_test.dart

### Implementation for Service

- [ ] T023 [P1] Create ProductDetailService class in lib/features/products/services/product_detail_service.dart
- [ ] T024 [P1] Add VRonGetProduct GraphQL query constant in lib/features/products/services/product_detail_service.dart
- [ ] T025 [P1] Implement getProductDetail method with error handling in lib/features/products/services/product_detail_service.dart
- [ ] T026 [P1] Run service tests - T020-T022 should now PASS

**Checkpoint**: ✅ Phase 1 complete - Models and service layer ready

---

## Phase 2: Core Screen (User Story 1 - MVP)

**Purpose**: Implement basic product detail screen with navigation

### Tests for Screen (TDD - Write First, Ensure FAIL)

- [ ] T027 [P] [P2] Write failing test for ProductDetailScreen loading state in test/features/products/screens/product_detail_screen_test.dart
- [ ] T028 [P] [P2] Write failing test for ProductDetailScreen displaying product data in test/features/products/screens/product_detail_screen_test.dart
- [ ] T029 [P] [P2] Write failing test for ProductDetailScreen error state in test/features/products/screens/product_detail_screen_test.dart
- [ ] T030 [P] [P2] Write failing test for ProductDetailScreen refresh functionality in test/features/products/screens/product_detail_screen_test.dart

### Tests for Header Widget (TDD - Write First, Ensure FAIL)

- [ ] T031 [P] [P2] Write failing test for ProductDetailHeader rendering in test/features/products/widgets/product_detail_header_test.dart
- [ ] T032 [P] [P2] Write failing test for ProductDetailHeader status badge in test/features/products/widgets/product_detail_header_test.dart
- [ ] T033 [P] [P2] Write failing test for ProductDetailHeader with null thumbnail in test/features/products/widgets/product_detail_header_test.dart

### Implementation for Core Screen

- [ ] T034 [P] [P2] Add productDetail route to AppRoutes in lib/core/navigation/routes.dart
- [ ] T035 [P] [P2] Register ProductDetailScreen route in MaterialApp routes in lib/main.dart
- [ ] T036 [P2] Create ProductDetailScreen with StatefulWidget in lib/features/products/screens/product_detail_screen.dart
- [ ] T037 [P2] Implement loading, error, and success states in ProductDetailScreen in lib/features/products/screens/product_detail_screen.dart
- [ ] T038 [P2] Implement pull-to-refresh functionality in ProductDetailScreen in lib/features/products/screens/product_detail_screen.dart
- [ ] T039 [P2] Add comprehensive Semantics labels to ProductDetailScreen in lib/features/products/screens/product_detail_screen.dart

- [ ] T040 [P] [P2] Create ProductDetailHeader widget in lib/features/products/widgets/product_detail_header.dart
- [ ] T041 [P] [P2] Implement title, thumbnail, and status display in ProductDetailHeader in lib/features/products/widgets/product_detail_header.dart
- [ ] T042 [P] [P2] Add Semantics labels to ProductDetailHeader in lib/features/products/widgets/product_detail_header.dart

- [ ] T043 [P2] Update ProductCard to navigate to detail screen with product ID in lib/features/products/widgets/product_card.dart

### Test Verification

- [ ] T044 [P2] Run all screen tests - T027-T030 should now PASS
- [ ] T045 [P2] Run header widget tests - T031-T033 should now PASS
- [ ] T046 [P2] Run flutter analyze to check for linting errors
- [ ] T047 [P2] Manual test: Navigate to product detail and verify display

**Checkpoint**: ✅ Phase 2 complete - MVP product detail screen functional

---

## Phase 3: Media Gallery (User Story 2)

**Purpose**: Display product images in a gallery format

### Tests for Media Gallery (TDD - Write First, Ensure FAIL)

- [ ] T048 [P] [P3] Write failing test for ProductMediaGallery rendering images in test/features/products/widgets/product_media_gallery_test.dart
- [ ] T049 [P] [P3] Write failing test for ProductMediaGallery empty state in test/features/products/widgets/product_media_gallery_test.dart
- [ ] T050 [P] [P3] Write failing test for ProductMediaGallery tap to full-screen in test/features/products/widgets/product_media_gallery_test.dart
- [ ] T051 [P] [P3] Write failing test for ProductMediaGallery image placeholders in test/features/products/widgets/product_media_gallery_test.dart

### Implementation for Media Gallery

- [ ] T052 [P] [P3] Create ProductMediaGallery widget in lib/features/products/widgets/product_media_gallery.dart
- [ ] T053 [P] [P3] Implement image grid layout with cached_network_image in lib/features/products/widgets/product_media_gallery.dart
- [ ] T054 [P] [P3] Implement tap to full-screen image view in lib/features/products/widgets/product_media_gallery.dart
- [ ] T055 [P] [P3] Add image loading placeholders in lib/features/products/widgets/product_media_gallery.dart
- [ ] T056 [P] [P3] Create empty state for no media in lib/features/products/widgets/product_media_gallery.dart
- [ ] T057 [P] [P3] Add Semantics labels to ProductMediaGallery in lib/features/products/widgets/product_media_gallery.dart

- [ ] T058 [P3] Integrate ProductMediaGallery into ProductDetailScreen in lib/features/products/screens/product_detail_screen.dart

### Test Verification

- [ ] T059 [P3] Run media gallery tests - T048-T051 should now PASS
- [ ] T060 [P3] Run flutter analyze to check for linting errors
- [ ] T061 [P3] Manual test: Verify images load and full-screen works

**Checkpoint**: ✅ Phase 3 complete - Media gallery functional

---

## Phase 4: Variants Section (User Story 3)

**Purpose**: Display product variants with pricing and inventory

### Tests for Variants Section (TDD - Write First, Ensure FAIL)

- [ ] T062 [P] [P4] Write failing test for ProductVariantsSection rendering variants in test/features/products/widgets/product_variants_section_test.dart
- [ ] T063 [P] [P4] Write failing test for ProductVariantsSection empty state in test/features/products/widgets/product_variants_section_test.dart
- [ ] T064 [P] [P4] Write failing test for ProductVariantsSection price formatting in test/features/products/widgets/product_variants_section_test.dart
- [ ] T065 [P] [P4] Write failing test for ProductVariantsSection discount display in test/features/products/widgets/product_variants_section_test.dart
- [ ] T066 [P] [P4] Write failing test for ProductVariantsSection inventory status in test/features/products/widgets/product_variants_section_test.dart

### Implementation for Variants Section

- [ ] T067 [P] [P4] Create ProductVariantsSection widget in lib/features/products/widgets/product_variants_section.dart
- [ ] T068 [P] [P4] Implement variant list display with SKU, price, inventory in lib/features/products/widgets/product_variants_section.dart
- [ ] T069 [P] [P4] Add discount badge for compareAtPrice in lib/features/products/widgets/product_variants_section.dart
- [ ] T070 [P] [P4] Implement inventory status display with color coding in lib/features/products/widgets/product_variants_section.dart
- [ ] T071 [P] [P4] Add price formatting with currency in lib/features/products/widgets/product_variants_section.dart
- [ ] T072 [P] [P4] Create empty state for no variants in lib/features/products/widgets/product_variants_section.dart
- [ ] T073 [P] [P4] Add Semantics labels to ProductVariantsSection in lib/features/products/widgets/product_variants_section.dart

- [ ] T074 [P4] Integrate ProductVariantsSection into ProductDetailScreen in lib/features/products/screens/product_detail_screen.dart

### Test Verification

- [ ] T075 [P4] Run variants section tests - T062-T066 should now PASS
- [ ] T076 [P4] Run flutter analyze to check for linting errors
- [ ] T077 [P4] Manual test: Verify variants display correctly

**Checkpoint**: ✅ Phase 4 complete - Variants section functional

---

## Phase 5: Metadata Section (User Story 4)

**Purpose**: Display product metadata and settings

### Tests for Metadata Section (TDD - Write First, Ensure FAIL)

- [ ] T078 [P] [P5] Write failing test for ProductMetadataSection rendering in test/features/products/widgets/product_metadata_section_test.dart
- [ ] T079 [P] [P5] Write failing test for ProductMetadataSection tags display in test/features/products/widgets/product_metadata_section_test.dart
- [ ] T080 [P] [P5] Write failing test for ProductMetadataSection date formatting in test/features/products/widgets/product_metadata_section_test.dart
- [ ] T081 [P] [P5] Write failing test for ProductMetadataSection product ID copy in test/features/products/widgets/product_metadata_section_test.dart

### Tests for Tag Chip (TDD - Write First, Ensure FAIL)

- [ ] T082 [P] [P5] Write failing test for ProductTagChip rendering in test/features/products/widgets/product_tag_chip_test.dart
- [ ] T083 [P] [P5] Write failing test for ProductTagChip accessibility in test/features/products/widgets/product_tag_chip_test.dart

### Implementation for Metadata Section

- [ ] T084 [P] [P5] Create ProductTagChip widget in lib/features/products/widgets/product_tag_chip.dart
- [ ] T085 [P] [P5] Add Semantics labels to ProductTagChip in lib/features/products/widgets/product_tag_chip.dart

- [ ] T086 [P] [P5] Create ProductMetadataSection widget in lib/features/products/widgets/product_metadata_section.dart
- [ ] T087 [P] [P5] Display category, tags, and tracking status in lib/features/products/widgets/product_metadata_section.dart
- [ ] T088 [P] [P5] Implement date formatting (relative time) in lib/features/products/widgets/product_metadata_section.dart
- [ ] T089 [P] [P5] Add product ID with copy functionality in lib/features/products/widgets/product_metadata_section.dart
- [ ] T090 [P] [P5] Add Semantics labels to ProductMetadataSection in lib/features/products/widgets/product_metadata_section.dart

- [ ] T091 [P5] Integrate ProductMetadataSection into ProductDetailScreen in lib/features/products/screens/product_detail_screen.dart

### Test Verification

- [ ] T092 [P5] Run metadata section tests - T078-T081 should now PASS
- [ ] T093 [P5] Run tag chip tests - T082-T083 should now PASS
- [ ] T094 [P5] Run flutter analyze to check for linting errors
- [ ] T095 [P5] Manual test: Verify metadata displays correctly

**Checkpoint**: ✅ Phase 5 complete - Metadata section functional

---

## Phase 6: Polish & Testing

**Purpose**: Final improvements and comprehensive testing

- [ ] T096 [P] Run complete test suite: flutter test
- [ ] T097 [P] Run flutter analyze and fix all issues
- [ ] T098 [P] Test on multiple screen sizes (phone, tablet)
- [ ] T099 [P] Verify accessibility with TalkBack (Android)
- [ ] T100 [P] Verify accessibility with VoiceOver (iOS)
- [ ] T101 [P] Test image loading with slow network simulation
- [ ] T102 [P] Test error scenarios (404, network failure, unauthorized)
- [ ] T103 [P] Performance profiling - ensure 60fps scrolling
- [ ] T104 [P] Performance profiling - measure load time (< 2s target)
- [ ] T105 [P] Memory profiling - check for leaks
- [ ] T106 [P] Update CLAUDE.md with new patterns/decisions
- [ ] T107 Write integration test for products list → detail → back in test/integration/product_detail_journey_test.dart
- [ ] T108 Code cleanup: Remove debug prints and commented code
- [ ] T109 Create PR with summary of changes and test results

**Checkpoint**: ✅ Phase 6 complete - All polish and testing done

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundation)**: No dependencies - can start immediately - BLOCKS all other phases
- **Phase 2 (Core Screen)**: Depends on Phase 1 completion
- **Phase 3 (Media Gallery)**: Depends on Phase 2 completion
- **Phase 4 (Variants)**: Depends on Phase 2 completion (can run parallel with P3)
- **Phase 5 (Metadata)**: Depends on Phase 2 completion (can run parallel with P3/P4)
- **Phase 6 (Polish)**: Depends on all previous phases

### Within Each Phase

**TDD Cycle (MANDATORY)**:
1. **Red**: Write failing tests first
2. **Green**: Implement minimum code to pass tests
3. **Refactor**: Clean up while keeping tests green

**Implementation Order**:
- Tests FIRST (must FAIL before implementation)
- Models/Services (foundation for logic)
- Widgets (UI components)
- Integration (wire everything together)
- Polish (final touches)

### Parallel Opportunities

#### Within Phase 1 (Foundation)
- Model tests T001-T008 can run in parallel (different test files)
- Model implementations T009-T019 can run in parallel (different model files)

#### Within Phase 2 (Core Screen)
- Screen tests T027-T030 and Header tests T031-T033 can run in parallel
- Route setup T034-T035 can run parallel with widget creation T040-T042

#### Across Phases 3-5
Once Phase 2 complete:
- Phase 3 (Media Gallery)
- Phase 4 (Variants Section)
- Phase 5 (Metadata Section)
Can all run in parallel if multiple developers available

#### Within Phase 6 (Polish)
All polish tasks T096-T105 can run in parallel (different aspects)

---

## Implementation Strategy

### MVP First (Phase 1-2)

1. Complete Phase 1: Foundation (2-3 hours)
2. Complete Phase 2: Core Screen MVP (3-4 hours)
3. **STOP and VALIDATE**: Test basic detail view
4. Deploy/demo MVP

**Time Estimate**: 5-7 hours for MVP

### Incremental Delivery

1. Foundation → Models and service ready (2-3 hours)
2. Core Screen → Test independently → Deploy MVP (3-4 hours)
3. Media Gallery → Test independently → Deploy (3-4 hours)
4. Variants Section → Test independently → Deploy (2-3 hours)
5. Metadata Section → Test independently → Deploy (1-2 hours)
6. Polish & Testing → Final release (2-3 hours)

**Total Time Estimate**: 13-19 hours

### Parallel Team Strategy

With 2-3 developers:

1. **Together**: Complete Phase 1 Foundation (2-3 hours)
2. **Together**: Complete Phase 2 Core Screen (3-4 hours)
3. **Split**:
   - Dev A: Phase 3 Media Gallery (3-4 hours)
   - Dev B: Phase 4 Variants Section (2-3 hours)
   - Dev C: Phase 5 Metadata Section (1-2 hours)
4. **Together**: Phase 6 Polish and testing (2-3 hours)

**Total Time with Parallel**: 8-12 hours

---

## TDD Compliance Checklist

✅ All test tasks explicitly marked "Write failing test"
✅ Tests ordered before implementation within each phase
✅ "Ensure FAIL" reminders in test sections
✅ Explicit verification tasks to run tests and confirm PASS
✅ Red-Green-Refactor cycle enforced
✅ Integration tests included for full user journeys

---

## Notes

- **[P] tasks** = different files, no dependencies, can run in parallel
- **TDD is non-negotiable** per constitution - tests MUST be written first
- Each phase is independently completable and testable
- Verify tests fail (RED) before implementing (GREEN)
- Refactor while keeping tests green
- Commit after each logical task or group
- Stop at any checkpoint to validate independently
- All images must load over HTTPS
- Handle null values gracefully throughout
- Format prices with proper currency symbols
- Use relative dates where appropriate (e.g., "2 days ago")
