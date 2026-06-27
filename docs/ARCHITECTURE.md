# Architecture — Sunsets AI Keyboard

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27
**Status:** Approved

---

## 1. System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    Apple Developer Account                    │
│  Main app: com.sunsetsrealestate.sunsetsproperties            │
│  Keyboard: com.sunsetsrealestate.sunsetsproperties.keyboard   │
│                                                              │
│  ┌────────────────────────┐  ┌────────────────────────────┐ │
│  │   Sunsets Properties   │  │    SunsetsAIKeyboard       │ │
│  │   (Main Application)   │  │    (Keyboard Extension)    │ │
│  │   SwiftUI              │  │    UIKit / UIInputVC       │ │
│  └────────────┬───────────┘  └──────────────┬─────────────┘ │
│               │                             │               │
│               └──────────┬──────────────────┘               │
│                          │                                   │
│              ┌───────────▼────────────┐                     │
│              │  App Group             │                     │
│              │  group.com.sunsets     │                     │
│              │  realestate.sunsetsai  │                     │
│              │                        │                     │
│              │  • keyboard_catalog.json                     │
│              │  • active_property_id                        │
│              │  • catalog_version                           │
│              │  • recent_property_ids                       │
│              └────────────────────────┘                     │
└──────────────────────────────────────────────────────────────┘

External (Future)
┌─────────────────────┐     ┌──────────────────────────┐
│  Supabase           │────▶│  Vercel Backend           │
│  (Remote catalog)   │     │  (TypeScript)             │
│  PostgreSQL + RLS   │     │  • Auth                   │
└─────────────────────┘     │  • Property sync          │
                            │  • AI generation proxy    │
                            │  • Rate limiting          │
                            └──────────────────────────┘
```

---

## 2. Component Boundaries

### 2.1 Sunsets Properties (Main Application)

**Responsibility:** Source of truth for the property catalog. All writes originate here.

**Technology:** SwiftUI, Swift Concurrency (async/await)

**What it owns:**
- Full `Property` model (all fields including sensitive ones)
- CRUD operations on the property catalog
- Synchronization with Supabase (future)
- Building and writing the keyboard-safe cache to the App Group
- Active property selection
- Agent authentication state (future)

**What it does not own:**
- The keyboard UI
- Sending messages
- AI generation (delegates to backend via keyboard extension)

---

### 2.2 SunsetsAIKeyboard (Keyboard Extension)

**Responsibility:** Read-only consumer of the App Group cache. Generates and inserts text.

**Technology:** UIKit, `UIInputViewController`, Swift Concurrency

**What it owns:**
- Keyboard UI (property bar, search, quick actions, preview, insert)
- Reading the keyboard-safe cache from the App Group
- Writing the active property ID back to the App Group
- Maintaining the recently-used list (App Group)
- Explicit clipboard import (user-initiated only)
- Local intent classification
- Deterministic template rendering
- Backend AI generation requests (future)
- `textDocumentProxy.insertText()` calls

**What it does not own:**
- Writing to the canonical property catalog
- Authentication (beyond passing a stored token)
- Supabase queries

**Memory constraint:** iOS keyboard extensions have a soft memory limit of approximately 50 MB. The keyboard-safe cache must be sized accordingly. Images are excluded from the cache.

---

### 2.3 App Group Shared Container

**Identifier:** `group.com.sunsetsrealestate.sunsetsai`

**Written by:** Sunsets Properties (catalog, version token); SunsetsAIKeyboard (active property ID, recent list)

**Read by:** Both targets

**Contents:**

| Key | Type | Writer | Description |
|-----|------|--------|-------------|
| `keyboard_catalog.json` | JSON file | Main app | Array of `KeyboardProperty` objects |
| `active_property_id` | UserDefaults String | Both | ID of the currently selected property |
| `catalog_version` | UserDefaults String | Main app | Opaque version token for incremental sync |
| `catalog_updated_at` | UserDefaults Double | Main app | Unix timestamp of last cache write |
| `recent_property_ids` | UserDefaults [String] | Keyboard | Up to 5 recently selected property IDs |

---

## 3. Domain Models

### 3.1 Property (Full — Main App Only)

The full property model is defined in `docs/PROPERTY_SCHEMA.md`. It lives exclusively inside the main application's data layer. It is never written directly to the App Group.

### 3.2 KeyboardProperty (Keyboard-Safe Cache)

A projection of the full property containing only the fields needed by the keyboard. See `docs/PROPERTY_SCHEMA.md` Section 4 for the exact field list.

Excluded from the keyboard cache (approved, ADR-008):
- `fullAddress` — use `locationSummary` instead
- `assignedAgentId` — not needed for reply generation
- `latitude` / `longitude`
- Internal notes, owner information, commissions, private contact details, access codes, and any other sensitive operational data

### 3.3 ActivePropertySelection

Stored as a single String value in the App Group UserDefaults under the key `active_property_id`. The keyboard resolves the full `KeyboardProperty` by scanning the cached catalog.

---

## 4. Proposed Layer Structure

```
SunsetsAI/
├── Shared/                          # Code shared between both targets
│   ├── Models/
│   │   ├── Property.swift           # Full model (main app only target)
│   │   ├── KeyboardProperty.swift   # Keyboard-safe model (both targets)
│   │   └── PropertyStatus.swift
│   ├── AppGroup/
│   │   ├── AppGroupKeys.swift       # Constant key strings
│   │   └── AppGroupStore.swift      # Read/write helpers
│   └── Extensions/
│
├── SunsetsProperties/               # Main application target
│   ├── App/
│   │   └── SunsetsPropertiesApp.swift
│   ├── Features/
│   │   ├── Catalog/
│   │   │   ├── CatalogViewModel.swift
│   │   │   └── CatalogView.swift
│   │   ├── PropertyDetail/
│   │   ├── PropertyEditor/
│   │   └── Setup/                   # Keyboard setup guide
│   ├── Repositories/
│   │   ├── PropertyRepository.swift (protocol)
│   │   ├── MockPropertyRepository.swift  (Milestone 1)
│   │   └── SupabasePropertyRepository.swift (Milestone 5)
│   ├── Services/
│   │   └── CatalogCacheService.swift  # Writes keyboard cache to App Group
│   └── Resources/
│
└── SunsetsAIKeyboard/               # Keyboard extension target
    ├── KeyboardViewController.swift  # UIInputViewController root
    ├── Features/
    │   ├── PropertySelector/
    │   ├── QuickActions/
    │   ├── MessageImport/
    │   ├── ResponsePreview/
    │   └── AIGeneration/
    ├── Services/
    │   ├── CatalogReader.swift       # Reads App Group cache
    │   ├── TemplateEngine.swift      # Deterministic template rendering
    │   ├── IntentClassifier.swift    # Local intent classification
    │   └── AIService.swift           # Backend proxy client (future)
    └── Resources/
```

---

## 5. Data Flow

### 5.1 Main App → App Group → Keyboard

```
Admin edits property in Sunsets Properties
         │
         ▼
CatalogCacheService serializes KeyboardProperty array
         │
         ▼
Writes keyboard_catalog.json to App Group container
Writes catalog_updated_at timestamp
         │
         ▼
SunsetsAIKeyboard reads file on next launch or refresh
         │
         ▼
CatalogReader deserializes into [KeyboardProperty]
         │
         ▼
Keyboard UI renders property list
```

### 5.2 Agent Selects Property in Keyboard

```
Agent taps property in keyboard
         │
         ▼
AppGroupStore writes active_property_id
AppGroupStore prepends to recent_property_ids
         │
         ▼
Keyboard UI updates active property bar immediately
```

### 5.3 AI Generation (Future — Milestone 4)

```
Agent imports customer message (explicit clipboard paste)
Agent taps "Generate with AI"
         │
         ▼
AIService sends HTTPS POST to Vercel backend:
  { userId, property: KeyboardProperty, customerMessage, style }
         │
         ▼
Backend validates auth token
Backend calls Anthropic Messages API with property context
Backend returns structured JSON response
         │
         ▼
Keyboard displays response in preview area
Agent reviews, taps Insert
         │
         ▼
textDocumentProxy.insertText(response)
Agent sends manually in host app
```

---

## 6. Repository Pattern (Dependency Injection)

The main application uses a `PropertyRepository` protocol so the concrete implementation can be swapped:

```swift
protocol PropertyRepository {
    func fetchAll() async throws -> [Property]
    func save(_ property: Property) async throws
    func delete(id: String) async throws
    func setActive(id: String) async throws
}
```

- **Milestone 1:** `MockPropertyRepository` — in-memory, no persistence
- **Milestone 2–4:** `LocalPropertyRepository` — persists to device (UserDefaults or file)
- **Milestone 5:** `SupabasePropertyRepository` — syncs with remote

---

## 7. Authentication (Future — Milestone 5)

- JWT-based authentication via Supabase Auth.
- The main application stores the auth token in the iOS Keychain.
- The keyboard reads the token from the shared App Group Keychain access group (requires configuration).
- The backend validates the token on every AI generation request.
- Row Level Security in Supabase restricts property access by organization.

---

## 8. Backend (Future — Milestone 4)

- **Runtime:** Node.js, TypeScript
- **Deployment:** Vercel serverless functions
- **Endpoints:** See `docs/API_CONTRACTS.md`
- **AI model:** Anthropic Claude via the Messages API
- **Rate limiting:** Per-user, per-hour request caps
- **Secret management:** Environment variables in Vercel (never in iOS code)

---

## 9. Offline Strategy

| Layer | Offline behavior |
|-------|-----------------|
| Main app | Full CRUD on local data; sync deferred until online |
| App Group cache | Always available; not cleared on network loss |
| Keyboard templates | Fully offline — no network needed |
| Keyboard AI generation | Disabled; user sees offline indicator |
| Supabase sync | Queued and retried when connectivity returns (future) |

---

## 10. Deployment Target

- iOS 17 minimum (confirmed — ADR-008).
- iPhone only — iPad is explicitly out of scope for the MVP.
- No macOS Catalyst.
- Primary interface language: Spanish for Guatemala (`es-GT`), neutral professional register.

---

## 11. Key Non-Goals

- The keyboard does not detect which application is in the foreground.
- The keyboard does not read conversation history from the host app.
- The keyboard does not automatically send any message.
- The main application does not expose a public API.
- No web or Android version in any milestone.
