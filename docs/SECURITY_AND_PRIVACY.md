# Security and Privacy — Sunsets AI

**Version:** 0.3 (Milestone 1.1 — Pending approval)
**Last updated:** 2026-06-27
**Status:** Pending approval

---

## 1. Threat Model Summary

This product handles two categories of sensitive data:

1. **Company property data** — prices, addresses, internal codes, availability, requirements.
2. **Customer message excerpts** — voluntarily imported by the agent; may contain personal names, contact information, or negotiation details.

These two categories are intentionally separated throughout the system.

**Milestone 1.1 addition:** A third sub-category of property data is now distinguished:

3. **Private location data** — full street address, geocoded formatted address, and (by default) exact GPS coordinates. These fields carry a higher privacy risk than the public-facing location summary and are handled with additional controls.

---

## 2. Secret Management

### iOS Application

- **No API keys are embedded in the iOS application.** This is an absolute rule. Violating it allows anyone who installs the app to extract and misuse company API credentials.
- No Supabase keys, Anthropic keys, Vercel URLs with embedded secrets, or any other credentials are to appear in:
  - Swift source files
  - `.plist` files (including `Info.plist`)
  - `xcconfig` files committed to the repository
  - Hardcoded string literals
- Environment variables are not available at iOS runtime.
- Future configuration (e.g., backend base URL, Supabase public anon key) that is truly public may be stored in a committed config file. If in doubt, keep it out of the repo.
- **No Google Maps API key is embedded in the app.** Google Maps links are generated from coordinates using the public URL format `https://www.google.com/maps?q={lat},{lon}`. No API key is required or permitted for this operation.

### iOS Keychain

- The authenticated user's `accessToken` and `refreshToken` are stored in the iOS Keychain.
- The keyboard extension accesses the token via a shared Keychain access group (requires configuration in both entitlement files).
- Tokens must be deleted from the Keychain on logout.

### Backend (Vercel)

- The Anthropic API key is stored in Vercel environment variables.
- The Supabase service role key (if used server-side) is stored in Vercel environment variables.
- These values are never returned in API responses.
- Environment variables are not logged.

---

## 3. Authentication Expectations

- Authentication is out of scope until Milestone 5.
- Until then, the application operates with mocked user identities and no token validation.
- When authentication is implemented, it must use Supabase Auth with JWT tokens.
- The backend must validate the JWT on every authenticated request before processing.
- Role claims (`administrator`, `agent`) must be verified from the JWT payload, not from a request body parameter.
- Expired tokens must be rejected with HTTP 401.

---

## 4. App Group Data Limitations

The App Group shared container (`group.com.sunsetsrealestate.sunsetsai`) is readable by any process in the same App Group. Because the keyboard extension runs in a shared context, only minimally sensitive data is stored here:

- **Allowed:** `KeyboardProperty` fields as defined in `PROPERTY_SCHEMA.md` Section 6.
- **Not allowed:** Full property addresses, formatted geocoded addresses, assigned agent IDs, Keychain tokens, auth tokens, customer messages.
- The App Group UserDefaults must not store the user's password or authentication credentials.
- The keyboard cache file does not contain customer data.

**Milestone 1.1 — Location field controls in the App Group:**

| Field | App Group allowed? | Condition |
|-------|-------------------|-----------|
| `locationSummary` | Yes | Always |
| `publicLocationLabel` | Yes | Always (when set) |
| `googleMapsURL` | Yes | Always (when set) — public link |
| `latitude` / `longitude` | Conditional | Only when `isExactLocationShareable == true` |
| `fullAddress` | **Never** | Absolute rule |
| `formattedAddress` | **Never** | Absolute rule |
| `locationSource` | No | Internal metadata |

The `CatalogCacheService` is responsible for enforcing these rules when building `KeyboardProperty` objects for the cache. The check must be performed even when `latitude` and `longitude` are set in the main `Property` model.

---

## 5. Clipboard Privacy

- The keyboard never reads the pasteboard automatically, in the background, or on a timer.
- The pasteboard is accessed only when the user explicitly taps **Import from clipboard**.
- The imported text is displayed in a visible text area so the user can confirm what was imported.
- The imported message is used only for the current generation session. It is not persisted to disk, the App Group, or any log.
- iOS 16+ shows a pasteboard access banner to the user; this is expected and correct behavior.

---

## 6. Customer Data Minimization

- The keyboard never stores a customer's message permanently.
- The backend receives only the minimum necessary context per `docs/API_CONTRACTS.md` Section 3.
- The backend must not log the `customerMessage` field.
- No complete conversation history is ever stored by this product.
- Customer names and contact details, if present in an imported message, are passed to the backend but must not be retained in backend logs or storage beyond the duration of the request.

---

## 7. Listing Import — Data Minimization

Listing import (Milestone 1.1) introduces a workflow where a property description text is parsed on-device. The following rules apply:

- **Contact information** extracted from listings (phone numbers, email addresses, agent names) is displayed in the `DraftReviewView` for reference only. It must never be saved to the `Property` model.
- **Hashtags and social media handles** extracted from listings are displayed for context. They are not mapped to any `Property` field.
- **The `sourceDescription` field** (original pasted text) is retained in the `PropertyDraft` only for the duration of the review session. It is not written to the App Group or included in the final saved `Property`.
- `LocalListingParser` performs all parsing on-device. No listing text is sent to any server during the Milestone 1.1 listing import workflow.
- The `ClaudeListingParser` (Milestone 4+) will send the listing text to the backend. Before implementing it, confirm that listing text does not contain customer-identifying information. If it does, redact before sending.

---

## 8. Location Privacy

**Private vs. public location data:**

The system distinguishes between:

- **Private location data** — `fullAddress` (complete street address), `formattedAddress` (geocoded from MapKit). These are stored only in the main application's local repository and must never be written to the App Group.
- **Public location data** — `locationSummary`, `publicLocationLabel`, `googleMapsURL`. These are safe to include in the keyboard cache.
- **Conditional location data** — `latitude` and `longitude`. These are stored in the main app's repository but are included in the keyboard cache only when the administrator has explicitly set `isExactLocationShareable = true`.

**Why this matters:**

For rental properties and residential addresses, sharing exact GPS coordinates in the keyboard cache means those coordinates could appear in customer messages if an agent uses the "Location with map" template. This may be appropriate for commercial properties or new developments but inappropriate for residential addresses with identifiable residents.

The agent (administrator) makes this decision per property. The default is **private** (`isExactLocationShareable = false`).

**Location Services:**

- Location Services (`CLLocationManager`) are not used in Milestone 1.1. The map picker defaults to Guatemala City and allows the user to drag a pin without needing the user's current location.
- If "use my current location" is added in a future milestone, `NSLocationWhenInUseUsageDescription` must be added to `Info.plist` and reviewed for clarity before shipping. The usage description must accurately describe why the app needs the location (e.g., "to help you pin the property's location on the map").
- The keyboard extension must never request Location Services permission.

---

## 9. Local Cache Clearing

- The keyboard-safe cache in the App Group is cleared and rebuilt whenever the main application performs a successful sync.
- Agents should be able to manually clear the local cache from the main application settings.
- If an agent is deprovisioned (future, Milestone 5), their local cache and Keychain tokens must be cleared.
- Clearing the cache does not affect the remote Supabase data.

---

## 10. Logging Restrictions

- Production builds must not log:
  - Authentication tokens
  - Customer message content
  - Full property addresses (`fullAddress` or `formattedAddress`)
  - GPS coordinates (`latitude`, `longitude`) unless they are already publicly marked as shareable
  - Personal information of any kind
- Debug builds may log non-sensitive operational data (property IDs, event types, cache sizes).
- The backend must log only: `userId`, `propertyId`, `eventType`, HTTP method, status code, and response time. The `customerMessage` field is explicitly excluded from server logs.
- Remote crash logging (e.g., Crashlytics) may be added in a later milestone. It must be configured to exclude sensitive data before enabling.

---

## 11. Full Access Explanation

iOS requires the user to grant **Full Access** to enable network requests from a keyboard extension. Granting Full Access does not allow the keyboard to transmit any keystrokes typed in other keyboards; that is a common misconception.

The main application must display a clear explanation of Full Access before directing the user to iOS Settings:

> "SunsetsAIKeyboard requests Full Access only to connect to our secure server for AI-assisted responses. It does not read or transmit text you type in other apps or other keyboards."

The application must not request Full Access before explaining why it is needed.

---

## 12. Network Security

- All backend communication uses HTTPS (TLS 1.2+).
- Certificate pinning is not required in Milestone 4 but should be evaluated before public distribution.
- The backend URL is not hardcoded with embedded secrets. The base URL (without credentials) may be stored in a config file.
- The backend enforces CORS restrictions to prevent unauthorized web clients from calling it.
- All API endpoints validate authentication before processing any request body.

---

## 13. Separation of Property Data and Customer Messages

This is a core architectural principle:

| Layer | Stores property data? | Stores customer messages? |
|-------|----------------------|--------------------------|
| Supabase (remote) | Yes, full catalog | No |
| Main app local storage | Yes, full catalog | No |
| App Group cache | Yes, keyboard-safe fields only (excl. full address) | No |
| Keyboard runtime memory | Yes, keyboard-safe fields | Temporarily, current session only |
| Backend logs | Property ID only | Never |
| Backend AI context | Yes, keyboard-safe fields | Yes, current request only |
| Anthropic (via backend) | Yes, keyboard-safe fields | Yes, current request only |

Customer messages are never written to disk or any persistent storage by this product.

---

## 14. App Store and Apple Guidelines Compliance

- The keyboard must not use the Accessibility API to read conversation content from host apps.
- The keyboard must not use screen recording APIs.
- The keyboard must not inject scripts into host applications.
- The Full Access permission must be used only for the stated purpose (backend AI calls and App Group access).
- The privacy policy must accurately describe Full Access usage before the app is submitted to the App Store.
- No `PhotosPicker` or `PHPhotoLibrary` access is used in any milestone through Milestone 1.1. If photo access is added in a future milestone, `NSPhotoLibraryUsageDescription` must be added and reviewed by a human.

---

## 15. Open Privacy Decisions Requiring Human Approval

The following decisions have not yet been made and require explicit approval before the indicated milestone:

1. **Privacy policy language** for the App Store listing. (Milestone 6)
2. **Data retention policy** for backend AI generation logs. (Milestone 5)
3. **Certificate pinning** — required or deferred to a future release? (Milestone 4)
4. **Remote crash logging** — which provider, and what data is excluded? (Milestone 5)
5. **Analytics data** — which events are recorded, stored for how long, and are they associated with individual user IDs? (Milestone 5)
6. **"Use my current location" in map picker** — if added, Location Services permission and usage description must be reviewed before shipping. (Post–Milestone 1.1)
7. **Listing import with ClaudeListingParser** — confirm listing text does not contain customer PII before sending to backend. (Milestone 4)
