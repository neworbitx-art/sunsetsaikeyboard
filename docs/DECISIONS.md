# Architecture Decision Records — Sunsets AI

**Last updated:** 2026-06-27

Decisions are recorded here in reverse-chronological order (newest first). Each record follows the ADR format: Context → Decision → Alternatives → Consequences → Status.

---

## ADR-014 — Sale financing model and FHA eligibility (Milestone 1.1 refinement)

**Date:** 2026-06-27
**Status:** Accepted

### Context
Real estate agents in Guatemala must communicate financing options to buyers. The primary path is bank financing (typically 70–80% of purchase price). FHA is an explicitly government-certified program that not all properties qualify for. Agents need to accurately represent whether a property "Aplica FHA" or not — guessing is a liability.

### Decision
Three new fields are added to `Property` for sale properties only: `sellerFinancingStatus` (`.unavailable` / `.available` / `.unknown`), `fhaEligibility` (`.eligible` / `.notEligible` / `.unknown`), and `financingNotes`.

`FinancingTextService` generates deterministic Spanish text: when `sellerFinancingStatus == .unavailable`, the bank financing paragraph is shown; FHA paragraph is appended only when `fhaEligibility == .eligible`; when `.unknown`, an internal warning is displayed rather than generated text.

`LocalListingParser` detects "Aplica FHA" / "No aplica FHA" explicitly; it never infers FHA eligibility from any other text. When no FHA phrase is found, `fhaEligibility` is `.unknown`.

The financing UI section (form and detail) is hidden for rental-only properties. Fields are present in the model for all properties but only surfaced when `operationType == .sale || .rentOrSale`.

Simultaneously, `PetPolicy` is reduced from 4 to 3 cases: `allowedWithDeposit` and `caseByCase` are removed and their legacy JSON values are mapped to `subjectToCaseAnalysis` in the migration decoder.

### Alternatives Considered
- **Always show FHA fields regardless of operation type:** Clutters the rental workflow. Rejected.
- **Infer FHA eligibility from price range or neighborhood:** Too risky — incorrect information could mislead buyers. FHA eligibility is a legal determination, not an inference. Rejected.
- **Use `.notEligible` as default instead of `.unknown`:** Would silently misrepresent properties that haven't been evaluated. Rejected.

### Consequences
- Two new model types (`SellerFinancingStatus`, `FHAEligibility`) are added to the `Models` group.
- `FinancingTextService` in `Services` is the canonical source of financing text.
- Financing fields decode with safe defaults from old JSON (all `.unknown` / `false`).

---

## ADR-013 — Property media deferred to a future milestone

**Date:** 2026-06-27
**Status:** Accepted

### Context
Property photographs and media assets would improve the product, but they introduce significant complexity: Photos Library permissions, binary storage (local and remote), Supabase Storage integration, cache size pressure on the keyboard extension, and App Store privacy disclosures. Attempting media alongside Milestone 1.1 would make the diff untestable.

### Decision
Property media (photographs, cover images, albums, gallery URLs, image sharing) is explicitly out of scope through at least Milestone 1.1. No image-related fields are added to `Property`, `KeyboardProperty`, or the keyboard cache. No `PhotosPicker` is added. No Photos Library permission is requested. The keyboard remains text-oriented.

A dedicated architectural review and milestone will be defined before any media work begins.

### Alternatives Considered
- **Include basic photo field (URL string only):** Would add a placeholder without adding Photos Library access, but creates schema debt and confusion. Rejected.
- **Supabase Storage in Milestone 5:** Property media can be bundled with the full backend milestone. This is the preferred future approach.

### Consequences
- No `PhotosPicker`, no `PHPhotoLibrary`, no image binary data in local storage.
- The `Property` model has no image fields until a media milestone is approved.
- Agents cannot share photos via the keyboard in any milestone through Milestone 1.1.

---

## ADR-012 — Listing text import with local parser and future Claude upgrade

**Date:** 2026-06-27
**Status:** Accepted

### Context
Real estate agents frequently copy listing descriptions from WhatsApp, MLS systems, or internal documents. Requiring them to re-type every field is error-prone and slow. A text import workflow reduces manual entry and provides structured data with a human review step.

### Decision
A `ListingImportService` accepts a pasted listing description and returns a `PropertyDraft`. In Milestone 1.1:
- `LocalListingParser` performs deterministic regex/string matching entirely on-device, with no network calls.
- Every detected field carries a `DraftConfidence` level (high / medium / low / missing).
- The draft is displayed for review; the user corrects any field before confirming.
- Nothing is saved until the user explicitly confirms.
- The original `sourceDescription` is preserved in the draft for comparison.

A `ClaudeListingParser` is defined as a protocol conformance reserved for Milestone 4+:
- It must call the backend `POST /import/listing` endpoint (not the Anthropic API directly from the iOS app).
- It must never save data without human review.
- It must mark uncertain fields.

### Alternatives Considered
- **Client-side AI parsing now:** Embedding a language model on-device is impractical at current iOS memory budgets and adds no App Store-reviewable value before Milestone 4. Rejected.
- **No import workflow:** Defers user experience improvement. Rejected — the local parser can deliver immediate value without any backend.
- **Auto-save on import:** Bypasses human review, risking incorrect data in the catalog. Explicitly rejected.

### Consequences
- `PropertyDraft`, `DraftField<T>`, `DraftConfidence`, `ListingImportService`, and `LocalListingParser` become part of the Milestone 1.1 scope.
- `ClaudeListingParser` is defined as a protocol stub; its implementation is blocked until Milestone 4.
- Contact information extracted from listings (`contactInfo`) is displayed for reference only and is never saved to the `Property` model.
- Hashtags extracted from listings are displayed for context but are not mapped to any `Property` field.

---

## ADR-011 — Automatic SUN-### internal code generation

**Date:** 2026-06-27
**Status:** Accepted

### Context
Manual internal codes (e.g., "SUN-042") are required for identifying properties in human communication and in the keyboard cache. Manual assignment is error-prone — agents may duplicate or skip codes.

### Decision
The application generates the next `SUN-###` code automatically by scanning all existing codes, extracting the numeric suffix, finding the maximum, and incrementing by one. The proposed code is displayed to the user before a property is created and may be overridden. Uniqueness is validated before saving; a duplicate is rejected with an error.

**Multi-user safety note:** Local auto-generation is safe for Milestone 1.1 (single-user, offline). When Supabase is introduced (Milestone 5), code generation must move to a PostgreSQL sequence or advisory lock to prevent collisions under concurrent saves.

Deleted or inactive codes are never reused. The generator always scans the full existing set, including inactive properties.

### Alternatives Considered
- **UUID-only, no human code:** Human codes are operationally necessary for agents to communicate ("which property?"). Rejected.
- **Admin-assigned codes only:** Adds cognitive load; auto-generation is a strict improvement. Admins retain override capability.
- **Timestamp-based codes:** Less readable, harder to reference verbally. Rejected.

### Consequences
- `PropertyRepository` gains a method to propose the next code.
- `LocalPropertyRepository` implements the scan-and-increment logic.
- `SupabasePropertyRepository` (Milestone 5) must delegate code generation to the database.
- The `PropertyEditorView` for new properties pre-fills the code field with the proposed value.
- Uniqueness validation runs in `PropertyEditorViewModel.validate()`.

---

## ADR-010 — MapKit for in-app location selection; no Google Maps SDK

**Date:** 2026-06-27
**Status:** Accepted

### Context
Properties require precise coordinates for map display, navigation links, and Google Maps URL generation. Two approaches are available: Apple MapKit (native, no API key, no third-party dependency) or the Google Maps iOS SDK (additional dependency, Google API key required, App Store privacy implications).

### Decision
MapKit (`import MapKit`) is used for all in-app map and address-search experiences in Milestone 1.1. No Google Maps SDK is added. No Google API key is added during Milestone 1.1.

Google Maps is still used as the *link format* for generated shareable URLs, because Google Maps is the dominant navigation app in Guatemala. Generated URLs use the universal format `https://www.google.com/maps?q={lat},{lon}` or `https://maps.app.goo.gl/…` (from URL import), which does not require an API key.

### Alternatives Considered
- **Google Maps iOS SDK:** Requires a Google Cloud API key stored in the app. Violates the rule against embedding keys in iOS apps (CLAUDE.md). Rejected.
- **Apple Maps links only:** Apple Maps links (`https://maps.apple.com/?q=…`) would not serve agents in Guatemala who use Google Maps. Rejected for the primary sharing link; may be offered as an additional option in a future milestone.
- **No map at all:** Loses location precision. Rejected.

### Consequences
- `import MapKit` is added to the `SunsetsProperties` target only.
- Address search uses `MKLocalSearch` with `MKLocalSearchRequest`.
- Map picker uses `Map` (SwiftUI) with a draggable annotation.
- Google Maps URL is generated from coordinates (no API call) or stored from a pasted URL.
- No new entitlements are required for MapKit.
- Location Services permission (`NSLocationWhenInUseUsageDescription`) must be added to `Info.plist` before any `CLLocationManager` usage; this is required only if "use my current location" is offered. The Milestone 1.1 map picker does not need to show the user's current location — it may default to Guatemala City.

---

## ADR-009 — Structured location model with public/private separation

**Date:** 2026-06-27
**Status:** Accepted

### Context
Property locations involve two distinct concerns: a private full address (which must never reach the keyboard extension or be visible in messaging apps) and a public-facing label used in customer replies. Until Milestone 1.1, only `locationSummary` existed — a single free-text field that conflated both concerns.

### Decision
The location model is split into:

| Field | Visibility | Purpose |
|-------|-----------|---------|
| `fullAddress` | Main app only | Private street address; never shared |
| `formattedAddress` | Main app only | Geocoded formatted address from MapKit; never shared |
| `locationSummary` | Keyboard cache ✅ | Existing field; public-facing short label |
| `publicLocationLabel` | Keyboard cache ✅ | Alternate public label; may differ from locationSummary |
| `latitude` / `longitude` | Conditional | In keyboard cache only when `isExactLocationShareable == true` |
| `googleMapsURL` | Keyboard cache ✅ | Public link; safe to share |
| `isExactLocationShareable` | Keyboard cache ✅ | Gate for coordinate sharing |
| `locationSource` | Main app only | Internal tracking; not needed by keyboard |

The agent explicitly decides whether to allow exact coordinates in the keyboard cache. The default is `false` — coordinates are private unless opted in.

### Alternatives Considered
- **Single `locationSummary` field forever:** Loses precision; no map integration. Rejected.
- **Always share coordinates:** Violates privacy principles when properties have residential addresses. Rejected.
- **Separate `PublicLocation` embedded struct:** Cleaner but adds complexity for a v1 schema. Deferred to a future refactor if warranted.

### Consequences
- `KeyboardProperty` gains `publicLocationLabel`, `googleMapsURL`, `isExactLocationShareable`, and conditional `latitude`/`longitude`.
- `CatalogCacheService` must check `isExactLocationShareable` before projecting coordinates.
- Migration: existing properties default to `isExactLocationShareable = false`.
- Location Services permission is optional; the app must function fully without it.

---

## ADR-008 — Project identifiers, deployment target, locale, and keyboard-cache privacy

*(Unchanged from v0.2)*

**Date:** 2026-06-27
**Status:** Accepted

### Context
After Milestone 0 documentation was created, several decisions were left open pending human approval: the minimum iOS version, bundle identifiers, App Group identifier, primary product language, and the exact set of fields to exclude from the keyboard-safe property cache. These decisions needed to be locked before creating the Xcode project.

### Decision

**Project and target names:**
- Overall project name: `Sunsets AI`
- Main application product name: `Sunsets Properties`
- Main application Xcode target: `SunsetsProperties`
- Keyboard extension Xcode target: `SunsetsAIKeyboard`

**Apple identifiers (proposed — pending Apple Developer portal confirmation):**
- Main application bundle ID: `com.sunsetsrealestate.sunsetsproperties`
- Keyboard extension bundle ID: `com.sunsetsrealestate.sunsetsproperties.keyboard`
- Shared App Group: `group.com.sunsetsrealestate.sunsetsai`

**Deployment target:** iOS 17 minimum. iPad is explicitly out of scope for the MVP.

**Primary language:** Spanish for Guatemala (`es-GT`). All templates, UI labels, and default copy use neutral, professional Guatemalan Spanish. English is secondary.

**Organization model:** Single organization (Sunsets Real Estate) for the MVP. Multiple authorized employees within the same organization are supported. Multi-tenant is out of scope.

**Keyboard-cache privacy:** The `KeyboardProperty` cache must exclude:
- `assignedAgentId`
- Full property address (use `locationSummary`)
- Owner information
- Commissions and fee splits
- Private contact details (agent or owner)
- Access codes and key locations
- Internal admin notes

**Privacy policy:** A public privacy policy URL is not required for the local Milestone 1 prototype. It must be created and approved before external TestFlight testing or public distribution. This is a blocker for Milestone 6, not Milestone 1.

### Alternatives Considered
- **iOS 16 minimum:** Wider device support, but excludes several SwiftUI APIs used extensively in iOS 17. Rejected.
- **`com.sunsetsrealestate.sunsetsai` as main bundle ID:** Cleaner but less descriptive. Rejected.
- **Including `assignedAgentId` in keyboard cache:** No template or AI generation feature requires it. Rejected.

### Consequences
- Bundle IDs are locked; changing them after Xcode project creation requires provisioning profile updates.
- The App Group identifier must be registered in the Apple Developer portal before any Xcode build that depends on it.
- All templates default to Spanish (`es-GT`).

---

## ADR-007 — Deterministic templates before AI generation

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

For any customer intent that maps to a known property field (price, location, amenities, availability, requirements, pet policy, visit instructions), the keyboard renders a deterministic template from the cached `KeyboardProperty` data without calling any API.

AI generation is used only when the intent is ambiguous, multiple facts need natural language combination, or the agent explicitly requests a different tone.

---

## ADR-006 — No automatic message sending

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

The keyboard inserts text into the host application's input field via `textDocumentProxy.insertText()`. The agent must then manually tap Send. The keyboard never triggers a send action.

---

## ADR-005 — Explicit clipboard import only (no background monitoring)

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

The keyboard never reads the pasteboard automatically or in the background. The user must tap an explicit **Import from clipboard** button. This applies permanently, not just for early milestones.

---

## ADR-004 — Backend-only Anthropic API access

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

All calls to the Anthropic Messages API are made from the Vercel backend. The iOS keyboard sends a request to the backend's `/generate` endpoint. The iOS application never holds an Anthropic API key.

---

## ADR-003 — App Groups for shared catalog data

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

Both the main application and keyboard extension are members of the App Group `group.com.sunsetsrealestate.sunsetsai`. The shared container stores the keyboard-safe catalog, active property ID, catalog version, and recently-used list.

---

## ADR-002 — UIKit for the keyboard extension

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

The keyboard extension's root is `UIInputViewController` (UIKit). Individual panels may be implemented as SwiftUI views embedded via `UIHostingController`.

---

## ADR-001 — SwiftUI for the main application

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

The main application (`SunsetsProperties`) is built entirely in SwiftUI with Swift Concurrency (async/await).

---

## ADR-000 — One iOS application with an embedded keyboard extension

*(Unchanged from v0.2)*

**Date:** 2026-06-26
**Status:** Accepted

The product is a single Xcode project containing two targets: `SunsetsProperties` (container app) and `SunsetsAIKeyboard` (keyboard extension).
