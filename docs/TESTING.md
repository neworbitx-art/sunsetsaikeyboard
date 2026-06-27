# Testing Strategy — Sunsets AI

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27
**Status:** Approved

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

## 3. App Group Serialization Tests

These tests verify the contract between the main application and the keyboard extension.

- Verify that `CatalogCacheService` writes a valid JSON file to the App Group container.
- Verify that `CatalogReader` reads and deserializes the same file into an identical `[KeyboardProperty]` array.
- Verify that a `Property` containing all optional nil fields serializes and deserializes without error.
- Verify that a `Property` with the maximum expected field lengths (e.g., 500-char `visitInstructions`) round-trips correctly.
- Verify that `catalog_updated_at` is written and readable as a Unix timestamp.
- Verify that `active_property_id` written by the keyboard is readable by the main app and vice versa.
- Verify that `recent_property_ids` maintains FIFO order capped at 5 entries.
- Verify that writing an empty catalog (zero properties) does not crash the reader.

---

## 4. Keyboard Insertion Tests

- Verify that `textDocumentProxy.insertText()` is called exactly once per Insert tap.
- Verify that the inserted string matches the previewed response exactly.
- Verify that no insertion occurs when the agent has not tapped Insert.
- Verify that `insertText` is not called when the keyboard opens.
- These tests use a mock `UITextDocumentProxy`.

---

## 5. Offline Tests

- Verify that the keyboard loads the cached catalog when no network is available.
- Verify that deterministic template responses are generated when offline.
- Verify that the AI generate button is disabled when offline.
- Verify that the offline indicator is visible when the network is unavailable.
- Verify that re-establishing network connectivity re-enables the AI generate button.

---

## 6. Stale Cache Tests

- Verify that a cache written more than 24 hours ago triggers the stale-data warning badge.
- Verify that a cache written within 24 hours does not trigger the warning.
- Verify that template responses are still generated from stale data (staleness is a warning, not a blocker).
- Verify that the warning disappears after the main application refreshes the cache.

---

## 7. Active Property Switching Tests

- Verify that selecting a different property updates the active property bar immediately.
- Verify that quick actions reflect the newly selected property's data after switching.
- Verify that AI generation uses the newly selected property's context after switching.
- Verify that switching properties does not clear the keyboard's search results.
- Verify that a property switch made in the keyboard is reflected when the main application next reads `active_property_id`.
- Verify that selecting an `inactive` property shows a warning and blocks availability-confirmation templates.

---

## 8. Manual Testing: Notes Application (Simulator or Device)

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

## 9. Manual Testing: Messenger

- [ ] Open Messenger. Switch to SunsetsAIKeyboard.
- [ ] Select a property. Confirm the active property bar is correct.
- [ ] Open a test conversation with a test account.
- [ ] Tap a quick action. Confirm the text appears in the Messenger input field (but is NOT sent).
- [ ] Tap Insert for an AI-generated response. Confirm it appears in the input field (but is NOT sent).
- [ ] Manually tap Send. Confirm the message is sent correctly.
- [ ] Switch to a different property. Confirm the keyboard state updates.

---

## 10. Manual Testing: WhatsApp

Same checklist as Messenger above, executed in WhatsApp.

- [ ] Switch to SunsetsAIKeyboard inside a WhatsApp conversation.
- [ ] Verify quick action insertion.
- [ ] Verify AI response insertion.
- [ ] Confirm that tapping Insert does not trigger an automatic send.

---

## 11. Manual Testing: Facebook Marketplace

- [ ] Open a Marketplace listing conversation.
- [ ] Switch to SunsetsAIKeyboard.
- [ ] Verify property search and selection.
- [ ] Verify quick action insertion.
- [ ] Confirm text is not sent automatically.

---

## 12. Physical Device Requirements

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

## 13. Test File Organization (Proposed)

```
SunsetsAIKeyboardTests/
├── Models/
│   └── PropertySchemaTests.swift
├── AppGroup/
│   ├── CatalogCacheServiceTests.swift
│   └── AppGroupStoreTests.swift
├── Services/
│   ├── TemplateEngineTests.swift
│   ├── IntentClassifierTests.swift
│   └── PropertySearchTests.swift
└── Keyboard/
    └── TextInsertionTests.swift

SunsetsPropertiesTests/
├── Models/
│   └── PropertyValidationTests.swift
└── Repositories/
    └── MockPropertyRepositoryTests.swift
```

---

## 14. CI Considerations (Future)

- Unit and integration tests should run in CI on every pull request.
- Physical-device tests are gated to milestone completion; they are not part of per-PR CI.
- XCTest is the test framework for all iOS tests.
- No third-party test frameworks are approved yet.
