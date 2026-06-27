# Property Schema — Sunsets AI Keyboard

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27
**Status:** Approved

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

## 3. Full Property Model (Main Application Only)

This model lives exclusively inside the `SunsetsProperties` target. It is never written directly to the App Group.

```
Property
├── id: String                      // UUID, primary key
├── internalCode: String            // Internal reference (e.g., "SUN-042")
├── title: String                   // Display name (e.g., "Penthouse Torre Reforma")
├── operationType: OperationType    // rent | sale | rentOrSale
├── status: PropertyStatus          // available | reserved | rented | sold | inactive
│
├── price: Decimal                  // Primary listed price
├── currency: String                // ISO 4217 (e.g., "MXN", "USD")
├── maintenanceFee: Decimal?        // Monthly maintenance/HOA fee
├── maintenanceIncluded: Bool       // Whether fee is included in the listed price
├── deposit: Decimal?               // Security deposit amount
│
├── locationSummary: String         // Short public-facing location (e.g., "Polanco, CDMX")
├── fullAddress: String?            // Complete address — NEVER copied to keyboard cache
├── neighborhood: String?
├── city: String?
├── state: String?
├── country: String                 // Default: "México"
├── latitude: Double?               // For future map display
├── longitude: Double?
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
│
├── requirements: [String]          // e.g., ["Credit check", "3 months deposit", "Employment proof"]
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

## 4. Keyboard-Safe Cache Model (Both Targets)

`KeyboardProperty` is a strict projection of `Property`. It contains only what the keyboard needs to display information, render templates, and provide verified context to the AI backend.

```
KeyboardProperty
├── id: String                      // Matches Property.id
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
├── locationSummary: String         // ✅ Public-facing summary only
│                                   // ❌ fullAddress is excluded
├── neighborhood: String?
├── city: String?
│
├── bedrooms: Int
├── bathrooms: Double
├── halfBathrooms: Int?
├── parkingSpaces: Int
├── areaSquareMeters: Double
│
├── amenities: [String]
├── includedAppliances: [String]
├── requirements: [String]
├── petPolicy: PetPolicy
├── visitInstructions: String?
│
├── quickReplyTemplates: [QuickReplyTemplate]
├── isFavorite: Bool
│
├── lastVerifiedAt: Date?
└── updatedAt: Date                 // Used to detect stale data in the keyboard
```

**Excluded fields (never in keyboard cache — approved, ADR-008):**

| Field | Reason |
|-------|--------|
| `fullAddress` | Privacy — keyboard is accessible from any app; `locationSummary` is sufficient |
| `assignedAgentId` | Internal operational data; employee identity is managed separately |
| `latitude` / `longitude` | Not needed for reply generation |
| `floorNumber` / `totalFloors` | May be added later if templates require it |
| `createdAt` | Operational metadata not relevant to the keyboard |
| Owner information | Sensitive — not needed for reply generation |
| Commissions / fee splits | Internal financial data; must never leave the main app |
| Private contact details | Agent or owner phone/email; not customer-facing data |
| Access codes / key locations | Security-critical; must never be cached outside the main app |
| Internal admin notes | Unstructured internal data; not verified for customer use |

---

## 5. Supporting Types

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
    let label: String          // Short button label (e.g., "Price", "Visit info")
    let bodyTemplate: String   // Template string with {{variable}} placeholders
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

Template variable tokens (resolved from `KeyboardProperty`):

| Token | Source field |
|-------|-------------|
| `{{title}}` | `title` |
| `{{price}}` | `price` formatted with `currency` |
| `{{currency}}` | `currency` |
| `{{maintenanceFee}}` | `maintenanceFee` |
| `{{deposit}}` | `deposit` |
| `{{location}}` | `locationSummary` |
| `{{bedrooms}}` | `bedrooms` |
| `{{bathrooms}}` | `bathrooms` |
| `{{area}}` | `areaSquareMeters` |
| `{{parking}}` | `parkingSpaces` |
| `{{amenities}}` | `amenities` joined |
| `{{appliances}}` | `includedAppliances` joined |
| `{{requirements}}` | `requirements` joined |
| `{{petPolicy}}` | `petPolicy` human-readable |
| `{{visitInstructions}}` | `visitInstructions` |
| `{{status}}` | `status` human-readable |

---

## 6. Default System Templates

In addition to property-specific templates, the keyboard provides default system templates available for any property. These are not stored in the catalog; they are rendered from the property's cached data at runtime.

| Label | Category | Example body |
|-------|----------|--------------|
| Price | price | "El precio de **{{title}}** es de {{price}} {{currency}} al mes." |
| Maintenance | price | "La cuota de mantenimiento es de {{maintenanceFee}} {{currency}} mensual{{#maintenanceIncluded}} (incluida en el precio){{/maintenanceIncluded}}." |
| Location | location | "El inmueble está ubicado en {{location}}." |
| Details | general | "{{title}}: {{bedrooms}} rec, {{bathrooms}} baños, {{area}} m², {{parking}} lugar(es) de estacionamiento." |
| Amenities | amenities | "El inmueble cuenta con: {{amenities}}." |
| Requirements | requirements | "Los requisitos son: {{requirements}}." |
| Pet policy — allowed | petPolicy | "¡Se aceptan mascotas!" |
| Pet policy — not allowed | petPolicy | "Lamentablemente no se aceptan mascotas en este inmueble." |
| Visit instructions | visit | "{{visitInstructions}}" |
| Availability | availability | "¡El inmueble está disponible! ¿Te gustaría agendar una visita?" |

---

## 7. Serialization

The keyboard cache file is stored as JSON at:

```
<AppGroupContainer>/Library/Application Support/keyboard_catalog.json
```

Encoding: UTF-8, pretty-printed for debuggability in Milestone 1–2; compact in production.

All `Date` values are encoded as ISO 8601 strings.
All `Decimal` values are encoded as JSON numbers (not strings).

---

## 8. Required Fields for Keyboard Availability

A property is included in the keyboard cache only if ALL of the following fields are non-empty/non-nil and the status is not `inactive`:

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

## 9. Cache Size Limit

The keyboard cache must remain within practical memory limits.

- Maximum recommended entries: 500 properties.
- Maximum recommended cache file size: 2 MB.
- If the catalog exceeds these limits, the main application should offer a filtered sync (e.g., only `available` and `reserved` properties).
