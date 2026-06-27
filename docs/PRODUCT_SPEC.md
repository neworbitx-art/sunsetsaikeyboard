# Product Specification — Sunsets AI Keyboard

**Version:** 0.3 (Milestone 1.1 — Pending approval)
**Last updated:** 2026-06-27
**Status:** Pending approval

---

## 0. Platform and Locale

- **Minimum iOS version:** iOS 17 (confirmed).
- **Devices:** iPhone only. iPad is explicitly out of scope for the MVP.
- **Primary language:** Spanish for Guatemala (`es-GT`). All templates, UI labels, and default copy use neutral, professional Guatemalan Spanish. English is secondary and not required in the MVP.
- **Organization:** Single organization — Sunsets Real Estate. Multi-tenant support is out of scope.
- **Bundle identifiers (proposed — pending Apple Developer portal confirmation):**
  - Main app: `com.sunsetsrealestate.sunsetsproperties`
  - Keyboard extension: `com.sunsetsrealestate.sunsetsproperties.keyboard`
  - App Group: `group.com.sunsetsrealestate.sunsetsai`

---

## 1. Product Goals

1. Eliminate repetitive typing by giving real estate agents instant access to verified property information while they are inside a conversation.
2. Ensure every message sent to a customer is based solely on verified, up-to-date property data — never on recalled or invented facts.
3. Keep the agent in control: no message is ever sent without the agent reviewing and manually submitting it.
4. Work inside the messaging apps agents already use (Messenger, WhatsApp, Facebook Marketplace) without requiring them to switch apps.
5. Reduce manual data entry through text import with human review.

---

## 2. Target Users

### Administrator
- Creates and manages the property catalog.
- Sets prices, statuses, availability, requirements, and visit instructions.
- Imports property listings via text paste.
- Manages agent accounts (future, Milestone 5).
- Uses the **Sunsets Properties** main application.

### Agent
- Responds to customer inquiries via Messenger, WhatsApp, Facebook Marketplace, or similar apps.
- Uses **SunsetsAIKeyboard** to generate and insert replies without leaving the conversation.
- Cannot edit the property catalog from the keyboard (read-only access to cached data).

---

## 3. Sunsets Properties — Main Application

### 3.1 Catalog Management

Administrators and agents with edit rights may:

- **Create** a new property with all required fields (see `PROPERTY_SCHEMA.md`).
- **Edit** any field of an existing property.
- **Set status** to `available`, `reserved`, `rented`, `sold`, or `inactive`.
- **Set prices:** rent or sale price, currency, maintenance fee, deposit.
- **Add property details:** bedrooms, bathrooms, parking, area, location.
- **Add amenities:** pool, gym, rooftop, parking type, and similar.
- **Add appliances and included/excluded items.**
- **Set requirements:** credit check, employment proof, income multiplier, etc.
- **Set pet policy:** "Se acepta mascota", "No se aceptan mascotas", or "Sujeto a análisis de caso" (3 options).
- **Add visit instructions:** how to schedule, who to contact, access notes.
- **Create quick-reply templates** scoped to a specific property.
- **Search and filter** the catalog by title, status, price range, operation type, or location.
- **Mark a property as a favorite** for quick access from the keyboard.
- **Import a listing description** via text paste (Milestone 1.1).
- **Select a location on a map** or search for an address (Milestone 1.1).
- **Control location sharing** — decide whether exact coordinates are visible in the keyboard cache (Milestone 1.1).
- **Set sale financing information** (sale properties only): seller financing status, bank financing availability, FHA eligibility, and optional notes (Milestone 1.1 refinement).

### 3.2 Automatic Internal Codes

Internal codes follow the format `SUN-###`. The application automatically proposes the next code when a new property is created. The agent may accept or override it.

Requirements:
- The proposed code is determined by scanning all existing codes and incrementing the highest numeric suffix.
- Codes from deleted or inactive properties are never reused.
- Uniqueness is validated before saving; a duplicate is rejected with an error.
- When Supabase is introduced (Milestone 5), code generation must move to the database to prevent multi-user collisions.

### 3.3 Structured Location (Milestone 1.1)

Location data is split into a private component and a public component:

**Private (main app only):**
- `fullAddress` — complete street address.
- `formattedAddress` — geocoded formatted address from MapKit.

**Public (may reach keyboard cache):**
- `locationSummary` — existing short public label (e.g., "Zona 10, Guatemala").
- `publicLocationLabel` — alternate public label that may differ from `locationSummary`.
- `googleMapsURL` — shareable Google Maps link.
- `latitude` / `longitude` — only when `isExactLocationShareable == true`.

Location may be set by:

1. **Map picker** — drag a pin on a MapKit map.
2. **Address search** — type a query, select from `MKLocalSearch` results.
3. **Google Maps URL paste** — paste a Google Maps link; the app extracts and stores the coordinates.
4. **Manual text entry** — type `locationSummary` by hand (existing behavior).

No Google Maps SDK is used. Google Maps URLs are generated from coordinates without an API key.

### 3.4 Listing Text Import (Milestone 1.1)

An import workflow allows administrators to paste a full real-estate listing description and receive a structured draft for review.

Steps:
1. Administrator taps **Importar descripción**.
2. Pastes a listing description into the text area.
3. Application runs `LocalListingParser`, which returns a `PropertyDraft`.
4. The draft review screen shows detected fields alongside their confidence level (high / medium / low / missing).
5. Fields with low or missing confidence are highlighted.
6. Administrator corrects any field directly in the review screen.
7. Administrator taps **Confirmar y crear propiedad** — the property is saved.
8. Tapping **Descartar** discards the draft with no changes.

The original listing text (`sourceDescription`) is displayed alongside the draft for comparison.

Contact information extracted from the listing is shown for reference only and is never saved to the `Property` model.

A future AI-assisted parser (`ClaudeListingParser`) will be added in Milestone 4 and will call the backend; it will never be called directly from the iOS app.

### 3.5 Validation Before Keyboard Availability

A property is not pushed to the keyboard-safe App Group cache unless all of the following fields are populated:

- `title`
- `operationType`
- `status`
- `price` and `currency`
- `locationSummary`
- `bedrooms` and `bathrooms`

Properties with status `inactive` are included in the cache but clearly labeled. They cannot generate availability confirmations.

### 3.6 Active Property Selection

- An administrator or agent may designate any catalog property as the **active property**.
- Selecting an active property writes the property's ID to the shared App Group.
- The keyboard reads the active property ID from the App Group on launch.

### 3.7 Synchronization (Future — Milestone 5)

The main application pulls the canonical property catalog from Supabase. After a successful sync, it rebuilds the keyboard-safe App Group cache.

---

## 4. SunsetsAIKeyboard — Keyboard Extension

*(Unchanged from v0.2 — all keyboard behavior is defined in Milestone 2.)*

The keyboard remains text-oriented. No property image display, photo sharing, or media access is added to the keyboard in any milestone through Milestone 1.1.

### 4.1 Activation

The keyboard cannot be activated automatically. The user must enable it in iOS Settings and grant Full Access.

### 4.2 Home Screen Layout

- Active property bar (always visible): title, operation type, price, status.
- Recently used properties (up to 5).
- Favorite properties.
- Property search field.
- Quick action buttons.
- Customer message import button.
- AI generate button (only enabled when connected and a property is selected).

### 4.3 Property Selection

Standard keyboard property selection. Selecting an active property with a non-available status shows a warning badge.

### 4.4 Customer Message Import

Explicit user tap only. No background clipboard monitoring.

### 4.5 Response Generation

- **Deterministic templates** (first choice): rendered locally from the cached `KeyboardProperty`, including new `{{googleMapsURL}}` and `{{publicLocation}}` tokens when set.
- **AI-assisted generation** (second choice, Milestone 4): via backend.
- **Negotiation / unknown**: flagged for human handling.

### 4.6 Text Insertion

`textDocumentProxy.insertText()`. Agent must tap Send in the host app.

### 4.7 Quick Actions

One-tap actions: share price, location, availability, visit instructions, requirements, amenities. In Milestone 2+, a "Share Google Maps link" quick action is added when `googleMapsURL` is set.

---

## 5. Property Media — Out of Scope

Property photographs, albums, gallery URLs, cover photos, and image sharing are explicitly out of scope through Milestone 1.1. This includes:

- No `PhotosPicker` or `UIImagePickerController`.
- No Photos Library permission request.
- No image binary data in local storage.
- No image fields in `Property` or `KeyboardProperty`.
- No media fields in the keyboard cache.
- No Supabase Storage for images.
- No photo or album sharing in the keyboard.

A separate architectural review and dedicated milestone are required before any media work begins. See ADR-013.

---

## 6. Offline Behavior

- The keyboard functions fully offline for deterministic template responses.
- AI generation requires network access.
- Listing import uses `LocalListingParser` offline. `ClaudeListingParser` requires network (Milestone 4+).
- The App Group cache remains available indefinitely until the main application overwrites it.

---

## 7. State Inventory

| State | User-visible behavior |
|-------|----------------------|
| No active property | Active property bar shows "No hay propiedad activa". Quick actions and AI generate are disabled. |
| Property selected, data fresh | Normal operation. |
| Property selected, data stale (>24 h) | Warning badge on active property bar. Templates still available. |
| Property inactive / rented / sold | Warning badge. Quick actions available. Availability confirmation blocked. |
| No cached catalog | Empty state with instruction to open the main application and sync. |
| AI generation in progress | Loading indicator. Insert button disabled. |
| AI generation error | Error message. Retry available. |
| Offline | AI generate button disabled. Deterministic templates still work. |

---

## 8. Acceptance Criteria

### Main Application (Milestone 1.1 additions)

- [ ] A new property is pre-filled with the next `SUN-###` code.
- [ ] Saving a property with a duplicate code shows an error.
- [ ] A MapKit map picker allows pin placement to set coordinates.
- [ ] Address search via `MKLocalSearch` populates coordinates and formatted address.
- [ ] Pasting a Google Maps URL extracts and stores coordinates.
- [ ] `isExactLocationShareable` defaults to `false`; user must opt in.
- [ ] `formattedAddress` and `fullAddress` never appear in the keyboard cache.
- [ ] Listing import workflow creates a reviewable draft with confidence indicators.
- [ ] No data is saved from import until the user confirms.
- [ ] Existing Milestone 1 properties load without errors after the update.
- [ ] No Photos Library permission is requested anywhere.

### Keyboard (no changes in Milestone 1.1)

- [ ] All Milestone 1 catalog acceptance criteria remain passing.
- [ ] The keyboard UI is unchanged.
