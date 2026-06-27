# Product Specification — Sunsets AI Keyboard

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27
**Status:** Approved

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

---

## 2. Target Users

### Administrator
- Creates and manages the property catalog.
- Sets prices, statuses, availability, requirements, and visit instructions.
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
- **Add property details:** bedrooms, bathrooms, parking, area, location summary.
- **Add amenities:** pool, gym, rooftop, parking type, and similar.
- **Add appliances:** which appliances are included with the property.
- **Set requirements:** credit check, employment proof, income multiplier, etc.
- **Set pet policy:** allowed, not allowed, allowed with deposit, or case-by-case.
- **Add visit instructions:** how to schedule, who to contact, access notes.
- **Create quick-reply templates** scoped to a specific property.
- **Search and filter** the catalog by title, status, price range, operation type, or location.
- **Mark a property as a favorite** for quick access from the keyboard.

### 3.2 Validation Before Keyboard Availability

A property is not pushed to the keyboard-safe App Group cache unless all of the following fields are populated:

- `title`
- `operationType`
- `status`
- `price` and `currency`
- `locationSummary`
- `bedrooms` and `bathrooms`

Properties with status `inactive` are included in the cache but clearly labeled and must not generate availability confirmations.

### 3.3 Active Property Selection

- An administrator or agent may designate any catalog property as the **active property** from within the main application.
- Selecting an active property writes the property's ID to the shared App Group.
- The keyboard reads the active property ID from the App Group on launch.

### 3.4 Synchronization (Future — Milestone 5)

- The main application pulls the canonical property catalog from Supabase.
- After a successful sync, the application rebuilds the keyboard-safe App Group cache.
- The application stores a catalog version token to enable incremental sync.

---

## 4. SunsetsAIKeyboard — Keyboard Extension

### 4.1 Activation

The keyboard cannot be activated automatically. The user must:

1. Install the Sunsets Properties application.
2. Open iOS Settings → General → Keyboard → Keyboards → Add New Keyboard.
3. Select **SunsetsAIKeyboard**.
4. Grant **Full Access** when prompted (required for App Group access and network calls).
5. Manually switch to the keyboard inside a conversation using the iOS keyboard selector (globe icon).

The main application must include an in-app setup guide explaining these steps.

### 4.2 Home Screen Layout

When the keyboard opens, the user sees:

- **Active property bar** (always visible): displays the selected property's title, operation type, price, and status.
- **Recently used properties** (up to 5, persisted in App Group).
- **Favorite properties** (persisted as `isFavorite` in the App Group cache).
- **Property search field**.
- **Quick action buttons** for the active property.
- **Customer message import** button (explicit clipboard paste).
- **AI generate** button (only enabled when an active property is selected).

### 4.3 Property Selection

- The user can search and select any cached property without leaving the keyboard.
- Selecting a property:
  1. Sets it as the active property in the App Group.
  2. Updates the active property bar immediately.
  3. Adds it to the recently used list.
- The active property persists across keyboard sessions until the user changes it.
- Properties with status `inactive`, `rented`, or `sold` are shown with a visual warning badge. They may be selected but the keyboard will not generate availability confirmations for them.
- The keyboard warns the user if the cached property data is more than 24 hours old.

### 4.4 Customer Message Import

- The user explicitly taps **Import from clipboard** to paste the customer's message.
- The keyboard never reads the clipboard automatically or in the background.
- The imported message is shown in a dedicated text area for the agent to review before generating a reply.
- The imported message is used only for the current generation request. It is not stored persistently.

### 4.5 Response Generation

#### Deterministic Templates (First Choice)

For questions that map to verified property facts, the keyboard selects or renders a property-specific quick-reply template:

- Price
- Location summary
- Availability
- Bedrooms, bathrooms, area
- Amenities
- Included appliances
- Requirements
- Pet policy
- Visit scheduling instructions

Templates are rendered locally using the cached property data. No network call is made.

#### AI-Assisted Generation (Second Choice)

The keyboard calls the backend AI service when:

- The customer's intent is ambiguous and does not match a deterministic template.
- The agent requests a different tone (formal, friendly, concise).
- Multiple verified facts need to be combined naturally.
- The agent explicitly taps **Generate with AI**.

The backend receives:

- Authorized user identifier.
- Selected property (keyboard-safe fields only).
- The explicitly imported customer message.
- Requested response style.
- No other context.

The AI response is displayed inside the keyboard for review. It is never inserted automatically.

#### Negotiation and Unknown Intents

If the customer is asking about price negotiation or the intent cannot be classified, the keyboard flags the message as requiring human judgment and does not generate a response.

### 4.6 Text Insertion

- The agent reviews the generated response in the keyboard preview area.
- The agent taps **Insert** to place the text into the conversation input field via `textDocumentProxy.insertText()`.
- The keyboard never sends the message. The agent must send it manually in the host app.

### 4.7 Quick Actions

For the active property, the keyboard exposes one-tap quick actions:

- Share price
- Share location summary
- Share availability status
- Share visit instructions
- Share requirement list
- Share amenity list

Each quick action renders a pre-formatted string from the cached property data and inserts it directly without calling the backend.

---

## 5. Offline Behavior

- The keyboard functions fully offline for deterministic template responses.
- AI generation requires network access. The keyboard displays a clear offline indicator and disables the AI generate button when offline.
- The App Group cache remains available indefinitely until the main application overwrites it.

---

## 6. State Inventory

| State | User-visible behavior |
|-------|----------------------|
| No active property | Active property bar shows "No property selected". Quick actions and AI generate are disabled. |
| Property selected, data fresh | Normal operation. |
| Property selected, data stale (>24 h) | Warning badge on active property bar. Templates still available. |
| Property inactive / rented / sold | Warning badge. Quick actions available. Availability confirmation blocked. |
| No cached catalog | Empty state with instruction to open the main application and sync. |
| AI generation in progress | Loading indicator in keyboard. Insert button disabled. |
| AI generation error | Error message. Previous response (if any) remains. Retry available. |
| Offline | AI generate button disabled. Deterministic templates still work. |

---

## 7. Acceptance Criteria

### Main Application

- [ ] An administrator can create a property with all required fields and have it appear in the App Group cache.
- [ ] Changing a property's status in the app updates the cached value within 5 seconds.
- [ ] A property with missing required fields cannot be pushed to the cache.
- [ ] Selecting an active property in the app updates the shared active property ID.
- [ ] Properties with status `inactive`, `rented`, or `sold` appear with a clear status label.

### Keyboard

- [ ] The keyboard opens and shows the active property bar on every launch.
- [ ] The user can change the active property without closing the keyboard.
- [ ] Selecting a new property updates the active property bar immediately.
- [ ] Tapping a quick action inserts correctly formatted text into the host app's text field.
- [ ] The user can import a customer message via explicit clipboard paste.
- [ ] The keyboard does not read the clipboard without user action.
- [ ] AI generation is disabled when offline.
- [ ] A stale-cache warning appears when cached data is more than 24 hours old.
- [ ] No message is sent without the agent tapping Send in the host application.
- [ ] The keyboard handles inactive/rented/sold properties without generating availability confirmations.
