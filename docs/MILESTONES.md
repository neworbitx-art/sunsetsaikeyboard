# Milestones — Sunsets AI Keyboard

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27

Each milestone has a defined scope, explicit exclusions, deliverables, acceptance criteria, testing requirements, known risks, and required human actions. No milestone may begin until the previous one has been explicitly approved.

---

## Milestone 0 — Documentation and Architecture

**Status:** Approved and complete (2026-06-27)

### Objective
Establish the full project documentation, data model, architecture, and implementation plan before any code is written. Ensure all stakeholders understand what will be built and agree on the approach.

### Scope
- Create and populate all files listed in this plan.
- Define the property schema.
- Define the architecture.
- Define the API contracts.
- Define the security posture.
- Define the testing strategy.
- Establish the milestone plan.

### Explicit Exclusions
- No Xcode project.
- No Swift or TypeScript code.
- No Supabase project.
- No Vercel project.
- No Apple Developer portal changes.
- No dependency installations.
- No Git commits.

### Deliverables
- `CLAUDE.md`
- `README.md`
- `.gitignore`
- `docs/PRODUCT_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`
- `docs/API_CONTRACTS.md`
- `docs/SECURITY_AND_PRIVACY.md`
- `docs/TESTING.md`
- `docs/PROPERTY_SCHEMA.md`
- `docs/MILESTONES.md`

### Acceptance Criteria
- [x] All documentation files are present and fully populated.
- [x] The property schema defines all required fields and their types.
- [x] The architecture clearly separates the main application, keyboard extension, and App Group.
- [x] The security and privacy document covers all major risk areas.
- [x] No application code has been written.
- [x] Nox has reviewed and approved this documentation.

### Testing Requirements
None — no code exists.

### Known Risks
- None — all decisions have been approved and the documentation is complete.

### Required Human Actions (all complete)
1. ✅ Review all documentation files.
2. ✅ Approve decisions: deployment target (iOS 17), bundle IDs, App Group, locale (es-GT), keyboard-cache exclusions.
3. Confirm the Apple Developer account is active and has the App Groups capability available (required before first Xcode build in Milestone 1).

---

## Milestone 1 — Local Sunsets Properties Application

**Status:** Approved and complete (2026-06-27)

### Objective
Build the main SwiftUI application with a fully functional local property catalog using mocked data and in-memory storage. No networking, no backend, no Supabase.

### Scope
- Xcode project with two targets: `SunsetsProperties` and `SunsetsAIKeyboard` (extension stub only).
- App Group entitlement configured in both targets.
- `Property` and `KeyboardProperty` domain models (Codable, Identifiable).
- `PropertyStatus`, `OperationType`, `PetPolicy`, `QuickReplyTemplate` supporting types.
- `MockPropertyRepository` with 5–10 sample properties pre-populated.
- SwiftUI views:
  - Property list with search and status filter.
  - Property detail view (all fields displayed).
  - Property creation form (all required fields).
  - Property editing form.
  - Status change action.
  - Active property selection.
  - Keyboard setup guide screen (static, non-functional links to Settings).
- `CatalogCacheService` that writes `KeyboardProperty[]` to the App Group as JSON.
- Active property ID written to App Group on selection.
- Mocked employees: two hardcoded agents (no authentication).

### Explicit Exclusions
- No keyboard extension UI.
- No Supabase.
- No network calls.
- No authentication.
- No TestFlight.

### Deliverables
- Working Xcode project opening without errors.
- Main app runs on iPhone Simulator and physical device.
- 5–10 sample properties visible in the catalog.
- CRUD operations working for properties.
- App Group cache file written after each save operation.

### Acceptance Criteria
- [ ] The app launches without crashes on iOS 17 Simulator.
- [ ] An administrator can create a new property with all required fields.
- [ ] A property can be edited and the changes persist within the session.
- [ ] A property's status can be changed.
- [ ] Setting a property as active writes its ID to the App Group.
- [ ] `CatalogCacheService` writes a valid `keyboard_catalog.json` to the App Group after each change.
- [ ] The catalog list can be searched by title and filtered by status.
- [ ] All required fields are validated before saving.
- [ ] Missing required fields prevent the property from being added to the cache.
- [ ] The keyboard setup guide screen is reachable from the main menu.

### Testing Requirements
- Unit tests for `Property` serialization.
- Unit tests for `CatalogCacheService` write/read round-trip.
- Unit tests for property validation rules.
- Manual test on physical device: create, edit, save a property; verify the App Group JSON file is written.

### Known Risks
- App Group may not function correctly until the Apple Developer portal configuration is confirmed.
- `Decimal` serialization via `JSONEncoder` requires explicit configuration; must be tested early.

### Required Human Actions
1. Register the App Group `group.com.sunsetsrealestate.sunsetsai` in the Apple Developer portal (if not already done).
2. Register bundle IDs `com.sunsetsrealestate.sunsetsproperties` and `com.sunsetsrealestate.sunsetsproperties.keyboard` in the Apple Developer portal.
3. Configure the Xcode project with the correct Team before first build.
4. Review and approve the Xcode project structure before Milestone 2 begins.

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
- Unit tests for `TemplateEngine` (all system templates, all placeholder tokens).
- Unit tests for property search (title match, location match, empty query, no results).
- Unit tests for `recent_property_ids` FIFO management.
- Unit tests for stale cache detection.
- Manual testing in Notes (Simulator acceptable for initial testing).
- Manual testing in Messenger on physical iPhone.
- Manual testing in WhatsApp on physical iPhone.
- Manual testing in Facebook Marketplace on physical iPhone.

### Known Risks
- iOS keyboard extension memory limit may be tight if the catalog is large. Monitor during this milestone.
- Some messaging apps may prevent custom keyboards from functioning in certain views (e.g., search fields). Document any incompatibilities.

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
Add explicit clipboard import and a local intent classifier that routes customer messages to deterministic template responses. Ambiguous and negotiation intents are flagged for human handling.

### Scope
- **Import from clipboard** button in the keyboard.
- Imported message shown in a dedicated review area.
- `IntentClassifier` service:
  - Classifies messages into known intents (price, availability, location, amenities, requirements, pet policy, visit).
  - Classifies negotiation messages as `negotiation` (human-only).
  - Classifies unknown messages as `unknown`.
- Routing logic: classified intent → deterministic template or human-handling flag.
- Human-handling indicator in the keyboard UI.
- No network call in this milestone.

### Explicit Exclusions
- No AI generation.
- No backend calls.
- No background clipboard monitoring (this is a permanent exclusion, not just for this milestone).

### Deliverables
- Import button imports clipboard content on explicit tap.
- Imported message is visible and editable before classification.
- Known intents trigger the correct template.
- Negotiation and unknown intents show a "Requires human response" indicator.
- Templates still work without an imported message (quick action path).

### Acceptance Criteria
- [ ] Tapping Import reads the current clipboard value once and displays it.
- [ ] No clipboard access occurs without a user tap.
- [ ] A price-inquiry message produces a price template response.
- [ ] An availability-inquiry message produces an availability template response.
- [ ] A negotiation message shows the human-handling indicator and no generated response.
- [ ] An unrecognized message shows the human-handling indicator.
- [ ] Tapping Insert sends only the reviewed response, not the customer message.

### Testing Requirements
- Unit tests for `IntentClassifier` covering all intent categories in Spanish and English.
- Unit tests verifying that negotiation and unknown intents do not produce template responses.
- Manual testing: import clipboard message, verify classification, verify insertion.

### Known Risks
- Intent classification accuracy for Mexican Spanish messaging slang requires careful vocabulary coverage.

### Required Human Actions
1. Review and approve the intent vocabulary list before Milestone 3 begins.
2. Test with real customer message samples (anonymized) to validate classifier accuracy.

---

## Milestone 4 — Secure AI Backend

**Status:** Not started

### Objective
Deploy a TypeScript backend on Vercel that authenticates agents, proxies AI generation via the Anthropic Messages API, and returns structured responses to the keyboard. No API key in the iOS app.

### Scope
- TypeScript backend with Vercel serverless functions.
- Endpoints as defined in `docs/API_CONTRACTS.md`:
  - `POST /generate`
  - `POST /events`
  - `GET /catalog/version`
- JWT token validation on every authenticated endpoint.
- Anthropic Messages API integration.
- Rate limiting (60 requests/user/hour for `/generate`).
- Structured JSON response for AI-generated text.
- Offline fallback in the keyboard (deterministic templates when offline or when the backend is unavailable).
- Error handling for 401, 422, 429, and 5xx responses.

### Explicit Exclusions
- No Supabase (user IDs are still mocked in this milestone).
- No real authentication (tokens are validated structurally but not against Supabase Auth).
- No App Store submission.
- The Anthropic API key is never included in any iOS file.

### Deliverables
- Vercel project deployed and accessible via HTTPS.
- Keyboard sends a generation request and displays the result.
- Rate limiting returns HTTP 429 when exceeded.
- AI generation is disabled when offline; keyboard falls back to templates.

### Acceptance Criteria
- [ ] `POST /generate` returns a valid response for a known property and customer message.
- [ ] The Anthropic API key is confirmed absent from all iOS source files.
- [ ] Offensive or off-topic AI responses are handled gracefully (property context constrains the model).
- [ ] Offline keyboard generates template responses without errors.
- [ ] HTTP 429 response shows a user-friendly rate-limit message in the keyboard.
- [ ] `POST /events` accepts all defined event types without error.

### Testing Requirements
- Unit tests for backend request/response schema validation.
- Integration test for `POST /generate` against a staging Vercel deployment.
- Manual test: generate a response in the keyboard on a physical device.
- Manual test: disconnect from network; confirm AI button is disabled and templates still work.

### Known Risks
- Anthropic API response latency may be higher than acceptable on first request; test p95 latency.
- Prompt design for property context requires iteration; reserve time.

### Required Human Actions
1. Provision a Vercel project and set environment variables (Anthropic key, etc.).
2. Confirm the backend base URL to be stored in the iOS app configuration.
3. Approve the AI system prompt before deploying to production.

---

## Milestone 5 — Supabase and Multi-User Synchronization

**Status:** Not started

### Objective
Replace the mocked property repository with a real Supabase backend. Add agent authentication, role-based access, and catalog synchronization.

### Scope
- Supabase project with PostgreSQL schema matching `PROPERTY_SCHEMA.md`.
- Row Level Security (RLS) policies:
  - Agents can read all properties in their organization.
  - Administrators can write and delete properties.
- Supabase Auth (email + password).
- JWT token stored in iOS Keychain.
- Keyboard reads token from shared Keychain access group.
- `SupabasePropertyRepository` implementation.
- `GET /catalog` and `GET /catalog/version` backend endpoints connected to Supabase.
- Main application syncs catalog on launch and on foreground return.
- App Group cache rebuilt after each successful sync.
- Catalog version token for incremental sync.
- Logout clears Keychain token and App Group cache.

### Explicit Exclusions
- No App Store submission.
- No push notifications.
- No real-time sync (polling only).

### Deliverables
- Two agents (Cristian, Yessy) can log in with separate accounts.
- Property changes made by one agent appear on the other's device after sync.
- RLS prevents agents from reading properties outside their organization.
- Logout on one device does not affect the other.

### Acceptance Criteria
- [ ] Login screen authenticates against Supabase Auth.
- [ ] Invalid credentials return a clear error message.
- [ ] Property catalog syncs from Supabase on app launch.
- [ ] A property created in Supabase appears in the keyboard after the next sync.
- [ ] A property deleted from Supabase is removed from the cache after the next sync.
- [ ] Logout clears the Keychain token and the App Group cache.
- [ ] The keyboard reads the Keychain token for backend API calls.

### Testing Requirements
- Unit tests for `SupabasePropertyRepository` (with a mock Supabase client).
- Integration tests against a Supabase staging project.
- Manual test: create a property on one device, sync, verify on the second device.
- Manual test: logout and confirm cache is cleared.

### Known Risks
- Supabase RLS policy errors can be silent; test access control explicitly.
- Shared Keychain access group configuration is error-prone; test on physical devices only.

### Required Human Actions
1. Create the Supabase project.
2. Apply the database schema.
3. Configure RLS policies.
4. Create agent accounts for Cristian and Yessy.
5. Provide Supabase project URL and anon key for iOS configuration.
6. Review and approve the RLS policies before enabling.

---

## Milestone 6 — TestFlight Deployment

**Status:** Not started

### Objective
Deploy the application to TestFlight for internal testing on Cristian's and Yessy's iPhones. Validate the complete flow on physical devices in real-world conditions.

### Scope
- App Store Connect app record.
- Privacy policy and App Store description.
- TestFlight internal distribution.
- Physical-device validation checklist.
- Privacy review of all data collection practices.
- Fix any issues discovered during physical-device testing.

### Explicit Exclusions
- No public App Store release.
- No external TestFlight testers.

### Deliverables
- App available in TestFlight for Cristian and Yessy.
- Both testers confirm the keyboard works in Messenger, WhatsApp, and Facebook Marketplace.
- Privacy policy is live at a public URL.

### Acceptance Criteria
- [ ] The app passes App Store Connect validation (no binary rejections).
- [ ] TestFlight build installs on both test iPhones.
- [ ] Keyboard enables and grants Full Access successfully on both devices.
- [ ] Property catalog syncs from Supabase on both devices.
- [ ] Quick action insertion works in Messenger, WhatsApp, and Facebook Marketplace on both devices.
- [ ] AI generation works on both devices with network connectivity.
- [ ] No crash reports in the first 48 hours of testing.
- [ ] The privacy policy URL is live and accurately describes data practices.

### Testing Requirements
- Complete manual testing checklist from `docs/TESTING.md` on both physical devices.
- AI generation latency measured and within acceptable range.
- Memory usage confirmed below keyboard extension limit.

### Known Risks
- Apple review of keyboard extensions may require additional privacy justification.
- Full Access prompt may concern users without a clear explanation.

### Required Human Actions
1. Create the App Store Connect record.
2. Write and publish the privacy policy.
3. Submit the TestFlight build and confirm it passes processing.
4. Install and test on both iPhones.
5. Report any issues for remediation before broader distribution.
