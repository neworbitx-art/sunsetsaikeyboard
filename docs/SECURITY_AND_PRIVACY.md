# Security and Privacy — Sunsets AI

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27
**Status:** Approved

---

## 1. Threat Model Summary

This product handles two categories of sensitive data:

1. **Company property data** — prices, addresses, internal codes, availability, requirements.
2. **Customer message excerpts** — voluntarily imported by the agent; may contain personal names, contact information, or negotiation details.

These two categories are intentionally separated throughout the system.

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

- **Allowed:** `KeyboardProperty` fields as defined in `PROPERTY_SCHEMA.md` Section 4.
- **Not allowed:** Full property addresses, assigned agent IDs, Keychain tokens, auth tokens, customer messages.
- The App Group UserDefaults must not store the user's password or authentication credentials.
- The keyboard cache file does not contain customer data.

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

## 7. Local Cache Clearing

- The keyboard-safe cache in the App Group is cleared and rebuilt whenever the main application performs a successful sync.
- Agents should be able to manually clear the local cache from the main application settings.
- If an agent is deprovisioned (future, Milestone 5), their local cache and Keychain tokens must be cleared.
- Clearing the cache does not affect the remote Supabase data.

---

## 8. Logging Restrictions

- Production builds must not log:
  - Authentication tokens
  - Customer message content
  - Full property addresses
  - Personal information of any kind
- Debug builds may log non-sensitive operational data (property IDs, event types, cache sizes).
- The backend must log only: `userId`, `propertyId`, `eventType`, HTTP method, status code, and response time. The `customerMessage` field is explicitly excluded from server logs.
- Remote crash logging (e.g., Crashlytics) may be added in a later milestone. It must be configured to exclude sensitive data before enabling.

---

## 9. Full Access Explanation

iOS requires the user to grant **Full Access** to enable network requests from a keyboard extension. Granting Full Access does not allow the keyboard to transmit any keystrokes typed in other keyboards; that is a common misconception.

The main application must display a clear explanation of Full Access before directing the user to iOS Settings:

> "SunsetsAIKeyboard requests Full Access only to connect to our secure server for AI-assisted responses. It does not read or transmit text you type in other apps or other keyboards."

The application must not request Full Access before explaining why it is needed.

---

## 10. Network Security

- All backend communication uses HTTPS (TLS 1.2+).
- Certificate pinning is not required in Milestone 4 but should be evaluated before public distribution.
- The backend URL is not hardcoded with embedded secrets. The base URL (without credentials) may be stored in a config file.
- The backend enforces CORS restrictions to prevent unauthorized web clients from calling it.
- All API endpoints validate authentication before processing any request body.

---

## 11. Separation of Property Data and Customer Messages

This is a core architectural principle:

| Layer | Stores property data? | Stores customer messages? |
|-------|----------------------|--------------------------|
| Supabase (remote) | Yes, full catalog | No |
| Main app local storage | Yes, full catalog | No |
| App Group cache | Yes, keyboard-safe fields only | No |
| Keyboard runtime memory | Yes, keyboard-safe fields | Temporarily, current session only |
| Backend logs | Property ID only | Never |
| Backend AI context | Yes, keyboard-safe fields | Yes, current request only |
| Anthropic (via backend) | Yes, keyboard-safe fields | Yes, current request only |

Customer messages are never written to disk or any persistent storage by this product.

---

## 12. App Store and Apple Guidelines Compliance

- The keyboard must not use the Accessibility API to read conversation content from host apps.
- The keyboard must not use screen recording APIs.
- The keyboard must not inject scripts into host applications.
- The Full Access permission must be used only for the stated purpose (backend AI calls and App Group access).
- The privacy policy must accurately describe Full Access usage before the app is submitted to the App Store.

---

## 13. Open Privacy Decisions Requiring Human Approval

The following decisions have not yet been made and require explicit approval before Milestone 5:

1. **Privacy policy language** for the App Store listing.
2. **Data retention policy** for backend AI generation logs.
3. **Certificate pinning** — required or deferred to a future release?
4. **Remote crash logging** — which provider, and what data is excluded?
5. **Analytics data** — which events are recorded, stored for how long, and are they associated with individual user IDs?
