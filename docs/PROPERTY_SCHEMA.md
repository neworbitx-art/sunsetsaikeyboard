# Property Schema — Sunsets AI Keyboard

**Version:** 0.3 (Milestone 1.1 — Pending approval)
**Last updated:** 2026-06-27
**Status:** Pending approval

---

## 1. Property Statuses

| Status | Meaning |
|--------|---------|
| `available` | The property is available for rent or purchase. Availability confirmations are allowed. |
| `reserved` | The property has a pending agreement. No availability confirmations. |
| `rented` | The property is currently occupied under a rental contract. |
| `sold` | The property has been sold. |
| `inactive` | The property is not listed (off-market, under renovation, etc.). |

Properties with any status other than `available` must display a warning badge in the keyboard and must not generate availability-confirming responses.

---

## 2. Operation Types

| Value | Meaning |
|-------|---------|
| `rent` | Property is offered for rent. |
| `sale` | Property is offered for sale. |
| `rentOrSale` | Property may be rented or purchased. |

---

## 3. Internal Code Format

Human-readable identifiers follow the format `SUN-###`, where `###` is a zero-padded integer.

| Rule | Detail |
|------|--------|
| Format | `SUN-001`, `SUN-042`, `SUN-100`, etc. |
| Generation | Determined by the highest existing number + 1 |
| Uniqueness | Validated before saving; rejected if already in use |
| Reuse | Deleted or inactive codes are never reused |
| Override | An administrator may manually specify a code; uniqueness is still enforced |
| Supabase (future) | Must generate codes atomically using a sequence or advisory lock to prevent collisions under concurrent saves. Local generation is acceptable for Milestone 1.1 (single-user, offline). |

The internal code is separate from the UUID (`id`) field, which remains the immutable primary key. The code is human-readable, survives display, and is safe to include in the keyboard cache.

---

## 4. Location Source

```swift
enum LocationSource: String, Codable, CaseIterable {
    case manual          // User typed the address manually
    case mapPicker       // User selected a pin from MapKit
    case addressSearch   // User searched for an address in MapKit
    case googleMapsURL   // User pasted a Google Maps URL; coordinates extracted
}
```

---

## 5. Full Property Model (Main Application Only)

This model lives exclusively inside the `SunsetsProperties` target. It is never written directly to the App Group.

```
Property
├── id: String                      // UUID, immutable primary key
├── internalCode: String            // SUN-### human-readable code (see Section 3)
├── title: String                   // Display name (e.g., "Penthouse Torre Reforma")
├── operationType: OperationType    // rent | sale | rentOrSale
├── status: PropertyStatus          // available | reserved | rented | sold | inactive
│
├── price: Decimal                  // Primary listed price
├── currency: String                // ISO 4217 (e.g., "GTQ", "USD")
├── maintenanceFee: Decimal?        // Monthly maintenance/HOA fee
├── maintenanceIncluded: Bool       // Whether fee is included in the listed price
├── deposit: Decimal?               // Security deposit amount
│
├── ── LOCATION ──
├── locationSummary: String         // Short public-facing label (e.g., "Polanco, CDMX")
├── publicLocationLabel: String?    // Alternate public label that may differ from locationSummary
├── fullAddress: String?            // Complete private address — NEVER copied to keyboard cache
├── formattedAddress: String?       // Geocoded formatted address — NEVER copied to keyboard cache
├── neighborhood: String?
├── city: String?
├── state: String?
├── country: String                 // Default: "Guatemala"
├── latitude: Double?               // GPS coordinate (shareable only when isExactLocationShareable)
├── longitude: Double?              // GPS coordinate (shareable only when isExactLocationShareable)
├── googleMapsURL: String?          // Universal Google Maps link (https://maps.app.goo.gl/… or
│                                   //   https://www.google.com/maps?q=…)
├── locationSource: LocationSource  // How the location was recorded
├── isExactLocationShareable: Bool  // Whether latitude/longitude may appear in keyboard cache
│
├── bedrooms: Int
├── bathrooms: Double               // Allows 1.5, 2.5, etc.
├── halfBathrooms: Int?
├── parkingSpaces: Int
├── areaSquareMeters: Double
├── floorNumber: Int?
├── totalFloors: Int?
│
├── amenities: [String]             // e.g., ["Pool", "Gym", "Rooftop", "24h Security"]
├── includedAppliances: [String]    // e.g., ["Refrigerator", "Washer", "Stove"]
├── includedItems: [String]         // Non-appliance items included (e.g., "Curtains", "Wardrobes")
├── excludedItems: [String]         // Items present but excluded from the transaction
│
├── requirements: [String]          // e.g., ["Credit check", "3 months deposit"]
├── petPolicy: PetPolicy            // allowed | notAllowed | allowedWithDeposit | caseByCase
├── visitInstructions: String?      // How to schedule or access for a visit
│
├── quickReplyTemplates: [QuickReplyTemplate]  // Property-specific templates
│
├── assignedAgentId: String?        // NEVER copied to keyboard cache
├── isFavorite: Bool                // Persisted in main app; projected to keyboard cache
│
├── lastVerifiedAt: Date?           // When a human last confirmed the data is current
├── createdAt: Date
└── updatedAt: Date
```

---

## 6. Keyboard-Safe Cache Model (Both Targets)

`KeyboardProperty` is a strict projection of `Property`. It contains only what the keyboard needs.

```
KeyboardProperty
├── id: String
├── internalCode: String
├── title: String
├── operationType: OperationType
├── status: PropertyStatus
│
├── price: Decimal
├── currency: String
├── maintenanceFee: Decimal?
├── maintenanceIncluded: Bool
├── deposit: Decimal?
│
├── locationSummary: String         // ✅ Public-facing summary
├── publicLocationLabel: String?    // ✅ Alternate public label (if set)
│                                   // ❌ fullAddress excluded
│                                   // ❌ formattedAddress excluded
├── neighborhood: String?
├── city: String?
├── latitude: Double?               // ✅ Only when isExactLocationShareable == true
├── longitude: Double?              // ✅ Only when isExactLocationShareable == true
├── googleMapsURL: String?          // ✅ Safe to share — public link only
├── isExactLocationShareable: Bool  // ✅ Informs keyboard whether to display coordinates
│
├── bedrooms: Int
├── bathrooms: Double
├── halfBathrooms: Int?
├── parkingSpaces: Int
├── areaSquareMeters: Double
│
├── amenities: [String]
├── includedAppliances: [String]
├── includedItems: [String]
├── excludedItems: [String]
├── requirements: [String]
├── petPolicy: PetPolicy
├── visitInstructions: String?
│
├── quickReplyTemplates: [QuickReplyTemplate]
├── isFavorite: Bool
│
├── lastVerifiedAt: Date?
└── updatedAt: Date
```

**Excluded fields (never in keyboard cache):**

| Field | Reason |
|-------|--------|
| `fullAddress` | Privacy — exact street address must not leave the main app without explicit sharing |
| `formattedAddress` | Privacy — geocoded full address; same risk as `fullAddress` |
| `assignedAgentId` | Internal operational data |
| `latitude` / `longitude` | Excluded by default; included only when `isExactLocationShareable == true` |
| `floorNumber` / `totalFloors` | May be added later if templates require it |
| `createdAt` | Operational metadata |
| Owner information | Sensitive |
| Commissions / fee splits | Internal financial data |
| Private contact details | Not customer-facing |
| Access codes / key locations | Security-critical |
| Internal admin notes | Unstructured internal data |
| `locationSource` | Internal tracking metadata; not needed by keyboard |

---

## 7. Supporting Types

### PetPolicy

```swift
enum PetPolicy: String, Codable {
    case allowed
    case notAllowed
    case allowedWithDeposit
    case caseByCase
}
```

### QuickReplyTemplate

```swift
struct QuickReplyTemplate: Codable, Identifiable {
    let id: String
    let label: String
    let bodyTemplate: String
    let category: TemplateCategory
}

enum TemplateCategory: String, Codable {
    case price
    case availability
    case location
    case amenities
    case requirements
    case petPolicy
    case visit
    case general
}
```

---

## 8. PropertyDraft (Listing Import)

A `PropertyDraft` represents unconfirmed data extracted from a pasted listing description. It is never persisted to the property catalog until the user explicitly confirms.

```
PropertyDraft
├── id: String                          // Temporary session ID; never stored as a Property ID
├── sourceDescription: String           // Original pasted text, preserved verbatim
├── parserVersion: String               // Identifies which parser produced this draft
│
├── title: DraftField<String>
├── operationType: DraftField<OperationType>
├── status: DraftField<PropertyStatus>
├── price: DraftField<Decimal>
├── currency: DraftField<String>
├── deposit: DraftField<Decimal>
├── maintenanceFee: DraftField<Decimal>
├── maintenanceIncluded: DraftField<Bool>
├── locationSummary: DraftField<String>
├── bedrooms: DraftField<Int>
├── bathrooms: DraftField<Double>
├── parkingSpaces: DraftField<Int>
├── floorNumber: DraftField<Int>
├── amenities: DraftField<[String]>
├── includedAppliances: DraftField<[String]>
├── includedItems: DraftField<[String]>
├── excludedItems: DraftField<[String]>
├── requirements: DraftField<[String]>
├── visitInstructions: DraftField<String>
├── contactInfo: DraftField<String>     // Extracted contact — displayed for reference only
│                                       //   Never saved to the Property model
└── hashtags: DraftField<[String]>      // Informational only; not mapped to Property fields
```

### DraftField

```swift
struct DraftField<T: Codable>: Codable {
    var value: T?                           // Detected value; nil if not found
    var confidence: DraftConfidence         // How certain the parser is
    var warning: String?                    // Human-readable warning if uncertain or missing
}

enum DraftConfidence: String, Codable {
    case high       // Parser is confident; value shown without emphasis
    case medium     // Parser found a candidate but context is ambiguous
    case low        // Parser guessed; must be reviewed
    case missing    // Field not found in the source text
}
```

Fields with `confidence == .low` or `confidence == .missing` are highlighted in the review UI to draw the user's attention before confirming the import.

---

## 9. Default System Templates

*(Unchanged from v0.2 — see below for added location tokens)*

In addition to property-specific templates, the keyboard provides default system templates.

| Label | Category | Example body |
|-------|----------|--------------|
| Price | price | "El precio de **{{title}}** es de {{price}} {{currency}} al mes." |
| Maintenance | price | "La cuota de mantenimiento es de {{maintenanceFee}} {{currency}} mensual{{#maintenanceIncluded}} (incluida en el precio){{/maintenanceIncluded}}." |
| Location | location | "El inmueble está ubicado en {{location}}." |
| Location with map | location | "El inmueble está ubicado en {{location}}. Ver en mapa: {{googleMapsURL}}" |
| Details | general | "{{title}}: {{bedrooms}} rec, {{bathrooms}} baños, {{area}} m², {{parking}} lugar(es) de estacionamiento." |
| Amenities | amenities | "El inmueble cuenta con: {{amenities}}." |
| Requirements | requirements | "Los requisitos son: {{requirements}}." |
| Pet policy — allowed | petPolicy | "¡Se aceptan mascotas!" |
| Pet policy — not allowed | petPolicy | "Lamentablemente no se aceptan mascotas en este inmueble." |
| Visit instructions | visit | "{{visitInstructions}}" |
| Availability | availability | "¡El inmueble está disponible! ¿Te gustaría agendar una visita?" |

Additional template tokens (Milestone 1.1):

| Token | Source field |
|-------|-------------|
| `{{publicLocation}}` | `publicLocationLabel` (falls back to `locationSummary`) |
| `{{googleMapsURL}}` | `googleMapsURL` |

---

## 10. Serialization

The keyboard cache file is stored as JSON at:

```
<AppGroupContainer>/Library/Application Support/keyboard_catalog.json
```

Encoding: UTF-8, pretty-printed for debuggability in Milestone 1–2; compact in production.

All `Date` values are encoded as ISO 8601 strings.
All `Decimal` values are encoded as JSON numbers (not strings).

---

## 11. Required Fields for Keyboard Availability

A property is included in the keyboard cache only if ALL of the following fields are non-empty/non-nil:

- `title`
- `operationType`
- `status`
- `price`
- `currency`
- `locationSummary`
- `bedrooms`
- `bathrooms`

Properties with status `inactive` are included in the cache but clearly labeled. They cannot generate availability-confirming responses.

---

## 12. Cache Size Limit

- Maximum recommended entries: 500 properties.
- Maximum recommended cache file size: 2 MB.
- Location coordinates (`latitude`, `longitude`) are small (< 50 bytes per property) and do not materially affect cache size.
- If the catalog exceeds size limits, the main application should offer a filtered sync.

---

## 13. Migration — Existing Local Properties (Milestone 1.1)

Properties created during Milestone 1 do not have the new fields. On first launch after upgrading:

| New field | Migration default |
|-----------|------------------|
| `publicLocationLabel` | `nil` (falls back to `locationSummary` at display time) |
| `formattedAddress` | `nil` |
| `googleMapsURL` | `nil` |
| `locationSource` | `.manual` |
| `isExactLocationShareable` | `false` |
| `includedItems` | `[]` |
| `excludedItems` | `[]` |

Because `LocalPropertyRepository` uses a JSON file, new optional fields decode to `nil` automatically when absent, and new non-optional fields with defaults (`locationSource: .manual`, `isExactLocationShareable: false`) require the decoder to supply a default.

**Risk:** `locationSource` is a non-optional enum. The JSON decoder will fail if the key is absent and no default is provided. Mitigation: make `locationSource` optional (`LocationSource?`) in the Codable model and resolve to `.manual` at the service layer, or provide a custom `init(from:)` decoder with a default.

---

## 14. Property Media — Out of Scope

Property photographs, cover images, albums, media storage, and image-sharing are explicitly deferred. No image-related fields are added to `Property` or `KeyboardProperty` in Milestone 1.1.

This decision is recorded in ADR-013 in `docs/DECISIONS.md`.
