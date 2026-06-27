# Architecture Decision Records — Sunsets AI

**Last updated:** 2026-06-27

Decisions are recorded here in reverse-chronological order (newest first). Each record follows the ADR format: Context → Decision → Alternatives → Consequences → Status.

---

## ADR-008 — Project identifiers, deployment target, locale, and keyboard-cache privacy

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

The authenticated employee identity is managed separately from property records and must not be stored inside property entries in the App Group cache.

**Privacy policy:** A public privacy policy URL is not required for the local Milestone 1 prototype. It must be created and approved before external TestFlight testing or public distribution. This is a blocker for Milestone 6, not Milestone 1.

### Alternatives Considered
- **iOS 16 minimum:** Wider device support, but excludes several SwiftUI APIs used extensively in iOS 17. The target devices (Cristian's and Yessy's iPhones) run iOS 17+, so the compromise offers no practical benefit. Rejected.
- **`com.sunsetsrealestate.sunsetsai` as main bundle ID:** Cleaner but less descriptive; the app product name is *Sunsets Properties*, not *Sunsets AI*. Rejected in favor of a more descriptive identifier.
- **Including `assignedAgentId` in keyboard cache:** No template or AI generation feature requires the agent assignment. Including it unnecessarily widens the data surface in the shared container. Rejected.

### Consequences
- Bundle IDs are locked; changing them after Xcode project creation requires provisioning profile updates.
- The App Group identifier must be registered in the Apple Developer portal before any Xcode build that depends on it.
- All templates default to Spanish (`es-GT`); English strings are not required in the MVP.
- The keyboard-cache exclusion list is now an explicit part of the schema (documented in `PROPERTY_SCHEMA.md`).
- Privacy policy creation is deferred to Milestone 6 and must not block Milestone 1.

---

## ADR-007 — Deterministic templates before AI generation

**Date:** 2026-06-26
**Status:** Accepted

### Context
AI generation via an external API introduces latency, cost, network dependency, and the risk of hallucinated property facts. Many customer messages ask predictable questions that can be answered from verified data alone.

### Decision
For any customer intent that maps to a known property field (price, location, amenities, availability, requirements, pet policy, visit instructions), the keyboard renders a deterministic template from the cached `KeyboardProperty` data without calling any API.

AI generation is used only when:
- The customer's intent is ambiguous.
- Multiple facts need to be combined with natural language.
- The agent explicitly requests a different tone.

### Alternatives Considered
- **AI-first:** Always call the AI, even for simple fact questions. Rejected: slower, more expensive, risks hallucination of verified data, fails offline.
- **Templates only, no AI:** Never call the AI. Rejected: insufficient for ambiguous or multi-fact messages.

### Consequences
- Faster responses for the most common cases.
- Offline capability for the majority of keyboard use.
- Lower per-agent API cost.
- Requires maintaining a template library.
- Template rendering must be tested separately from AI generation.

---

## ADR-006 — No automatic message sending

**Date:** 2026-06-26
**Status:** Accepted

### Context
iOS custom keyboard extensions can insert text into any text field. It is technically possible to insert text without user review. Automatically sending a message to a customer without the agent's explicit review would be a serious UX and trust failure.

### Decision
The keyboard inserts text into the host application's input field via `textDocumentProxy.insertText()`. The agent must then manually tap Send (or equivalent) in the host application. The keyboard never triggers a send action.

### Alternatives Considered
- **Auto-send:** Insert and simulate a Return key press. Rejected: no review step, could send incorrect or hallucinated content.

### Consequences
- Agents retain full control over every message.
- The extra step (tap Insert, tap Send) is an acceptable UX trade-off for safety and accuracy.

---

## ADR-005 — Explicit clipboard import only (no background monitoring)

**Date:** 2026-06-26
**Status:** Accepted

### Context
To generate a reply, the keyboard needs the customer's message. One approach is to automatically read the clipboard. Another is to require the user to explicitly import it.

### Decision
The keyboard never reads the clipboard automatically or in the background. The user must tap an explicit **Import from clipboard** button. The imported message is shown for review and is used only for the current generation request; it is not stored persistently.

### Alternatives Considered
- **Automatic clipboard monitoring:** Read the pasteboard on keyboard open or on a timer. Rejected: violates Apple's guidelines, degrades user trust, reads data the user did not intend to share.
- **Accessibility API to read conversation:** Use UIAccessibility to extract the visible conversation. Rejected: violates App Store guidelines, fragile, not sanctioned by iOS.

### Consequences
- Users must take a deliberate action to import a customer message.
- Slightly more friction for AI generation, acceptable given the privacy benefit.
- No risk of inadvertently reading unrelated clipboard content.

---

## ADR-004 — Backend-only Anthropic API access

**Date:** 2026-06-26
**Status:** Accepted

### Context
API keys embedded in an iOS application binary can be extracted by anyone who installs the app. The Anthropic API key must never appear in iOS application code.

### Decision
All calls to the Anthropic Messages API are made from the Vercel backend (TypeScript). The iOS keyboard sends a request to the backend's `/generate` endpoint, which authenticates the user, calls Anthropic, and returns a structured response. The iOS application never holds an Anthropic API key.

### Alternatives Considered
- **Embed key in iOS:** Simple to implement. Rejected: key extraction risk is unacceptable.
- **Obfuscate key in iOS binary:** Not meaningfully secure. Rejected.
- **User supplies their own key:** Poor UX, not a business product. Rejected.

### Consequences
- AI generation requires network connectivity.
- Backend adds an extra hop of latency (expected < 1 s for typical responses).
- Centralizes rate limiting and cost control at the backend.
- Backend becomes a single point of failure; offline fallback (deterministic templates) is essential.

---

## ADR-003 — App Groups for shared catalog data

**Date:** 2026-06-26
**Status:** Accepted

### Context
The main application and the keyboard extension are separate iOS processes. They cannot share memory directly. iOS provides App Groups as the sanctioned mechanism for inter-process data sharing between a container app and its extensions.

### Decision
Both the main application and keyboard extension are members of the App Group `group.com.sunsetsrealestate.sunsetsai`. The shared container is used to store:
- The keyboard-safe property catalog (`keyboard_catalog.json`)
- The active property ID
- The catalog version token
- The recently-used property list

### Alternatives Considered
- **Local network socket between processes:** Not supported between app and extension on iOS. Rejected.
- **Custom URL scheme:** Could notify the keyboard to refresh, but cannot transfer large data. Rejected as primary mechanism.
- **CloudKit:** Requires network, adds latency. Rejected for this role; may be considered for backup sync later.

### Consequences
- Both targets must include the App Groups entitlement.
- Bundle IDs must share the prefix `com.sunsetsrealestate.sunsetsproperties` to use the same App Group (`com.sunsetsrealestate.sunsetsproperties` and `com.sunsetsrealestate.sunsetsproperties.keyboard`).
- The App Group must be provisioned in the Apple Developer portal before building either target.
- Writes from the main app are visible to the keyboard on its next read (no live push).

---

## ADR-002 — UIKit for the keyboard extension

**Date:** 2026-06-26
**Status:** Accepted

### Context
iOS custom keyboard extensions must subclass `UIInputViewController`, which is a UIKit class. SwiftUI views can be hosted inside UIKit via `UIHostingController`, but the root controller must be UIKit.

### Decision
The keyboard extension's root is `UIInputViewController` (UIKit). Individual panels (property list, quick actions, preview) may be implemented as SwiftUI views embedded via `UIHostingController`.

### Alternatives Considered
- **Pure SwiftUI keyboard:** Not supported by iOS; `UIInputViewController` is mandatory. Not applicable.
- **Pure UIKit keyboard:** Possible but verbose. Rejected in favor of SwiftUI sub-views for rapid iteration.

### Consequences
- The keyboard target has a UIKit dependency even if most UI is SwiftUI.
- Memory management requires attention when hosting SwiftUI inside UIKit in an extension.
- Testing UIKit view controllers requires XCTest; SwiftUI sub-views can use SwiftUI previews.

---

## ADR-001 — SwiftUI for the main application

**Date:** 2026-06-26
**Status:** Accepted

### Context
The main application is a standard iOS container app with no special system integration requirements that would mandate UIKit. The team has a preference for modern tooling.

### Decision
The main application (`SunsetsProperties`) is built entirely in SwiftUI with Swift Concurrency (async/await).

### Alternatives Considered
- **UIKit:** Mature, stable, but verbose and slower to build catalog management screens. Rejected.
- **SwiftUI + UIKit hybrid:** Only if a specific screen requires UIKit. May be used for onboarding or edge cases.

### Consequences
- Minimum deployment target is iOS 17 (confirmed — ADR-008). Modern SwiftUI APIs are fully available.
- SwiftUI previews enable rapid iteration on catalog views.
- Some UIKit interop may be needed for certain system screens.

---

## ADR-000 — One iOS application with an embedded keyboard extension

**Date:** 2026-06-26
**Status:** Accepted

### Context
The product could be structured as a standalone keyboard with no companion app, as a companion app with a keyboard, or as separate apps. iOS policy requires keyboard extensions to be embedded inside a container application.

### Decision
The product is a single Xcode project containing two targets:
1. `SunsetsProperties` — the container application (main app).
2. `SunsetsAIKeyboard` — the keyboard extension embedded inside the container.

### Alternatives Considered
- **Keyboard extension alone, no main app:** Not allowed by iOS — extensions require a container app.
- **Two separate apps:** Not possible — extensions must be embedded in their host app's bundle.
- **Main app + separate keyboard app:** Not applicable to iOS keyboard extensions.

### Consequences
- Both targets are distributed as a single App Store submission.
- The main application serves as the setup entry point (keyboard enable guide, catalog management).
- Shared code lives in a `Shared` directory or Swift Package that both targets depend on.
- Both targets must be signed with the same team and included in the same App Group.
