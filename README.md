# Sunsets AI

An iOS property-management assistant consisting of two tightly integrated components:

1. **Sunsets Properties** — SwiftUI main application. The authoritative catalog of rental and sale properties managed by Sunsets Real Estate employees.
2. **SunsetsAIKeyboard** — Custom Keyboard Extension. Allows agents to generate verified, property-specific replies inside Messenger, WhatsApp, Facebook Marketplace, and other messaging applications without leaving the conversation.

---

## What This Is

Real estate agents spend significant time composing repetitive messages: confirming prices, describing amenities, sharing visit instructions, and responding to availability inquiries. SunsetsAIKeyboard reduces that friction by:

- Keeping a locally cached, keyboard-safe property catalog available inside any messaging app.
- Allowing agents to select the relevant property and generate deterministic or AI-assisted responses.
- Requiring agents to review and manually send every message — nothing is transmitted automatically.

---

## Repository Structure

```
SunsetsAIKeyboard/
├── CLAUDE.md                    # Engineering rules for Claude sessions
├── README.md                    # This file
├── .gitignore
└── docs/
    ├── PRODUCT_SPEC.md          # Full product requirements and acceptance criteria
    ├── ARCHITECTURE.md          # System architecture and component boundaries
    ├── DECISIONS.md             # Architecture Decision Records
    ├── PROJECT_STATUS.md        # Current milestone, completed work, next task
    ├── API_CONTRACTS.md         # Future backend API schemas
    ├── SECURITY_AND_PRIVACY.md  # Security posture and privacy rules
    ├── TESTING.md               # Test strategy and manual testing requirements
    ├── PROPERTY_SCHEMA.md       # Canonical property data model
    └── MILESTONES.md            # Phased implementation plan
```

Application source code will be added in Milestone 1.

---

## Key Constraints

- The keyboard **never sends messages automatically**. All insertion is manual.
- The keyboard **never reads the clipboard in the background**. Customer messages must be explicitly imported by the user.
- **No API keys** are embedded in the iOS application. All AI calls go through the backend.
- The keyboard uses **only the selected property's verified data** to generate responses.
- The keyboard does not detect which conversation the user is in.

---

## App Group

Both targets share data through:

```
group.com.sunsetsrealestate.sunsetsai
```

Main application bundle ID: `com.sunsetsrealestate.sunsetsproperties`
Keyboard extension bundle ID: `com.sunsetsrealestate.sunsetsproperties.keyboard`

---

## Development Phases

See `docs/MILESTONES.md` for the full plan. No application code exists yet.

**Current phase:** Milestone 1 — Local Sunsets Properties application.

---

## Requirements

- Xcode 15 or later
- iOS 17 minimum deployment target (confirmed)
- iPhone only — iPad is explicitly out of scope for the MVP
- Apple Developer account with App Groups entitlement
- Physical iPhone for keyboard extension testing

---

## Privacy

This product processes company property data and excerpts of customer messages. No complete conversation history is stored. See `docs/SECURITY_AND_PRIVACY.md` for the full privacy posture.
