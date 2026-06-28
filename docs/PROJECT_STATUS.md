# Project Status — Sunsets AI

**Last updated:** 2026-06-27
**Current milestone:** Milestone 2 — Local SunsetsAIKeyboard Extension ✅ (awaiting approval — corrections applied)

---

## Current Phase

Milestone 1 is **approved and complete** (2026-06-27). The local Sunsets Properties SwiftUI application was manually validated by Nox on 2026-06-27. All acceptance criteria confirmed on iPhone Simulator.

Milestone 1.1 is **approved and complete** (2026-06-27). Manually validated by Nox on 2026-06-27. All acceptance criteria confirmed on iPhone 17 Simulator.

Milestone 1.1 refinements (pet policy, sale financing, FHA) are **approved and complete** (2026-06-27). Manually validated by Nox on 2026-06-27. Milestone 2 may now begin.

---

## Completed Work

### Milestone 0 — Documentation and Architecture ✅ Approved 2026-06-27

- [x] `CLAUDE.md` — Engineering rules for all Claude sessions
- [x] `README.md` — Project overview
- [x] `.gitignore` — Xcode, Swift, Node, Supabase, secrets
- [x] `docs/PRODUCT_SPEC.md` — Full product requirements and acceptance criteria
- [x] `docs/ARCHITECTURE.md` — System architecture, component boundaries, data flows
- [x] `docs/DECISIONS.md` — 9 Architecture Decision Records (ADR-000 through ADR-008)
- [x] `docs/API_CONTRACTS.md` — Future backend API schemas (not implemented)
- [x] `docs/SECURITY_AND_PRIVACY.md` — Security posture and privacy rules
- [x] `docs/TESTING.md` — Test strategy and manual testing requirements
- [x] `docs/PROPERTY_SCHEMA.md` — Canonical property data model, keyboard-safe projection, templates
- [x] `docs/MILESTONES.md` — 7 milestones (0–6) with scope, exclusions, acceptance criteria, risks
- [x] `docs/PROJECT_STATUS.md` — This file
- [x] All Milestone 0 decisions resolved (ADR-008): deployment target, bundle IDs, App Group, locale, keyboard-cache exclusions, privacy policy timeline

### Milestone 1 — Local Sunsets Properties Application ✅ Approved 2026-06-27

- [x] Xcode project with `SunsetsProperties` target (SwiftUI, iOS 17+, iPhone only)
- [x] `Property`, `KeyboardProperty`-compatible domain models (`Codable`, `Identifiable`, `Equatable`)
- [x] Supporting types: `PropertyStatus`, `OperationType`, `PetPolicy`, `QuickReplyTemplate`, `TemplateCategory`
- [x] `PropertyRepository` protocol for dependency injection
- [x] `LocalPropertyRepository` — JSON file in Application Support, `UserDefaults` for active ID and employee
- [x] `MockPropertyRepository` equivalent via seed data (`SeedData.swift`) with 6 sample properties
- [x] SwiftUI catalog view with search (title, code, location) and filter (9 filter options)
- [x] Property detail view (all non-sensitive fields)
- [x] Property creation and editing form with validation
- [x] Status change from editor form
- [x] Active property selection with warning for non-available properties
- [x] Active property cleared on delete; persists across app launches
- [x] Keyboard setup guide screen (static, non-functional settings links)
- [x] Mocked employee selector (Cristian / Yessy), persisted locally
- [x] `CatalogViewModel`, `ActivePropertyViewModel`, `PropertyEditorViewModel`
- [x] Reusable `StatusBadge`, `OperationBadge`, `EmptyStateView` components
- [x] `AppFormatters` — currency (GTQ/USD), area (m²), dates (es-GT), bathrooms
- [x] Spanish-first UI throughout
- [x] Unit tests: 46 tests across 7 suites — all pass
- [x] UI tests: launch and launch-performance — pass
- [x] Build: `** BUILD SUCCEEDED **` for iPhone 17 Pro Simulator

### Milestone 1.1 — Property Enrichment and Import ✅ Approved 2026-06-27

**Documentation (from prior session):**
- [x] `docs/PRODUCT_SPEC.md` v0.3
- [x] `docs/ARCHITECTURE.md` v0.3
- [x] `docs/PROPERTY_SCHEMA.md` v0.3
- [x] `docs/DECISIONS.md` — ADR-009 through ADR-013
- [x] `docs/MILESTONES.md` v0.3
- [x] `docs/SECURITY_AND_PRIVACY.md` v0.3
- [x] `docs/TESTING.md` v0.3
- [x] `docs/API_CONTRACTS.md` v0.3

**Implementation:**
- [x] `Models/LocationSource.swift` — NEW
- [x] `Models/PropertyDraft.swift` — NEW (`DraftField<T>`, `DraftConfidence`, `PropertyDraft`)
- [x] `Models/Property.swift` — 12 new fields; custom decoder in extension preserves memberwise init
- [x] `Repositories/PropertyRepository.swift` — `nextInternalCode()`, `isInternalCodeUnique()` added
- [x] `Repositories/LocalPropertyRepository.swift` — migration, backup, `lastIssuedInternalCodeNumber` counter
- [x] `Services/InternalCodeService.swift` — NEW (`SUN-###` format/extract utilities)
- [x] `Services/GoogleMapsURLParser.swift` — NEW (parses `?q=` and `/@` formats; no network; no API key)
- [x] `Services/ListingImportService.swift` — NEW (protocol + `LocalListingParser` + `ClaudeListingParser` stub)
- [x] `ViewModels/PropertyEditorViewModel.swift` — optional repository dep; `prepareForNew()` async; new location/feature fields; `load(from: PropertyDraft)`
- [x] `ViewModels/ListingImportViewModel.swift` — NEW
- [x] `Views/PropertyEditor/LocationPickerView.swift` — NEW (MapKit pin, MKLocalSearch, CLGeocoder)
- [x] `Views/ListingImport/ListingImportView.swift` — NEW
- [x] `Views/ListingImport/DraftReviewView.swift` — NEW (confidence colour indicators, all fields editable)
- [x] `Views/PropertyEditor/PropertyEditorView.swift` — read-only code display, map picker, new fields
- [x] `Views/PropertyDetail/PropertyDetailView.swift` — new location fields, Google Maps link, excluded items
- [x] `Views/Catalog/CatalogView.swift` — repository param, import button
- [x] `Views/MainTabView.swift` — passes repository to CatalogView
- [x] `SunsetsPropertiesApp.swift` — `migrateIfNeeded()` called before seed
- [x] 91 unit tests — all pass (46 original + 45 new across 6 new suites)
- [x] Build: `** BUILD SUCCEEDED **` (iPhone 17 Simulator, iOS 26.5)
- [x] Tests: `** TEST SUCCEEDED **`

### Milestone 1.1 Refinement — Pet Policy, Sale Financing, FHA ✅ Approved 2026-06-27

Manually validated by Nox on 2026-06-27.

- [x] `Models/PetPolicy.swift` — reduced to 3 cases; `subjectToCaseAnalysis` replaces `allowedWithDeposit` + `caseByCase`
- [x] `Models/SellerFinancingStatus.swift` — NEW (`.unavailable` / `.available` / `.unknown`)
- [x] `Models/FHAEligibility.swift` — NEW (`.eligible` / `.notEligible` / `.unknown`)
- [x] `Services/FinancingTextService.swift` — NEW (deterministic Spanish bank/FHA text)
- [x] `Models/Property.swift` — 4 new financing fields; legacy `petPolicy` migration in decoder
- [x] `Models/PropertyDraft.swift` — 2 new financing draft fields
- [x] `Services/ListingImportService.swift` — FHA detection ("Aplica FHA" / "No aplica FHA"); seller financing from explicit statements only
- [x] `ViewModels/PropertyEditorViewModel.swift` — financing fields
- [x] `Views/PropertyEditor/PropertyEditorView.swift` — financing section (sale only)
- [x] `Views/PropertyDetail/PropertyDetailView.swift` — financing display (sale only)
- [x] `Views/ListingImport/DraftReviewView.swift` — FHA section in draft review
- [x] 14 new unit tests (PetPolicyRefinement, SaleFinancing, FHAParser suites); 117 total, all pass
- [x] Build: `** BUILD SUCCEEDED **`; Tests: `** TEST SUCCEEDED **`
- [x] docs updated: PRODUCT_SPEC.md v0.4, ARCHITECTURE.md v0.4, PROPERTY_SCHEMA.md v0.4, DECISIONS.md (ADR-014), MILESTONES.md, TESTING.md, PROJECT_STATUS.md

**Validated items:**
- Pet-policy picker shows exactly 3 options; removed "Se aceptan mascotas con depósito"
- Existing properties with legacy `caseByCase` / `allowedWithDeposit` load correctly
- Sale-financing fields visible only for sale / rent-or-sale properties
- FHA eligibility defaults to unknown; mentioned only when explicitly confirmed
- Existing local properties remain backward compatible
- No keyboard, AI, backend, Supabase, networking, or media changes

---

### Milestone 2 — Local SunsetsAIKeyboard Extension ✅ (awaiting human approval, 2026-06-27)

**Main app additions:**
- [x] `Models/KeyboardSafeProperty.swift` — NEW (`KeyboardCatalogSnapshot` + `KeyboardSafeProperty` + projection from `Property`). Uses typed enums for main app target.
- [x] `Models/Property.swift` — 4 IUSI fields added: `iusiAmount`, `iusiFrequency`, `iusiVerifiedAt`, `iusiNotes`
- [x] `Models/QuickReplyTemplate.swift` — 3 new `TemplateCategory` cases: `.characteristics`, `.purchaseInfo`, `.followUp`
- [x] `Services/CatalogCacheService.swift` — NEW. Writes `keyboard_catalog.json` to App Group container atomically. Publishes version/timestamp to App Group `UserDefaults`.
- [x] `Services/TemplateEngine.swift` — NEW. Deterministic Spanish reply generator for all 10 categories. Typed-enum version for main app / tests.
- [x] `Services/StorageMaintenanceService.swift` — NEW. `clearAllLocalData()`, `restoreDemoData()`, `removeStaleTempFiles()`, size reporting.
- [x] `ViewModels/PropertyEditorViewModel.swift` — IUSI fields added.
- [x] `ViewModels/CatalogViewModel.swift` — `CatalogCacheService` wired; default-parameter init preserves single-arg usage in tests.
- [x] `ViewModels/ActivePropertyViewModel.swift` — `CatalogCacheService` wired; default-parameter init.
- [x] `Views/Settings/SettingsView.swift` — Rewritten: catalog sync section (manual publish, last updated, version, size, count, error), keyboard setup 7-step guide, data management (clear + restore with confirmation), employee picker.
- [x] `Views/PropertyEditor/PropertyEditorView.swift` — IUSI fields in financing section (sale only).
- [x] `Views/PropertyDetail/PropertyDetailView.swift` — IUSI display in financing section (sale only).
- [x] `Views/MainTabView.swift` — `CatalogCacheService` + `StorageMaintenanceService` threaded through.
- [x] `SunsetsPropertiesApp.swift` — Creates `LocalPropertyRepository`, `CatalogCacheService`, `StorageMaintenanceService`; publishes cache on launch.

**Keyboard extension (`SunsetsAIKeyboard/`):**
- [x] `Models/KeyboardSafeProperty.swift` — NEW (string-typed enum fields; `KBQuickReplyTemplate`; independent from main app module).
- [x] `Services/CatalogReader.swift` — NEW. Reads `keyboard_catalog.json` from App Group; stale detection (24 h); typed error messages.
- [x] `Services/KeyboardPreferences.swift` — NEW. App Group `UserDefaults` for `keyboard_selected_property_id`, `recent_property_ids` (FIFO max 5), `active_property_id` (read-only), `current_employee`.
- [x] `Services/TemplateEngine.swift` — NEW. String-enum version of deterministic Spanish replies. Same logic as main app.
- [x] `Views/KeyboardRootView.swift` — NEW. 4-screen SwiftUI state machine: loading → error / noProperty / replies / selector / preview.
- [x] `Views/PropertySelectorView.swift` — NEW. Favoritas / Recientes / Disponibles / No disponibles sections + search.
- [x] `Views/ResponsePreviewView.swift` — NEW. Preview + Insert + Back.
- [x] `KeyboardViewController.swift` — REWRITTEN. `UIHostingController<KeyboardRootView>` at 320 pt height; `textDocumentProxy.insertText()`; `advanceToNextInputMode()`.

**Tests:**
- [x] `SunsetsPropertiesTests/KeyboardCacheTests.swift` — NEW. 40 tests across 8 suites: projection (8), snapshot encoding (4), availability (5), price (6), location (3), pet policy (3), purchase info (6), characteristics (2), follow-up (3), general dispatcher (5), IUSI fields (3).
- [x] All 157+ tests pass (unit). Build: `** BUILD SUCCEEDED **` for both targets.

### Milestone 2 Refinement ✅ (awaiting human approval, 2026-06-27)

**New models:**
- [x] `Models/PropertyType.swift` — NEW. `PropertyType` enum (9 cases); `PropertyType.infer(from:)` utility.
- [x] `Models/GeneralMessageTemplate.swift` — NEW. `GeneralMessageCategory` (7 cases), `GeneralMessageTemplate`, `KeyboardSafeGeneralMessage` (projection init included).
- [x] `Models/Property.swift` — 4 new fields: `propertyType`, `developmentName`, `neighborhoodName`, `publicDescription`. Migration defaults in decoder. `displayTitle` computed property.
- [x] `Models/PropertyDraft.swift` — 3 new draft fields: `propertyType`, `developmentName`, `publicDescription`.
- [x] `Models/QuickReplyTemplate.swift` — `.generalInfo` case added (12th category).
- [x] `Models/KeyboardSafeProperty.swift` (main app) — `propertyType`, `developmentName`, `displayTitle`, `publicDescription` added to struct and projection init. `generalMessages: [KeyboardSafeGeneralMessage]` added to `KeyboardCatalogSnapshot`.

**New repositories and services:**
- [x] `Repositories/GeneralMessageRepository.swift` — NEW. `GeneralMessageRepository` protocol + `LocalGeneralMessageRepository` (JSON file in Application Support, atomic writes).
- [x] `Services/CatalogCacheService.swift` — `messageRepository` parameter added to `publish()`; only `isEnabled && isKeyboardVisible` messages projected.
- [x] `Services/StorageMaintenanceService.swift` — `LocalGeneralMessageRepository` threaded in; `general_messages.json` removed on `clearAllLocalData()`.
- [x] `Services/TemplateEngine.swift` (main app) — `generalInfo(for:)` method added (combined description + price + location + requirements).
- [x] `Services/ListingImportService.swift` — Improved: input sanitized first (hashtag/footer/signature lines removed); `detectBathrooms` handles `medio baño`, `1/2 baño`, `N baños y medio`, decimal formats; `detectIncludedItems` splits comma-separated inline lists; `detectStructuredPropertyType` returns typed `PropertyType`; `detectDevelopmentName` extracts residencial/torre/etc. prefix; `detectPublicDescription` added.

**New ViewModels and Views:**
- [x] `ViewModels/GeneralMessagesViewModel.swift` — NEW. Load/save/delete/reorder; triggers cache sync after each mutation.
- [x] `Views/GeneralMessages/GeneralMessagesView.swift` — NEW. Sortable list with category badges and keyboard-visibility icon.
- [x] `Views/GeneralMessages/GeneralMessageEditorView.swift` — NEW. Create/edit sheet with all fields.
- [x] `Views/MainTabView.swift` — "Mensajes" tab added (4th tab, text.bubble icon).
- [x] `SunsetsPropertiesApp.swift` — `LocalGeneralMessageRepository` created at launch; passed to `MainTabView` and `CatalogCacheService`.
- [x] `Views/PropertyEditor/PropertyEditorView.swift` — `propertyType` picker, `developmentName`, `neighborhoodName` fields; `displayTitle` preview row; `publicDescription` section.
- [x] `Views/PropertyDetail/PropertyDetailView.swift` — `displayTitle`, `propertyType`, `developmentName`, `neighborhoodName`, `publicDescription` displayed in header section.
- [x] `Views/ListingImport/DraftReviewView.swift` — `propertyType`, `developmentName`, `publicDescription` draft fields shown.

**Keyboard extension updates:**
- [x] `Models/KeyboardSafeProperty.swift` (keyboard) — `propertyType`, `developmentName`, `displayTitle`, `publicDescription` fields; `KBGeneralMessage` model with `categoryLabel`; `KeyboardCatalogSnapshot` updated to include `generalMessages`.
- [x] `Services/TemplateEngine.swift` (keyboard) — `generalInfo(for:)` added as first category; `categories` array updated (11 categories including `generalInfo`).
- [x] `Views/KeyboardRootView.swift` — `generalMessages` and `messagePreview` screen states; globe-bar button for messages when available; property header uses `displayTitle`; "Mensajes" button in no-property state.
- [x] `Views/PropertySelectorView.swift` — Redesigned with tab bar: Todos / Disponibles / No disponibles / Favoritos / Recientes (with per-tab counts); search across `displayTitle`, code, location.
- [x] `Views/GeneralMessagesKeyboardView.swift` — NEW. Browse and select from `KBGeneralMessage` list; review-before-insert indicator.

**Tests:**
- [x] 6 new test suites (32 tests): `BathroomParsingRefinement` (6), `ListingSanitization` (4), `PropertyTypeDetection` (4), `DevelopmentNameExtraction` (3), `IncludedItemsExtraction` (2), `GeneralInfoTemplate` (5), `DisplayTitle` (3), `GeneralMessageTemplate` (3) — plus existing `KeyboardCacheTests` snapshot fix.
- [x] **196/196 tests pass.** Build: `** BUILD SUCCEEDED **`.

### Milestone 2 Correction — 5 Blocking Defects ✅ (awaiting manual validation, 2026-06-27)

Defects found during manual validation of Milestone 2 Refinement; corrected before approval.

**DEFECT 1 — General Information used incomplete description:**
- [x] `Property.swift` — `publicListingText: String?` field added; `CodingKeys` + decoder updated
- [x] `PropertyDraft.swift` — `publicListingText: DraftField<String>` added
- [x] `ListingImportService.swift` — `sanitize()` improved: removes CTA lines (`contáctanos`, `agenda tu visita`, `escríbenos`), phone-only lines, email-only lines, inline hashtag tokens; `publicListingText` DraftField populated with full sanitized text
- [x] `TemplateEngine.swift` (main app) — `generalInfo()` rewritten: uses `publicListingText` as primary body; appends price/requirements only when absent from listing; appends Google Maps + Waze links when location approved
- [x] `TemplateEngine.swift` (keyboard) — same rewrite; string-enum comparisons preserved
- [x] `PropertyEditorViewModel.swift` — `publicListingText` field + load from Property and Draft + pass to `buildProperty()`
- [x] `DraftReviewView.swift` — large editable TextEditor for `publicListingText` with confidence colour
- [x] `PropertyEditorView.swift` — "Texto del anuncio" section; "Descripción corta" section retained

**DEFECT 2 — General messages didn't synchronize to keyboard:**
- [x] `KeyboardRootView.swift` — `reloadTrigger: Int` parameter; `.task(id: reloadTrigger)` replaces `.task`; `loadedVersion` state for version-change detection; `updateScreen(with:)` smart refresh; "Mensajes generales" button always visible (no conditional on count)
- [x] `KeyboardViewController.swift` — `reloadCount` counter; `viewWillAppear` increments and calls `updateRootView()`; `makeRootView()` / `updateRootView()` helpers
- [x] `GeneralMessagesKeyboardView.swift` — grouped by category with section headers; `categoryLabel(_:)` maps raw keys to Spanish; empty state when no messages

**DEFECT 3 — Property type misclassified as Warehouse:**
- [x] `ListingImportService.swift` — `detectStructuredPropertyType(_:lines:)`: 4-priority heading-first system; body text never triggers warehouse; warehouse requires explicit phrase (`bodega en venta`, `nave industrial`) in first 5 lines
- [x] Regression fixture `ArborettoFixtureTests` added (6 tests)

**DEFECT 4 — Generated title format included internal code:**
- [x] `OperationType.swift` — `titleWord` computed property (`"renta"` / `"venta"` / `"renta o venta"`)
- [x] `Property.swift` — `displayTitle` rewritten to `"<type> en <operation> · <development/neighborhood/location>"`; no internal code
- [x] `PropertyEditorView.swift` — `buildDisplayTitle()` updated; shown when type ≠ `.other` or development name set (not requiring internal code)
- [x] `DisplayTitleTests` updated (3 tests)

**DEFECT 5 — Google Maps and Waze location links:**
- [x] `KeyboardSafeProperty.swift` (main app) — `wazeURL: String?` added to struct and projection; coordinate-based when exact sharing approved; search-based from `publicLocationLabel` otherwise
- [x] `KeyboardSafeProperty.swift` (keyboard) — `wazeURL: String?` added
- [x] `TemplateEngine.swift` (main app + keyboard) — `buildMapsLinks()` helper; `location()` rewritten with `📍 Ubicación:` + Google Maps + Waze links
- [x] `PropertyDetailView.swift` — shows `publicListingText` in header; falls back to `publicDescription`

**Schema change (backward-compatible):**
- [x] `KeyboardCatalogSnapshot.currentSchemaVersion` bumped 1 → 2 (new optional fields decode as nil from old snapshots)

**Tests:**
- [x] `schemaVersionIsCurrentVersion` updated to `== 2`
- [x] `GeneralInfoTemplateTests` expanded (9 tests total — publicListingText, suppression, maps links)
- [x] `ArborettoFixtureTests` — 6 regression tests (type, dev name, operation, location, CTA removal, displayTitle)
- [x] `WazeURLTests` — 2 tests (coordinate-based, search-based)
- [x] `ListingSanitizationExtendedTests` — 2 tests (CTA removal, inline hashtag stripping)
- [x] Location detection: Strategy 2.5 added (standalone comma-separated place-name lines in lines 2–5)
- [x] **209/209 tests pass.** Build: `** BUILD SUCCEEDED **`.

### Milestone 2 Correction (Round 3) — 3 Synchronization Defects ✅ (awaiting manual validation, 2026-06-27)

**DEFECT 1 — SUN-020 absent from keyboard (isValidForCache too strict):**
- [x] `Models/Property.swift` — `isValidForCache` now requires only `!id.isEmpty && !internalCode.isEmpty`. Price, currency, locationSummary, and displayTitle are no longer exclusion criteria. Keyboard uses safe fallbacks for incomplete data. `isValidDisplayTitle` retained as diagnostic-only flag.
- [x] `Models/Property.swift` — `displayTitle` fallback changed from `"Propiedad sin título · SUN-###"` to `"Propiedad pendiente de revisión"` (code shown separately in keyboard subtitle row, not embedded in title string).
- [x] `Services/CatalogCacheService.swift` — Added `init(snapshotURL: URL? = nil)` for testable path bypassing App Group. `atomicWrite` fixed: uses `moveItem` when target doesn't yet exist (was silently discarding the write).

**DEFECT 2 — General messages wiped on every property save (messageRepository not stored):**
- [x] `Services/CatalogCacheService.swift` — `publish(repository:messageRepository:)` now stores `messageRepository` in `_messageRepository` when non-nil. Subsequent calls that omit `messageRepository` (CatalogViewModel, ActivePropertyViewModel, SettingsView) use the stored reference. General messages are never wiped by property operations.

**DEFECT 3 — Keyboard property row shows no internal code:**
- [x] `SunsetsAIKeyboard/Views/PropertySelectorView.swift` — `propertyRow` subtitle changed from `displayLocation` to `"\(internalCode) · \(displayLocation)"` (e.g. `SUN-020 · Zona 10`).
- [x] `SunsetsAIKeyboard/Views/KeyboardRootView.swift` — `propertyHeader` now shows `displayTitle` (medium weight) + `"\(internalCode) · \(displayLocation)"` (caption2, secondary) for the active property.

**Diagnostics (SettingsView):**
- [x] `Views/Settings/SettingsView.swift` — Catalog sync section now shows: total properties, published count, excluded count (when > 0), published internal codes, total messages, published messages, App Group availability.
- [x] `Services/CatalogCacheService.swift` — New tracking properties: `totalPropertyCount`, `totalMessageCount`, `publishedMessageCount`, `publishedInternalCodes`, `appGroupAvailable`.

**Tests:**
- [x] `DisplayTitleRegressionTests` updated: fallback text is now `"Propiedad pendiente de revisión"`; `isValidForCache` tests inverted (garbage location/price-zero properties are NOW included).
- [x] `SyncLifecycle` suite (4 tests): SUN-020 appears; available status correct; zero-price included; garbage location included.
- [x] `MessageSyncLifecycle` suite (6 tests): Bienvenida published; edit updates; disable removes; re-enable restores; properties+messages coexist; subsequent property-only publish keeps messages.
- [x] **239/239 tests pass.** Build: `** BUILD SUCCEEDED **`.

### Milestone 2 Correction (Round 2) — 4 Additional Blocking Defects ✅ (awaiting manual validation, 2026-06-27)

Defects found during continued manual validation of Milestone 2 (post-correction). Fixed before re-approval.

**DEFECT 1 — Correct property titles:**
- [x] `Models/Property.swift` — `isCleanLocationPart(_:)` static helper: rejects price lines, field labels, operation phrases, URLs, contact keywords; `displayTitle` walks priority chain and skips garbage candidates; falls back to `"Propiedad sin título · <code>"` when `propertyType = .other` and no clean location exists; `isValidDisplayTitle: Bool` computed property; `isValidForCache` updated to require `isValidDisplayTitle`.
- [x] Regression tests added (`IsCleanLocationPart` suite — 5 tests; `DisplayTitleRegression` suite — 8 tests).

**DEFECT 2 — Save button fails after editing location:**
- [x] `Views/PropertyEditor/PropertyEditorView.swift` — `@State private var showingSaveErrorAlert`. `save()` sets the flag on validation failure instead of silently returning. `LocationPickerView.onConfirm` now falls back to coordinate string `"%.5f, %.5f"` when reverse-geocoding returns nil — prevents empty `locationSummary` blocking save invisibly. `.alert("No se puede guardar")` shows full validation error list.
- [x] `Views/ListingImport/DraftReviewView.swift` — same alert flag and `confirmAndSave()` wired to show alert on failure.

**DEFECT 3 — General messages not reaching keyboard:**
- [x] `Models/GeneralMessageTemplate.swift` — `new()` default changed `isKeyboardVisible: false` → `isKeyboardVisible: true`. New messages now reach the keyboard immediately without requiring a manual toggle.
- [x] `GeneralMessageTemplateTests.testNewTemplateDefaults()` updated to expect `true`.
- [x] `GeneralMessageDefaults` suite added — 5 tests covering default, publish-filter logic.

**DEFECT 4 — Invalid items in property catalog:**
- [x] `Services/CatalogCacheService.swift` — `excludedPropertyCount: Int` added; `publish()` computes `valid = all.filter { $0.isValidForCache }`, tracks `excluded = all.count - valid.count`, sets `lastError` warning when `excluded > 0`, resets `excludedPropertyCount` in `clearCache()`.
- [x] `Views/Settings/SettingsView.swift` — "Propiedades excluidas" row shown in orange when `excludedPropertyCount > 0`.

**Tests:**
- [x] `DisplayTitleRegression` suite — 8 tests (price line excluded, field label excluded, operation phrase excluded, fallback code, valid passthrough, dev name priority, `isValidForCache` false/true).
- [x] `GeneralMessageDefaults` suite — 5 tests (default visible, default enabled, disabled excluded, invisible excluded, both included).
- [x] `IsCleanLocationPart` suite — 5 tests (place names accepted; price/label/operation/short strings rejected).
- [x] **227/227 tests pass.** Build: `** BUILD SUCCEEDED **`.

## Pending Work

---

## Known Blockers

1. **Apple Developer portal** — The following must be registered before the first Xcode build on a real device:
   - App Group: `group.com.sunsetsrealestate.sunsetsai`
   - Bundle ID (main app): `com.sunsetsrealestate.sunsetsproperties`
   - Bundle ID (keyboard): `com.sunsetsrealestate.sunsetsproperties.keyboard`

2. **Test target deployment targets** — `SunsetsPropertiesTests` and `SunsetsPropertiesUITests` targets have `IPHONEOS_DEPLOYMENT_TARGET = 26.5` (inheriting from project level). Correction recommended: set to iOS 17.0 in Xcode to match the main target. Non-blocking for Simulator work on macOS 26.

---

## Schema Changes (Milestone 1.1 — Pending Approval)

### New `Property` fields

| Field | Type | Default | Migration |
|-------|------|---------|-----------|
| `publicLocationLabel` | `String?` | `nil` | Auto (optional) |
| `formattedAddress` | `String?` | `nil` | Auto (optional) |
| `googleMapsURL` | `String?` | `nil` | Auto (optional) |
| `locationSource` | `LocationSource` | `.manual` | Requires custom decoder |
| `isExactLocationShareable` | `Bool` | `false` | Requires custom decoder |
| `includedItems` | `[String]` | `[]` | Requires custom decoder |
| `excludedItems` | `[String]` | `[]` | Requires custom decoder |

`latitude` and `longitude` existed in the schema but now have a defined UI for setting them.

### New `KeyboardProperty` fields

| Field | Condition |
|-------|-----------|
| `publicLocationLabel: String?` | Always projected (when set) |
| `googleMapsURL: String?` | Always projected (when set) |
| `isExactLocationShareable: Bool` | Always projected |
| `latitude: Double?` | Only when `isExactLocationShareable == true` |
| `longitude: Double?` | Only when `isExactLocationShareable == true` |
| `includedItems: [String]` | Always projected |
| `excludedItems: [String]` | Always projected |

### New top-level types

- `LocationSource` enum (`.manual`, `.mapPicker`, `.addressSearch`, `.googleMapsURL`)
- `PropertyDraft` struct
- `DraftField<T>` generic struct
- `DraftConfidence` enum (`.high`, `.medium`, `.low`, `.missing`)

---

## Resolved Decisions (as of 2026-06-27)

| Decision | Approved value |
|----------|---------------|
| iOS deployment target | iOS 17 minimum |
| Primary device | iPhone only (iPad out of scope for MVP) |
| Main app bundle ID | `com.sunsetsrealestate.sunsetsproperties` |
| Keyboard extension bundle ID | `com.sunsetsrealestate.sunsetsproperties.keyboard` |
| App Group identifier | `group.com.sunsetsrealestate.sunsetsai` |
| Primary language | Spanish for Guatemala (`es-GT`) |
| Organization model | Single organization (Sunsets Real Estate) |
| `assignedAgentId` in keyboard cache | Excluded |
| Privacy policy requirement | Deferred to Milestone 6 (not a Milestone 1 blocker) |
| Local persistence (Milestone 1) | JSON file in Application Support + UserDefaults |
| Test framework for unit tests | Swift Testing (`import Testing`) |
| Test framework for UI tests | XCTest |
| Map provider (Milestone 1.1) | MapKit only — no Google Maps SDK, no Google API key |
| Google Maps URL format | `google.com/maps?q={lat},{lon}` (generated); `maps.app.goo.gl/…` (accepted from paste) |
| Property media | Deferred — no media fields in any milestone through Milestone 1.1 (ADR-013) |
| Listing import (Milestone 1.1) | Local parser only; AI parser stub only (ADR-012) |
| SUN-### code reuse | Deleted/inactive codes are never reused (ADR-011) |
| Exact coordinates in keyboard cache | Opt-in only; default is private (ADR-009) |

---

## Open Decisions (still require human approval before indicated milestone)

| Decision | Required before | Notes |
|----------|----------------|-------|
| Backend base URL / custom domain | Milestone 4 | Vercel project not yet created |
| Intent classifier vocabulary | Milestone 3 | Spanish/English phrase list needs human review |
| AI system prompt | Milestone 4 | Anthropic prompt must be approved before production |
| Data retention policy | Milestone 5 | How long backend AI logs are kept |
| Remote crash logging provider | Milestone 5 | Provider and data exclusions to be decided |
| Privacy policy | Milestone 6 | Must be live before external TestFlight or public distribution |
| "Use my current location" in map picker | Post–Milestone 1.1 | Requires Location Services permission review |
| Listing import PII check for `ClaudeListingParser` | Milestone 4 | Must confirm no customer PII in listing text before sending to backend |

---

## Confirmed Assumptions

1. Primary language is Spanish for Guatemala (`es-GT`) — neutral, professional register.
2. Target messaging apps: Messenger, WhatsApp, Facebook Marketplace.
3. iPhone only. iPad out of scope for the MVP.
4. Supabase project will be created fresh (no migration from an existing database).
5. One organization: Sunsets Real Estate. Multi-tenant is out of scope.
6. Anthropic Messages API is used for AI generation.
7. Agents may be bilingual; customer messages are expected primarily in Spanish (Guatemala).
8. Google Maps is the dominant navigation app used by agents and customers in Guatemala (informs URL format choice).

---

## Next Exact Task

> **Await explicit human approval of Milestone 2 (including all correction rounds) before beginning Milestone 3.**

Milestone 2 base implementation, Milestone 2 Refinement, Correction round 1 (5 defects), Correction round 2 (4 defects), and Correction round 3 (3 synchronization defects) are fully implemented and tested (239/239 tests passing). Stop here per the Milestone Discipline rule in CLAUDE.md.
