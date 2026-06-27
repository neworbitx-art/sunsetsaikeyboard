# Project Status — Sunsets AI

**Last updated:** 2026-06-27
**Current milestone:** Milestone 1 — Local Sunsets Properties Application

---

## Current Phase

Milestone 0 is **approved and complete**. All documentation has been created, reviewed, and approved by Nox. All pending decisions have been resolved (see ADR-008 in `docs/DECISIONS.md`).

Milestone 1 is ready to begin. No unresolved blockers remain for the Xcode project creation.

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

---

## Pending Work

### Milestone 1 — Local Sunsets Properties Application

All Milestone 1 work is pending. See `docs/MILESTONES.md` for full scope. Summary:

- Create Xcode project with two targets: `SunsetsProperties` and `SunsetsAIKeyboard` stub.
- Configure App Group entitlement in both targets.
- Implement `Property` and `KeyboardProperty` domain models.
- Implement `MockPropertyRepository` with 5–10 sample properties.
- Build SwiftUI catalog views (list, detail, create, edit, status change, active selection).
- Implement `CatalogCacheService` to write keyboard-safe JSON to the App Group.
- Build keyboard setup guide screen.

---

## Known Blockers

1. **Apple Developer portal** — The following must be registered before the first Xcode build:
   - App Group: `group.com.sunsetsrealestate.sunsetsai`
   - Bundle ID (main app): `com.sunsetsrealestate.sunsetsproperties`
   - Bundle ID (keyboard): `com.sunsetsrealestate.sunsetsproperties.keyboard`
   - These are proposed identifiers; they become confirmed when registered.

No other blockers. All documentation decisions are resolved.

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

> **Create the local Xcode project and begin Milestone 1 — Local Sunsets Properties application.**

Before writing code, confirm the Apple Developer portal actions listed in the Known Blockers section above are complete or in progress.
