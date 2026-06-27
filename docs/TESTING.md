# Testing Strategy — Sunsets AI

**Version:** 0.4 (Milestone 2 — Not started)
**Last updated:** 2026-06-27
**Status:** Milestone 1.1 approved and complete

---

## 1. Guiding Principles

- Tests must be runnable without a physical device for unit and integration levels.
- Physical-device tests are required before any milestone is marked complete.
- Keyboard extension tests must be executed on a real iPhone — iOS Simulator does not support keyboard extensions fully.
- Each test layer focuses on a single concern; tests should not cross layer boundaries unless testing integration.

---

## 2. Unit Tests

### 2.1 Property Model Tests (`SunsetsPropertiesTests`)

- Verify that a `Property` with all required fields serializes and deserializes correctly.
- Verify that a `Property` missing required fields is correctly flagged as invalid by the validation function.
- Verify that `PropertyStatus` raw values match expected strings (`"available"`, `"reserved"`, etc.).
- Verify that `OperationType` raw values match expected strings.
- Verify that `PetPolicy` raw values match expected strings.
- Verify that `Decimal` price fields round-trip through JSON without precision loss.
- Verify that `Date` fields are encoded as ISO 8601 and decoded correctly.

### 2.2 Template Engine Tests (`SunsetsAIKeyboardTests`)

- For each default system template, verify that all `{{token}}` placeholders are resolved from a known `KeyboardProperty`.
- Verify that optional tokens (`{{maintenanceFee}}`) are omitted gracefully when the field is nil.
- Verify that `petPolicy` produces the correct human-readable string for each enum case.
- Verify that a property with status `rented` or `sold` does not produce an availability-confirming template body.
- Verify that custom `QuickReplyTemplate` placeholders resolve correctly.
- Verify that templates with unknown tokens fall back gracefully (do not crash).
- Verify that `{{googleMapsURL}}` resolves to the URL string when `googleMapsURL` is set.
- Verify that `{{googleMapsURL}}` is omitted or replaced with a fallback when `googleMapsURL` is nil.
- Verify that `{{publicLocation}}` resolves to `publicLocationLabel` when set.
- Verify that `{{publicLocation}}` falls back to `locationSummary` when `publicLocationLabel` is nil.

### 2.3 Intent Classifier Tests (`SunsetsAIKeyboardTests`)

- Verify that messages containing price keywords classify as `price_inquiry`.
- Verify that messages about availability classify as `availability_inquiry`.
- Verify that messages about visit scheduling classify as `visit_inquiry`.
- Verify that messages about pets classify as `pet_inquiry`.
- Verify that negotiation phrases classify as `negotiation` (requires human handling).
- Verify that unrecognized messages classify as `unknown` (requires human handling or AI).
- Tests must cover Spanish and English variants of common phrases.

### 2.4 Property Search Tests (`SunsetsAIKeyboardTests`)

- Verify that searching by title substring returns matching properties.
- Verify that searching by location summary returns matching properties.
- Verify that searching by internal code returns the exact property.
- Verify that an empty query returns all properties sorted by `isFavorite` then `title`.
- Verify that a query with no matches returns an empty array.
- Verify that search is case-insensitive and accent-insensitive.

---

## 3. Milestone 1.1 Unit Tests

### 3.1 InternalCodeGenerator Tests (`SunsetsPropertiesTests`)

- Verify that `nextCode(existingCodes: [])` returns `"SUN-001"` when no properties exist.
- Verify that `nextCode(existingCodes: ["SUN-001", "SUN-002"])` returns `"SUN-003"`.
- Verify that `nextCode` skips gaps — `["SUN-001", "SUN-003"]` → `"SUN-004"` (always takes max+1, not fills gaps).
- Verify that `nextCode` handles non-contiguous codes correctly.
- Verify that `nextCode` pads to at least 3 digits: `"SUN-009"` → `"SUN-010"`, `"SUN-099"` → `"SUN-100"`.
- Verify that `isUnique("SUN-005", existingCodes: ["SUN-001"])` returns `true`.
- Verify that `isUnique("SUN-001", existingCodes: ["SUN-001"])` returns `false`.
- Verify that after deleting a property with code `"SUN-002"`, `nextCode(existingCodes: ["SUN-001", "SUN-003"])` still returns `"SUN-004"` (not `"SUN-002"`).

### 3.2 GoogleMapsURLImporter Tests (`SunsetsPropertiesTests`)

- Verify that `parse("https://www.google.com/maps?q=14.6349,-90.5069")` returns `(14.6349, -90.5069)`.
- Verify that `parse("https://www.google.com/maps/place/@14.6349,-90.5069,17z")` extracts coordinates.
- Verify that `parse("https://maps.app.goo.gl/abc123")` is recognized as a short link (returns a result with a non-nil `requiresResolution` flag or resolves synchronously in tests via a mock).
- Verify that `parse("https://example.com/not-maps")` returns `nil`.
- Verify that `parse("")` returns `nil`.
- Verify that `parse("not a url")` returns `nil`.
- Verify that coordinates with negative latitude/longitude (Southern/Western hemisphere) parse correctly.

### 3.3 LocalListingParser Tests (`SunsetsPropertiesTests`)

- Verify that a listing with "Q15,000/mes" or "Q 15,000" produces `price.value = 15000` and `currency.value = "GTQ"` with `high` or `medium` confidence.
- Verify that a listing with "USD 2,500" produces `price.value = 2500` and `currency.value = "USD"`.
- Verify that "3 recámaras" or "3 habitaciones" produces `bedrooms.value = 3`.
- Verify that "3.5 baños" produces `bathrooms.value = 3.5`.
- Verify that "2 estacionamientos" produces `parkingSpaces.value = 2`.
- Verify that "en venta" produces `operationType.value = .sale`.
- Verify that "en renta" or "en alquiler" produces `operationType.value = .rent`.
- Verify that a listing with no price detected produces `price.confidence = .missing`.
- Verify that a listing with ambiguous price produces `price.confidence = .low` or `.medium`.
- Verify that `contactInfo` is extracted when a phone number is present but produces a `DraftField` with non-nil value.
- Verify that `sourceDescription` in the resulting `PropertyDraft` matches the input string verbatim.

### 3.4 PropertyDraft Tests (`SunsetsPropertiesTests`)

- Verify that a `PropertyDraft` round-trips through JSON encoding and decoding without data loss.
- Verify that `DraftField<Decimal>` encodes `nil` value and `missing` confidence correctly.
- Verify that `DraftField<[String]>` encodes and decodes an array value correctly.
- Verify that `DraftConfidence` raw values match expected strings.

### 3.5 CatalogCacheService Location Projection Tests (`SunsetsPropertiesTests`)

- Verify that when `isExactLocationShareable == true`, the resulting `KeyboardProperty` contains `latitude` and `longitude`.
- Verify that when `isExactLocationShareable == false`, the resulting `KeyboardProperty` has `latitude == nil` and `longitude == nil`, even if the source `Property` has non-nil values.
- Verify that `googleMapsURL` is included in `KeyboardProperty` when set.
- Verify that `googleMapsURL` is `nil` in `KeyboardProperty` when the source `Property` has `nil`.
- Verify that `fullAddress` is never present in the projected `KeyboardProperty`.
- Verify that `formattedAddress` is never present in the projected `KeyboardProperty`.
- Verify that `publicLocationLabel` is included in `KeyboardProperty` when set.
- Verify that `locationSource` is not present in the projected `KeyboardProperty`.

### 3.6 Migration Decoder Tests (`SunsetsPropertiesTests`)

- Verify that a `Property` JSON object without `locationSource` decodes successfully with a default of `.manual` (or that the field is optional and resolves to `.manual` in the service layer).
- Verify that a `Property` JSON object without `isExactLocationShareable` decodes successfully with a default of `false`.
- Verify that a `Property` JSON object without `includedItems` decodes with `includedItems == []`.
- Verify that a `Property` JSON object without `excludedItems` decodes with `excludedItems == []`.
- Verify that a `Property` JSON object without `publicLocationLabel` decodes with `publicLocationLabel == nil`.
- Verify that a `Property` JSON object without `googleMapsURL` decodes with `googleMapsURL == nil`.

---

## 4. App Group Serialization Tests

These tests verify the contract between the main application and the keyboard extension.

- Verify that `CatalogCacheService` writes a valid JSON file to the App Group container.
- Verify that `CatalogReader` reads and deserializes the same file into an identical `[KeyboardProperty]` array.
- Verify that a `Property` containing all optional nil fields serializes and deserializes without error.
- Verify that a `Property` with the maximum expected field lengths (e.g., 500-char `visitInstructions`) round-trips correctly.
- Verify that `catalog_updated_at` is written and readable as a Unix timestamp.
- Verify that `active_property_id` written by the keyboard is readable by the main app and vice versa.
- Verify that `recent_property_ids` maintains FIFO order capped at 5 entries.
- Verify that writing an empty catalog (zero properties) does not crash the reader.
- Verify that a `KeyboardProperty` with `googleMapsURL` set round-trips through App Group JSON correctly.
- Verify that a `KeyboardProperty` with `latitude` and `longitude` (when `isExactLocationShareable == true`) round-trips correctly.

---

## 5. Keyboard Insertion Tests

- Verify that `textDocumentProxy.insertText()` is called exactly once per Insert tap.
- Verify that the inserted string matches the previewed response exactly.
- Verify that no insertion occurs when the agent has not tapped Insert.
- Verify that `insertText` is not called when the keyboard opens.
- These tests use a mock `UITextDocumentProxy`.

---

## 6. Offline Tests

- Verify that the keyboard loads the cached catalog when no network is available.
- Verify that deterministic template responses are generated when offline.
- Verify that the AI generate button is disabled when offline.
- Verify that the offline indicator is visible when the network is unavailable.
- Verify that re-establishing network connectivity re-enables the AI generate button.
- Verify that listing import via `LocalListingParser` works offline (no network call is made).

---

## 7. Stale Cache Tests

- Verify that a cache written more than 24 hours ago triggers the stale-data warning badge.
- Verify that a cache written within 24 hours does not trigger the warning.
- Verify that template responses are still generated from stale data (staleness is a warning, not a blocker).
- Verify that the warning disappears after the main application refreshes the cache.

---

## 8. Active Property Switching Tests

- Verify that selecting a different property updates the active property bar immediately.
- Verify that quick actions reflect the newly selected property's data after switching.
- Verify that AI generation uses the newly selected property's context after switching.
- Verify that switching properties does not clear the keyboard's search results.
- Verify that a property switch made in the keyboard is reflected when the main application next reads `active_property_id`.
- Verify that selecting an `inactive` property shows a warning and blocks availability-confirmation templates.

---

## 9. Manual Testing: Milestone 1.1 Acceptance ✅ Validated 2026-06-27

Manually validated by Nox on 2026-06-27 on iPhone 17 Simulator (iOS 26.5). All items confirmed.

**Internal codes:**
- [x] New property pre-filled with the next `SUN-###` code; code is read-only.
- [x] Opening and cancelling the form does not consume a code; same code shown on re-open.
- [x] Saving consumes exactly one code; next open shows the incremented code.
- [x] Deleting a property does not make its code available for reuse.
- [x] Editing an existing property preserves its code unchanged.

**Location picker:**
- [x] MapKit map picker opens; draggable pin sets `latitude` and `longitude`.
- [x] `MKLocalSearch` address search returns results; selecting a result populates coordinates.
- [x] Pasting a Google Maps URL auto-populates coordinates in the editor.
- [x] `isExactLocationShareable` toggle works as a privacy gate.
- [x] Structured location fields saved and displayed correctly.

**Listing import:**
- [x] CENTO listing imports correctly: rent, Q 4,200, mantenimiento incluido, Q 4,200 deposit, Santa Catarina Pinula, Level 2, 3 bedrooms, 1 bath, 2 parking, estufa+lavasecadora included, refrigeradora excluded.
- [x] Tanta Premier listing imports correctly: sale, Q 1,450,000, Zona 10 Santa Catarina Pinula, 140 m², 3 bedrooms, 3 parking, no invented bathroom count, included items, amenities.
- [x] Missing numeric fields remain empty in review (no silent default zero).
- [x] Draft review shows colour-coded confidence indicators.
- [x] Data not saved until user taps "Confirmar".
- [x] "Descartar" discards draft without saving.

**Migration:**
- [x] Existing Milestone 1 properties load without error.
- [x] Existing properties default to `locationSource = .manual`, `isExactLocationShareable = false`, `includedItems = []`, `excludedItems = []`.

**Exclusions verified:**
- [x] No `PhotosPicker`, no camera permission, no Photos framework.
- [x] No network requests during `LocalListingParser` import.
- [x] No keyboard extension UI changes.
- [x] No App Group capability changes.
- [x] No AI or backend calls.

---

## 10. Manual Testing: Notes Application (Simulator or Device)

Use the iOS Notes app to test basic keyboard behavior in a low-risk environment before testing in production messaging apps.

- [ ] Install app, enable keyboard in Settings, grant Full Access.
- [ ] Open Notes, switch to SunsetsAIKeyboard.
- [ ] Verify the active property bar is visible.
- [ ] Change the active property. Confirm the bar updates.
- [ ] Tap a quick action. Confirm the correct text appears in the Notes input field.
- [ ] Import a clipboard message. Confirm the text appears in the import area.
- [ ] Verify no text is inserted before tapping Insert.
- [ ] Tap Insert. Confirm the text appears in the Notes input field.
- [ ] Verify that inactive/rented properties show the warning badge.
- [ ] Verify the stale-cache warning when the cache is older than 24 hours.

---

## 11. Manual Testing: Messenger

- [ ] Open Messenger. Switch to SunsetsAIKeyboard.
- [ ] Select a property. Confirm the active property bar is correct.
- [ ] Open a test conversation with a test account.
- [ ] Tap a quick action. Confirm the text appears in the Messenger input field (but is NOT sent).
- [ ] Tap Insert for an AI-generated response. Confirm it appears in the input field (but is NOT sent).
- [ ] Manually tap Send. Confirm the message is sent correctly.
- [ ] Switch to a different property. Confirm the keyboard state updates.

---

## 12. Manual Testing: WhatsApp

Same checklist as Messenger above, executed in WhatsApp.

- [ ] Switch to SunsetsAIKeyboard inside a WhatsApp conversation.
- [ ] Verify quick action insertion.
- [ ] Verify AI response insertion.
- [ ] Confirm that tapping Insert does not trigger an automatic send.

---

## 13. Manual Testing: Facebook Marketplace

- [ ] Open a Marketplace listing conversation.
- [ ] Switch to SunsetsAIKeyboard.
- [ ] Verify property search and selection.
- [ ] Verify quick action insertion.
- [ ] Confirm text is not sent automatically.

---

## 14. Physical Device Requirements

The following tests cannot be performed reliably on the iOS Simulator:

- App Group data sharing between main app and keyboard extension.
- Keyboard extension memory behavior.
- `textDocumentProxy.insertText()` in production messaging apps.
- Full Access granted state.
- Real network behavior for AI generation.

Every milestone that includes keyboard extension changes must be verified on a physical iPhone before the milestone is marked complete.

**Minimum devices for Milestone 6 (TestFlight):**
- Cristian's iPhone
- Yessy's iPhone

---

## 15. Test File Organization (Proposed, Milestone 1.1 additions)

```
SunsetsAIKeyboardTests/
├── Models/
│   └── PropertySchemaTests.swift
├── AppGroup/
│   ├── CatalogCacheServiceTests.swift      # Updated for location projection
│   └── AppGroupStoreTests.swift
├── Services/
│   ├── TemplateEngineTests.swift           # Updated for {{googleMapsURL}}, {{publicLocation}}
│   ├── IntentClassifierTests.swift
│   └── PropertySearchTests.swift

SunsetsPropertiesTests/
├── Models/
│   ├── PropertyValidationTests.swift
│   └── PropertyDraftTests.swift            # NEW (Milestone 1.1)
├── Repositories/
│   └── MockPropertyRepositoryTests.swift
└── Services/
    ├── InternalCodeGeneratorTests.swift    # NEW (Milestone 1.1)
    ├── GoogleMapsURLImporterTests.swift    # NEW (Milestone 1.1)
    ├── LocalListingParserTests.swift       # NEW (Milestone 1.1)
    ├── CatalogCacheProjectionTests.swift   # NEW (Milestone 1.1)
    └── MigrationDecoderTests.swift        # NEW (Milestone 1.1)
```

---

## 16. CI Considerations (Future)

- Unit and integration tests should run in CI on every pull request.
- Physical-device tests are gated to milestone completion; they are not part of per-PR CI.
- **Unit tests** use Swift Testing (`import Testing`), available since Xcode 15 / Swift 5.9. This is the approved framework for all unit and integration tests.
- **UI tests** use XCTest (`import XCTest`), which is required for `XCUIApplication`-based tests.
- No third-party test frameworks are approved.
