# Project Status — Sunsets AI

**Last updated:** 2026-06-27
**Current milestone:** Milestone 2 — Local SunsetsAIKeyboard Extension (not started)

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

## Pending Work

### Milestone 2 — Local SunsetsAIKeyboard Extension (Not started)

Awaiting implementation start. Scope defined in `docs/MILESTONES.md`.

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

> **Implement Milestone 2 — Local SunsetsAIKeyboard and shared keyboard-safe property catalog.**
