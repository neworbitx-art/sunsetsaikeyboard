# Milestones — Sunsets AI Keyboard

**Version:** 0.4 (Milestone 2 — Not started)
**Last updated:** 2026-06-27

Each milestone has a defined scope, explicit exclusions, deliverables, acceptance criteria, testing requirements, known risks, and required human actions. No milestone may begin until the previous one has been explicitly approved.

---

## Milestone 0 — Documentation and Architecture

**Status:** Approved and complete (2026-06-27)

Established the full project documentation, data model, architecture, and implementation plan before any code was written.

---

## Milestone 1 — Local Sunsets Properties Application

**Status:** Approved and complete (2026-06-27)

Built the main SwiftUI application with a functional local property catalog using mocked data and local JSON persistence. No networking, no backend, no Supabase.

---

## Milestone 1.1 — Property Enrichment and Import

**Status:** Approved and complete (2026-06-27). Manually validated by Nox on 2026-06-27.

### Objective
Enrich the property model with structured location data, automatic internal codes, and a text-import workflow that creates a reviewable draft before any data is saved. All work remains offline and local.

### Scope

**1. Structured location**
- `LocationPicker` view using MapKit (`MKMapView` or SwiftUI `Map`) with a draggable pin.
- `AddressSearchView` using `MKLocalSearch`.
- `GoogleMapsURLImporter` — parses a pasted Google Maps URL to extract coordinates.
- New `Property` fields: `publicLocationLabel`, `formattedAddress`, `googleMapsURL`, `locationSource`, `isExactLocationShareable`.
- `latitude` and `longitude` already existed in the schema; they now have a defined UI path for setting.
- `CatalogCacheService` updated to project `latitude`, `longitude`, `googleMapsURL`, `publicLocationLabel`, and `isExactLocationShareable` into `KeyboardProperty` when applicable.
- Template token `{{googleMapsURL}}` added to the default location template.

**2. Automatic internal codes**
- `InternalCodeGenerator` service that scans existing codes and returns the next `SUN-###`.
- Pre-populated code field in `PropertyEditorView` when creating a new property.
- Uniqueness validation in `PropertyEditorViewModel`.
- Code cannot be reused after deletion or inactivation.

**3. Listing text import**
- `PropertyDraft` and `DraftField<T>` models.
- `DraftConfidence` enum (high / medium / low / missing).
- `ListingImportService` protocol.
- `LocalListingParser` implementation using deterministic string matching and regex.
- `ClaudeListingParser` protocol stub (no implementation; reserved for Milestone 4).
- `ListingImportView` — paste area → parse → review draft → confirm or discard.
- Draft review UI highlights fields with `low` or `missing` confidence.
- `sourceDescription` preserved in the draft for comparison.
- Contact info extracted for display only; never saved to `Property`.
- Nothing is saved until the user explicitly taps "Confirmar y crear propiedad".

**4. Migration**
- Existing local `Property` records gain new fields with safe defaults on decode.
- `LocalPropertyRepository` handles missing keys via `init(from:)` decoder defaults.

**5. Model additions**
- `includedItems: [String]` and `excludedItems: [String]` on `Property` and `KeyboardProperty`.

### Explicit Exclusions
- No keyboard extension UI changes.
- No App Group capability (added in Milestone 2).
- No Supabase.
- No network calls.
- No Anthropic / Claude API calls.
- No Google Maps SDK.
- No Google API key.
- No authentication.
- No property media (photographs, images, galleries) — see ADR-013.
- No `PhotosPicker`.
- No Photos Library permission.
- No `ClaudeListingParser` implementation (stub only).

### Deliverables
- MapKit-based location picker and address search in the property editor.
- Google Maps URL import field in the property editor.
- Auto-generated `SUN-###` code proposed on new property creation.
- Duplicate-code validation error when saving.
- "Importar descripción" entry point in the property catalog or editor.
- `PropertyDraft` review screen with confidence indicators.
- Existing Milestone 1 test suite still passing.

### Acceptance Criteria

**Internal codes:**
- [ ] A new property is pre-filled with the next `SUN-###` code based on the highest existing number.
- [ ] Saving a property with a duplicate code is rejected with a clear error.
- [ ] Deleting a property does not make its code available for reuse.
- [ ] An administrator can override the proposed code before saving.
- [ ] After a manual override, the next auto-generated code continues from the correct maximum.

**Location:**
- [ ] Opening the location picker shows a MapKit map; the user can drag a pin to a location and confirm.
- [ ] The address search field returns results via `MKLocalSearch`; selecting a result sets `latitude`, `longitude`, and `formattedAddress`.
- [ ] Pasting a Google Maps URL (`maps.app.goo.gl/…` or `google.com/maps?q=…`) extracts and stores the coordinates.
- [ ] `isExactLocationShareable` defaults to `false` for all properties; the user can enable it explicitly.
- [ ] When `isExactLocationShareable == true`, `latitude` and `longitude` appear in the keyboard cache.
- [ ] When `isExactLocationShareable == false`, `latitude` and `longitude` are absent from the keyboard cache regardless of whether they are set.
- [ ] `googleMapsURL` is included in the keyboard cache when set; `fullAddress` and `formattedAddress` are never included.
- [ ] `publicLocationLabel` appears in the keyboard cache when set.

**Listing import:**
- [ ] The user can paste a listing description and receive a `PropertyDraft` with detected fields.
- [ ] Fields detected with `low` confidence are visually highlighted for review.
- [ ] Fields with `missing` confidence are shown as empty with a prompt to fill them in.
- [ ] No data is saved until the user taps the confirmation button.
- [ ] The original pasted text (`sourceDescription`) is visible alongside the draft for comparison.
- [ ] Tapping "Descartar" discards the draft without saving anything.
- [ ] Contact information extracted from the listing is shown for reference but is not saved to `Property`.
- [ ] After confirmation, the new property appears in the catalog with all confirmed fields.

**Migration:**
- [ ] Existing properties created in Milestone 1 load without error after the Milestone 1.1 update.
- [ ] Existing properties default to `locationSource = .manual`, `isExactLocationShareable = false`, `includedItems = []`, `excludedItems = []`.

**Exclusions verified:**
- [ ] No `PhotosPicker` is present anywhere in the codebase.
- [ ] No Photos Library permission appears in `Info.plist`.
- [ ] No AI or backend call is made during listing import.
- [ ] No keyboard extension UI has changed.
- [ ] No App Group capability has been added.

### Testing Requirements
- Unit tests for `InternalCodeGenerator` (next code, gap skipping, duplicate rejection, no reuse after delete).
- Unit tests for `GoogleMapsURLImporter` (valid URLs, invalid URLs, short links).
- Unit tests for `LocalListingParser` (price detection, bedroom detection, location detection, operation type, confidence levels).
- Unit tests for `PropertyDraft` encoding and decoding.
- Unit tests for `CatalogCacheService` location projection (with and without `isExactLocationShareable`).
- Unit tests for migration decoder defaults.
- Manual test: pin a location on the map, confirm coordinates appear in the property.
- Manual test: search an address, select a result, confirm fields are populated.
- Manual test: paste a Google Maps URL, confirm coordinates are extracted.
- Manual test: paste a sample listing, review draft, confirm, verify property in catalog.
- Manual test: verify existing Milestone 1 properties load correctly after update.

### Known Risks
- `MKLocalSearch` results vary by device language and region settings; tested with `es_GT` locale.
- Short Google Maps URLs (`maps.app.goo.gl/…`) redirect to full URLs and may require HTTP resolution to extract coordinates; prefer parsing `google.com/maps?q=…` form directly. Document behavior for both formats.
- `locationSource` is non-optional; existing JSON without this key will fail to decode unless a custom decoder default is implemented. **This is a migration risk — must be addressed before shipping.**
- `LocalListingParser` accuracy depends on the vocabulary of Guatemalan real-estate listings; accuracy may be low for some fields.

### Required Human Actions
1. Review and approve Milestone 1.1 documentation before implementation begins.
2. Test listing import with real (anonymized) property descriptions.
3. Confirm expected Google Maps URL format for Guatemala listings.
4. Approve Milestone 1.1 completion before starting Milestone 2.

---

## Milestone 2 — Local SunsetsAIKeyboard Extension

**Status:** Not started

### Objective
Build the custom keyboard extension that reads the App Group cache, allows property search and selection, shows quick actions, and inserts text into the host application. No AI, no backend.

### Scope
- `UIInputViewController` subclass as the keyboard root.
- Active property bar (always visible): title, operation type, price, status.
- Property search field and list (reads from App Group cache).
- Recently used properties list (up to 5).
- Favorite properties section.
- Property selection updates active property ID in App Group.
- Quick action buttons for the active property (renders default system templates).
- Property-specific `QuickReplyTemplate` buttons.
- Response preview area.
- Insert button (`textDocumentProxy.insertText()`).
- Stale cache warning (>24 hours).
- Inactive/reserved/rented/sold property warning badge.
- `CatalogReader` service for reading the App Group catalog.
- `TemplateEngine` for rendering templates from `KeyboardProperty`.

### Explicit Exclusions
- No AI generation.
- No backend calls.
- No clipboard import.
- No intent classification.
- No authentication.

### Deliverables
- Keyboard extension installs and activates on a physical iPhone.
- Active property bar shows the correct property after selection.
- Searching the catalog inside the keyboard returns correct results.
- Tapping a quick action inserts the correct text into the host app's input field.
- Selecting a property in the keyboard updates the active property in the App Group.

### Acceptance Criteria
- [ ] The keyboard opens inside Messenger, WhatsApp, Facebook Marketplace, and Notes without crashing.
- [ ] The active property bar displays the current property's title, price, and status on every open.
- [ ] The user can search for a property by title or location summary.
- [ ] Selecting a property updates the active bar immediately.
- [ ] Tapping a quick action produces the correct formatted string in the host app's text field.
- [ ] No text is inserted before the user taps Insert.
- [ ] Stale cache (>24 hours) triggers a visible warning.
- [ ] Properties with status other than `available` display a warning badge.
- [ ] `inactive` and `sold` properties do not generate availability-confirming template responses.
- [ ] The keyboard stays within the iOS memory limit (~50 MB).

### Testing Requirements
- Unit tests for `CatalogReader` deserialization.
- Unit tests for `TemplateEngine` (all system templates, all placeholder tokens including `{{googleMapsURL}}` and `{{publicLocation}}`).
- Unit tests for property search (title match, location match, empty query, no results).
- Unit tests for `recent_property_ids` FIFO management.
- Unit tests for stale cache detection.
- Manual testing in Notes (Simulator acceptable for initial testing).
- Manual testing in Messenger on physical iPhone.
- Manual testing in WhatsApp on physical iPhone.
- Manual testing in Facebook Marketplace on physical iPhone.

### Known Risks
- iOS keyboard extension memory limit may be tight if the catalog is large.
- Some messaging apps may prevent custom keyboards in certain views.

### Required Human Actions
1. Install the app on physical iPhones.
2. Enable the keyboard in iOS Settings.
3. Grant Full Access.
4. Verify the keyboard in all three target messaging apps.
5. Approve Milestone 2 completion before starting Milestone 3.

---

## Milestone 3 — Clipboard Import and Local Intent Handling

**Status:** Not started

### Objective
Add explicit clipboard import and a local intent classifier that routes customer messages to deterministic template responses.

*(Scope, exclusions, and acceptance criteria unchanged from v0.2 — see prior version for detail.)*

### Required Human Actions
1. Review and approve the intent vocabulary list before Milestone 3 begins.
2. Test with real customer message samples (anonymized) to validate classifier accuracy.

---

## Milestone 4 — Secure AI Backend

**Status:** Not started

### Objective
Deploy a TypeScript backend on Vercel that authenticates agents, proxies AI generation via the Anthropic Messages API, and returns structured responses to the keyboard. No API key in the iOS app.

**Includes:** `ClaudeListingParser` implementation via `POST /import/listing` endpoint.

*(Full scope unchanged from v0.2 — see prior version for detail.)*

### Required Human Actions
1. Provision a Vercel project and set environment variables.
2. Confirm the backend base URL.
3. Approve the AI system prompt before deploying to production.

---

## Milestone 5 — Supabase and Multi-User Synchronization

**Status:** Not started

### Objective
Replace the mocked property repository with a real Supabase backend. Add agent authentication, role-based access, and catalog synchronization.

**Note:** Internal code generation (`SUN-###`) must move to a Supabase sequence or advisory lock in this milestone to prevent multi-user collisions.

*(Full scope unchanged from v0.2 — see prior version for detail.)*

---

## Milestone 6 — TestFlight Deployment

**Status:** Not started

### Objective
Deploy the application to TestFlight for internal testing on Cristian's and Yessy's iPhones.

*(Full scope unchanged from v0.2 — see prior version for detail.)*
