# Architecture — Sunsets AI Keyboard

**Version:** 0.4 (Milestone 1.1 refinement — pet policy, sale financing, FHA)
**Last updated:** 2026-06-27
**Status:** Pending approval

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
│  │   SwiftUI + MapKit     │  │    UIKit / UIInputVC       │ │
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
┌─────────────────────┐     ┌──────────────────────────────────┐
│  Supabase           │────▶│  Vercel Backend                  │
│  (Remote catalog)   │     │  (TypeScript)                    │
│  PostgreSQL + RLS   │     │  • Auth                          │
└─────────────────────┘     │  • Property sync                 │
                            │  • AI generation proxy           │
                            │  • Listing import (Claude)       │
                            │  • Rate limiting                 │
                            └──────────────────────────────────┘
```

---

## 2. Component Boundaries

### 2.1 Sunsets Properties (Main Application)

**Responsibility:** Source of truth for the property catalog. All writes originate here.

**Technology:** SwiftUI, Swift Concurrency (async/await), MapKit

**What it owns:**
- Full `Property` model (all fields including sensitive location data)
- CRUD operations on the property catalog
- Internal code generation (`InternalCodeGenerator`)
- Location selection (map picker, address search, Google Maps URL import)
- Listing text import and draft review (`ListingImportService`, `LocalListingParser`)
- Synchronization with Supabase (future)
- Building and writing the keyboard-safe cache to the App Group (`CatalogCacheService`)
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
- Maintaining the recently-used list
- Explicit clipboard import (user-initiated only)
- Local intent classification
- Deterministic template rendering (including `{{googleMapsURL}}` and `{{publicLocation}}`)
- Backend AI generation requests (future)
- `textDocumentProxy.insertText()` calls

**What it does not own:**
- Writing to the canonical property catalog
- Authentication
- Supabase queries
- Location services
- Listing import

**Memory constraint:** ~50 MB soft cap. No image data in the cache.

---

### 2.3 App Group Shared Container

**Identifier:** `group.com.sunsetsrealestate.sunsetsai`

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

The full property model is defined in `docs/PROPERTY_SCHEMA.md` Section 5. It lives exclusively inside the main application's data layer.

**Milestone 1.1 additions:**
- `publicLocationLabel: String?`
- `formattedAddress: String?`
- `googleMapsURL: String?`
- `locationSource: LocationSource`
- `isExactLocationShareable: Bool`
- `includedItems: [String]`
- `excludedItems: [String]`

**Milestone 1.1 refinement additions (pet policy + financing):**
- `sellerFinancingStatus: SellerFinancingStatus` — default `.unknown` (sale only)
- `bankFinancingAssistanceAvailable: Bool` — default `false`
- `fhaEligibility: FHAEligibility` — default `.unknown`; never inferred by parser
- `financingNotes: String?` — optional free-text

`PetPolicy` reduced from 4 cases to 3: `allowedWithDeposit` and `caseByCase` removed; `subjectToCaseAnalysis` added. Migration decoder maps legacy values to `.subjectToCaseAnalysis`.

`latitude` and `longitude` existed in the schema since v0.2; they now have a defined UI path for setting them via map picker, address search, or URL import.

### 3.2 KeyboardProperty (Keyboard-Safe Cache)

A projection of the full property. See `docs/PROPERTY_SCHEMA.md` Section 6 for the exact field list.

**Milestone 1.1 additions to `KeyboardProperty`:**
- `publicLocationLabel: String?`
- `googleMapsURL: String?`
- `isExactLocationShareable: Bool`
- `latitude: Double?` — projected only when `isExactLocationShareable == true`
- `longitude: Double?` — projected only when `isExactLocationShareable == true`
- `includedItems: [String]`
- `excludedItems: [String]`

### 3.3 PropertyDraft (Listing Import — Milestone 1.1)

A transient, unconfirmed data structure. It is never written to the App Group. It is discarded or converted to a `Property` after user review.

```swift
struct PropertyDraft {
    var id: String                             // Temporary session ID
    var sourceDescription: String              // Original pasted text
    var parserVersion: String
    var title: DraftField<String>
    var operationType: DraftField<OperationType>
    // ... (all detectable fields as DraftField<T>)
    var contactInfo: DraftField<String>        // Reference only; never saved to Property
}

struct DraftField<T: Codable>: Codable {
    var value: T?
    var confidence: DraftConfidence
    var warning: String?
}

enum DraftConfidence: String, Codable {
    case high, medium, low, missing
}
```

---

## 4. New Services (Milestone 1.1)

### 4.1 InternalCodeGenerator

```swift
protocol InternalCodeGenerator {
    func nextCode(existingCodes: [String]) -> String
    func isUnique(_ code: String, existingCodes: [String]) -> Bool
}
```

Implementation: scans all `SUN-###` codes, extracts numeric suffixes, finds the maximum, returns `SUN-{max+1}` zero-padded to at least 3 digits.

### 4.2 LocationImportService

```swift
protocol LocationImportService {
    func parseGoogleMapsURL(_ url: String) -> LocationImportResult?
    func searchAddress(_ query: String) async throws -> [MKMapItem]
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String?
}

struct LocationImportResult {
    var latitude: Double
    var longitude: Double
    var extractedURL: String    // Normalized URL to store
}
```

Extracts coordinates from both `maps.app.goo.gl/…` short links (resolved via HTTP) and `google.com/maps?q=lat,lon` direct links.

### 4.3 FinancingTextService (new — Milestone 1.1 refinement)

Generates fixed, deterministic Spanish text for sale-property financing when shown in `PropertyDetailView` or composing keyboard replies.

```swift
enum FinancingTextService {
    static func text(for property: Property) -> String?
    // Returns nil for non-sale properties or when sellerFinancingStatus != .unavailable.
    // Appends FHA paragraph only when fhaEligibility == .eligible.

    static func fhaWarning(for property: Property) -> String?
    // Returns "Elegibilidad FHA no confirmada." when fhaEligibility == .unknown and
    // sellerFinancingStatus == .unavailable for a sale property.
}
```

### 4.4 ListingImportService

```swift
protocol ListingImportService {
    func parse(_ description: String) async throws -> PropertyDraft
}
```

**LocalListingParser** — deterministic, offline, no network:
- Uses regex and keyword matching to detect price, currency, bedrooms, bathrooms, amenities, etc.
- Returns `DraftField<T>` with appropriate `DraftConfidence` for each field.

**ClaudeListingParser** — AI-assisted, backend-only (Milestone 4):
- Conforms to `ListingImportService`.
- Calls `POST /import/listing` on the Vercel backend.
- Never calls Anthropic directly from the iOS app.
- Always returns a draft for human review; never saves automatically.

### 4.4 CatalogCacheService (updated)

Updated to project new fields into `KeyboardProperty`:
- Includes `latitude`/`longitude` only when `isExactLocationShareable == true`.
- Includes `publicLocationLabel`, `googleMapsURL`, `isExactLocationShareable`.
- Includes `includedItems`, `excludedItems`.
- Excludes `formattedAddress`, `fullAddress`, `locationSource`.

---

## 5. Proposed Layer Structure (updated)

```
SunsetsAI/
├── SunsetsProperties/               # Main application target
│   ├── App/
│   │   └── SunsetsPropertiesApp.swift
│   ├── Models/
│   │   ├── Property.swift
│   │   ├── PropertyStatus.swift
│   │   ├── OperationType.swift
│   │   ├── PetPolicy.swift             # 3 cases (updated M1.1 refinement)
│   │   ├── SellerFinancingStatus.swift  # NEW (M1.1 refinement)
│   │   ├── FHAEligibility.swift        # NEW (M1.1 refinement)
│   │   ├── QuickReplyTemplate.swift
│   │   ├── LocationSource.swift        # NEW (Milestone 1.1)
│   │   └── PropertyDraft.swift         # NEW (Milestone 1.1; updated M1.1 refinement)
│   ├── Repositories/
│   │   ├── PropertyRepository.swift    # Protocol
│   │   ├── LocalPropertyRepository.swift
│   │   └── SupabasePropertyRepository.swift  # Milestone 5
│   ├── Services/
│   │   ├── CatalogCacheService.swift
│   │   ├── InternalCodeGenerator.swift  # NEW (Milestone 1.1)
│   │   ├── LocationImportService.swift  # NEW (Milestone 1.1)
│   │   ├── FinancingTextService.swift   # NEW (M1.1 refinement)
│   │   └── ListingImportService.swift   # NEW (Milestone 1.1; FHA detection added M1.1 refinement)
│   │       ├── LocalListingParser.swift
│   │       └── ClaudeListingParser.swift  # Stub (Milestone 1.1); impl in Milestone 4
│   ├── ViewModels/
│   │   ├── CatalogViewModel.swift
│   │   ├── PropertyEditorViewModel.swift
│   │   ├── ActivePropertyViewModel.swift
│   │   └── ListingImportViewModel.swift  # NEW (Milestone 1.1)
│   ├── Views/
│   │   ├── MainTabView.swift
│   │   ├── Catalog/
│   │   ├── PropertyDetail/
│   │   ├── PropertyEditor/
│   │   │   ├── PropertyEditorView.swift
│   │   │   └── LocationPickerView.swift  # NEW (Milestone 1.1)
│   │   ├── ListingImport/               # NEW (Milestone 1.1)
│   │   │   ├── ListingImportView.swift
│   │   │   └── DraftReviewView.swift
│   │   ├── ActiveProperty/
│   │   └── Settings/
│   ├── Components/
│   ├── Formatters/
│   └── Fixtures/
│
└── SunsetsAIKeyboard/               # Keyboard extension target
    ├── KeyboardViewController.swift
    ├── Features/
    │   ├── PropertySelector/
    │   ├── QuickActions/
    │   ├── MessageImport/
    │   ├── ResponsePreview/
    │   └── AIGeneration/
    ├── Services/
    │   ├── CatalogReader.swift
    │   ├── TemplateEngine.swift       # Updated to support {{googleMapsURL}}, {{publicLocation}}
    │   ├── IntentClassifier.swift
    │   └── AIService.swift            # Future
    └── Resources/
```

---

## 6. Data Flow

### 6.1 Main App → App Group → Keyboard (unchanged)

```
Admin edits property
         │
         ▼
CatalogCacheService serializes KeyboardProperty array
  (applies isExactLocationShareable gate for coordinates)
         │
         ▼
Writes keyboard_catalog.json to App Group container
         │
         ▼
SunsetsAIKeyboard reads file on next launch or refresh
```

### 6.2 Location Import Flow (Milestone 1.1)

```
Admin opens LocationPickerView
         │
         ├── Map picker: drag pin → latitude, longitude
         │
         ├── Address search: MKLocalSearch → formattedAddress, latitude, longitude
         │
         └── URL paste: LocationImportService.parseGoogleMapsURL()
                              → latitude, longitude, googleMapsURL
         │
         ▼
Admin sets publicLocationLabel (optional, differs from locationSummary)
Admin toggles isExactLocationShareable
         │
         ▼
Save → CatalogCacheService projects new fields into KeyboardProperty
```

### 6.3 Listing Import Flow (Milestone 1.1)

```
Admin pastes listing text in ListingImportView
         │
         ▼
ListingImportService.parse(description) → PropertyDraft
(LocalListingParser in Milestone 1.1; ClaudeListingParser in Milestone 4)
         │
         ▼
DraftReviewView shows fields with DraftConfidence indicators
Admin reviews, corrects uncertain/missing fields
         │
         ├── "Descartar" → draft discarded, nothing saved
         │
         └── "Confirmar y crear propiedad" → PropertyEditorViewModel.save()
                              → LocalPropertyRepository.save()
```

### 6.4 Internal Code Generation Flow (Milestone 1.1)

```
Admin opens "Nueva propiedad"
         │
         ▼
PropertyEditorViewModel calls InternalCodeGenerator.nextCode(existingCodes:)
Proposed code pre-filled in internalCode field
         │
         ▼
Admin accepts or overrides
         │
         ▼
PropertyEditorViewModel.validate() checks uniqueness
         │
         ├── Duplicate → error displayed, save blocked
         └── Unique → save proceeds
```

### 6.5 AI Generation (Future — Milestone 4)

*(Unchanged from v0.2)*

---

## 7. Repository Pattern (Dependency Injection)

*(Unchanged from v0.2)*

```swift
protocol PropertyRepository {
    func fetchAll() async throws -> [Property]
    func save(_ property: Property) async throws
    func delete(id: String) async throws
    func setActive(id: String?) async throws
    func fetchActiveId() async throws -> String?
    func fetchEmployee() async throws -> String?
    func setEmployee(_ name: String) async throws
}
```

**Milestone 1.1 addition:**
```swift
    func fetchAllCodes() async throws -> [String]   // For InternalCodeGenerator
```

---

## 8. Authentication (Future — Milestone 5)

*(Unchanged from v0.2)*

---

## 9. Backend (Future — Milestone 4)

- **Runtime:** Node.js, TypeScript
- **Deployment:** Vercel serverless functions
- **Endpoints:** See `docs/API_CONTRACTS.md`
- **AI model:** Anthropic Claude via the Messages API
- **Milestone 1.1 addition:** `POST /import/listing` endpoint defined (implementation deferred)

---

## 10. Offline Strategy

| Layer | Offline behavior |
|-------|-----------------|
| Main app | Full CRUD, location picker (MapKit), local listing import — all offline |
| `LocalListingParser` | Fully offline — no network |
| `ClaudeListingParser` | Requires network (Milestone 4) |
| App Group cache | Always available |
| Keyboard templates | Fully offline |
| Keyboard AI generation | Disabled; user sees offline indicator |

---

## 11. MapKit Integration

- `import MapKit` is added to the `SunsetsProperties` target only.
- No new entitlements are required for `MKLocalSearch` or coordinate display.
- Location Services (`CLLocationManager`) is not required for Milestone 1.1. If "use my current location" is added later, `NSLocationWhenInUseUsageDescription` must be added to `Info.plist` and reviewed by a human before shipping.
- The map picker defaults to a center coordinate (Guatemala City: 14.6349°N, 90.5069°W) when no existing location is set.

---

## 12. Deployment Target

- iOS 17 minimum (confirmed — ADR-008).
- iPhone only. iPad out of scope.
- No macOS Catalyst.
- Primary interface language: Spanish for Guatemala (`es-GT`).

---

## 13. Key Non-Goals

- The keyboard does not detect which application is in the foreground.
- The keyboard does not read conversation history from the host app.
- The keyboard does not automatically send any message.
- The main application does not expose a public API.
- No web or Android version in any milestone.
- No property photos or media in any milestone through Milestone 1.1.
