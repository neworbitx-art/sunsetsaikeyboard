# Project Status — Sunsets AI

**Last updated:** 2026-06-27
**Current milestone:** Milestone 2 — Local SunsetsAIKeyboard Extension

---

## Current Phase

Milestone 1 is **approved and complete**. The local Sunsets Properties SwiftUI application was manually validated by Nox on 2026-06-27. All acceptance criteria confirmed on iPhone Simulator.

Milestone 2 is ready to begin after the SunsetsAIKeyboard extension target is created and validated.

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

---

## Pending Work

### Milestone 2 — Local SunsetsAIKeyboard Extension

All Milestone 2 work is pending. See `docs/MILESTONES.md` for full scope.

**Waiting for:** SunsetsAIKeyboard extension target creation and validation before beginning feature implementation.

---

## Known Blockers

1. **Apple Developer portal** — The following must be registered before the first Xcode build on a real device:
   - App Group: `group.com.sunsetsrealestate.sunsetsai`
   - Bundle ID (main app): `com.sunsetsrealestate.sunsetsproperties`
   - Bundle ID (keyboard): `com.sunsetsrealestate.sunsetsproperties.keyboard`

2. **Test target deployment targets** — `SunsetsPropertiesTests` and `SunsetsPropertiesUITests` targets have `IPHONEOS_DEPLOYMENT_TARGET = 26.5` (inheriting from project level). Correction recommended: set to iOS 17.0 in Xcode to match the main target. Non-blocking for Simulator work on macOS 26.

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

---

## Confirmed Assumptions

1. Primary language is Spanish for Guatemala (`es-GT`) — neutral, professional register.
2. Target messaging apps: Messenger, WhatsApp, Facebook Marketplace.
3. iPhone only. iPad out of scope for the MVP.
4. Supabase project will be created fresh (no migration from an existing database).
5. One organization: Sunsets Real Estate. Multi-tenant is out of scope.
6. Anthropic Messages API is used for AI generation.
7. Agents may be bilingual; customer messages are expected primarily in Spanish (Guatemala).

---

## Next Exact Task

> **Create and validate the SunsetsAIKeyboard Custom Keyboard Extension target before implementing Milestone 2.**
