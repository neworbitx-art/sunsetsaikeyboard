# API Contracts — Sunsets AI Keyboard

**Version:** 0.3 (Milestone 1.1 — Pending approval)
**Last updated:** 2026-06-27
**Status:** Proposed — not implemented. These contracts describe the intended future backend API. Nothing here should be built until Milestone 4 (except where noted).

Base URL (proposed): `https://api.sunsetsai.vercel.app` (or custom domain TBD)

All requests use HTTPS. All request and response bodies are `application/json`. All authenticated endpoints require a Bearer token in the `Authorization` header.

---

## 1. Authentication

### POST /auth/login

Authenticates an agent and returns a session token. Proxies Supabase Auth.

**Request:**
```json
{
  "email": "agent@sunsetsrealestate.com",
  "password": "••••••••"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresAt": "2026-07-26T12:00:00Z",
  "userId": "uuid-v4",
  "role": "agent"
}
```

**Response 401:**
```json
{
  "error": "invalid_credentials",
  "message": "Email or password is incorrect."
}
```

---

### POST /auth/refresh

Refreshes a session token.

**Request:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Response 200:** Same as `/auth/login` 200 without `refreshToken`.

**Response 401:**
```json
{
  "error": "token_expired",
  "message": "Refresh token has expired. Please log in again."
}
```

---

## 2. Property Synchronization

### GET /catalog/version

Returns the current catalog version token without downloading the full catalog. Used to determine whether a sync is needed.

**Headers:** `Authorization: Bearer <accessToken>`

**Response 200:**
```json
{
  "version": "2026-06-26T15:30:00Z",
  "propertyCount": 47
}
```

---

### GET /catalog

Returns the full keyboard-safe catalog for the authenticated user's organization. The response shape follows `KeyboardProperty` as defined in `docs/PROPERTY_SCHEMA.md` Section 6.

**Headers:** `Authorization: Bearer <accessToken>`

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `since` | ISO 8601 string | If provided, returns only properties updated after this timestamp. |
| `status` | comma-separated | Filter by status: `available,reserved`. |

**Response 200:**
```json
{
  "version": "2026-06-26T15:30:00Z",
  "properties": [
    {
      "id": "uuid-v4",
      "internalCode": "SUN-042",
      "title": "Penthouse Torre Reforma",
      "operationType": "rent",
      "status": "available",
      "price": 85000,
      "currency": "GTQ",
      "maintenanceFee": 4500,
      "maintenanceIncluded": false,
      "deposit": 170000,
      "locationSummary": "Zona 10, Guatemala City",
      "publicLocationLabel": "Zona 10",
      "neighborhood": "Zona 10",
      "city": "Guatemala City",
      "latitude": null,
      "longitude": null,
      "googleMapsURL": "https://www.google.com/maps?q=14.6349,-90.5069",
      "isExactLocationShareable": false,
      "bedrooms": 3,
      "bathrooms": 2.5,
      "halfBathrooms": 1,
      "parkingSpaces": 2,
      "areaSquareMeters": 180.5,
      "amenities": ["Pool", "Gym", "Rooftop", "24h Security", "Concierge"],
      "includedAppliances": ["Refrigerator", "Stove", "Washer", "Dryer"],
      "includedItems": ["Curtains", "Wardrobes"],
      "excludedItems": [],
      "requirements": ["3 months deposit", "Credit check", "Employment proof"],
      "petPolicy": "notAllowed",
      "visitInstructions": "Call 55-1234-5678 to schedule. Monday–Saturday 10 AM–6 PM.",
      "quickReplyTemplates": [
        {
          "id": "uuid-template-1",
          "label": "Price",
          "bodyTemplate": "El precio de renta es Q{{price}} al mes, más Q{{maintenanceFee}} de mantenimiento.",
          "category": "price"
        }
      ],
      "isFavorite": false,
      "lastVerifiedAt": "2026-06-20T10:00:00Z",
      "updatedAt": "2026-06-25T09:15:00Z"
    }
  ]
}
```

**Notes:**
- `latitude` and `longitude` are included in the response only when `isExactLocationShareable == true` on the server. When `false`, the server returns `null` for both.
- `fullAddress` and `formattedAddress` are **never** included in this response, regardless of server-side values.
- `locationSource` is **never** included in this response (internal tracking field).

**Response 304:** No changes since `since` timestamp.

**Response 401:** Unauthorized.

---

## 3. AI Response Generation

### POST /generate

Generates an AI-assisted reply for the active property and an explicitly provided customer message.

**This endpoint must never receive:**
- The full conversation history.
- The customer's contact information.
- The full property address (`fullAddress` or `formattedAddress`).
- Any data not listed in the request schema below.

**Headers:** `Authorization: Bearer <accessToken>`

**Request:**
```json
{
  "userId": "uuid-v4",
  "property": {
    "id": "uuid-v4",
    "title": "Penthouse Torre Reforma",
    "operationType": "rent",
    "status": "available",
    "price": 85000,
    "currency": "GTQ",
    "maintenanceFee": 4500,
    "maintenanceIncluded": false,
    "deposit": 170000,
    "locationSummary": "Zona 10, Guatemala City",
    "publicLocationLabel": "Zona 10",
    "googleMapsURL": "https://www.google.com/maps?q=14.6349,-90.5069",
    "bedrooms": 3,
    "bathrooms": 2.5,
    "parkingSpaces": 2,
    "areaSquareMeters": 180.5,
    "amenities": ["Pool", "Gym", "Rooftop", "24h Security"],
    "includedAppliances": ["Refrigerator", "Stove", "Washer", "Dryer"],
    "includedItems": ["Curtains", "Wardrobes"],
    "excludedItems": [],
    "requirements": ["3 months deposit", "Credit check", "Employment proof"],
    "petPolicy": "notAllowed",
    "visitInstructions": "Call 55-1234-5678 to schedule. Monday–Saturday 10 AM–6 PM."
  },
  "customerMessage": "Hola! Me interesa el depa, ¿cuánto es la renta y qué incluye?",
  "responseStyle": "friendly",
  "language": "es"
}
```

**Field definitions:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `userId` | String | Yes | Authenticated user ID for audit |
| `property` | Object | Yes | Keyboard-safe property fields only — see above |
| `customerMessage` | String | Yes | Explicitly imported by user; max 2000 chars |
| `responseStyle` | String | Yes | `friendly` \| `formal` \| `concise` |
| `language` | String | No | ISO 639-1; defaults to `"es"` |

**Response 200:**
```json
{
  "responseId": "resp_uuid",
  "text": "¡Hola! Claro, con gusto te informo. El Penthouse Torre Reforma tiene una renta de Q85,000 al mes, más Q4,500 de mantenimiento...",
  "intent": "price_and_amenities_inquiry",
  "usedTemplate": false,
  "generatedAt": "2026-06-26T14:22:10Z"
}
```

**Response 422 — Unclassifiable intent:**
```json
{
  "error": "intent_requires_human",
  "message": "This message involves price negotiation or an unclassifiable intent. Human judgment required.",
  "intent": "negotiation"
}
```

**Response 429 — Rate limited:**
```json
{
  "error": "rate_limit_exceeded",
  "retryAfter": 60,
  "message": "You have exceeded the maximum requests per hour."
}
```

**Response 401:** Unauthorized.

---

## 4. Listing Import (Defined in Milestone 1.1 — Implemented in Milestone 4)

### POST /import/listing

Parses a raw listing description using Claude and returns a structured `PropertyDraft`. This endpoint will be used by `ClaudeListingParser` in Milestone 4.

**Status:** Contract defined. Implementation deferred to Milestone 4. The iOS `ClaudeListingParser` stub (Milestone 1.1) is written against this contract.

**Headers:** `Authorization: Bearer <accessToken>`

**Request:**
```json
{
  "userId": "uuid-v4",
  "description": "Penthouse en renta en Zona 10, Guatemala. 3 recámaras, 2.5 baños, 2 estacionamientos. Q 15,000/mes. Excelente ubicación, seguridad 24/7, gym, rooftop. Requisitos: fianza de 2 meses, comprobante de ingresos. Mascotas no permitidas. Informes: 1234-5678."
}
```

**Field definitions:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `userId` | String | Yes | For audit only |
| `description` | String | Yes | Raw listing text; max 5000 chars |

**Response 200:**
```json
{
  "draftId": "draft_uuid",
  "parserVersion": "claude-backend-v1",
  "fields": {
    "title": {
      "value": "Penthouse Zona 10",
      "confidence": "medium",
      "warning": "Title was inferred; not explicitly stated in the listing."
    },
    "operationType": {
      "value": "rent",
      "confidence": "high",
      "warning": null
    },
    "status": {
      "value": "available",
      "confidence": "high",
      "warning": null
    },
    "price": {
      "value": 15000,
      "confidence": "high",
      "warning": null
    },
    "currency": {
      "value": "GTQ",
      "confidence": "high",
      "warning": null
    },
    "deposit": {
      "value": 30000,
      "confidence": "medium",
      "warning": "Deposit calculated as 2× monthly rent."
    },
    "maintenanceFee": {
      "value": null,
      "confidence": "missing",
      "warning": "Maintenance fee not mentioned in the listing."
    },
    "locationSummary": {
      "value": "Zona 10, Guatemala City",
      "confidence": "high",
      "warning": null
    },
    "bedrooms": {
      "value": 3,
      "confidence": "high",
      "warning": null
    },
    "bathrooms": {
      "value": 2.5,
      "confidence": "high",
      "warning": null
    },
    "parkingSpaces": {
      "value": 2,
      "confidence": "high",
      "warning": null
    },
    "amenities": {
      "value": ["24h Security", "Gym", "Rooftop"],
      "confidence": "high",
      "warning": null
    },
    "requirements": {
      "value": ["2 months deposit", "Employment proof"],
      "confidence": "medium",
      "warning": null
    },
    "petPolicy": {
      "value": "notAllowed",
      "confidence": "high",
      "warning": null
    },
    "contactInfo": {
      "value": "1234-5678",
      "confidence": "high",
      "warning": "Contact info is for reference only and will not be saved to the property."
    }
  }
}
```

**Response 400 — Empty or invalid input:**
```json
{
  "error": "invalid_input",
  "message": "The description field is required and must be at least 10 characters."
}
```

**Response 401:** Unauthorized.

**Response 413 — Input too long:**
```json
{
  "error": "description_too_long",
  "message": "Description must be 5000 characters or fewer.",
  "maxLength": 5000
}
```

**Security notes for this endpoint:**
- The backend must not log the `description` field in server logs.
- If the listing text may contain customer information (unusual case), the caller should redact it before sending.
- The backend must not store the listing description after the response is sent.
- The `contactInfo` field in the response is a reference field only. The iOS application must never save it to the `Property` model.

---

## 5. Catalog Version Check

See Section 2: `GET /catalog/version`.

---

## 6. Usage Event Recording

### POST /events

Records a usage event for analytics and audit. Fire-and-forget from the keyboard.

**Headers:** `Authorization: Bearer <accessToken>`

**Request:**
```json
{
  "userId": "uuid-v4",
  "propertyId": "uuid-v4",
  "eventType": "template_inserted",
  "metadata": {
    "templateCategory": "price",
    "responseStyle": "friendly"
  },
  "occurredAt": "2026-06-26T14:22:10Z"
}
```

**Event types:**

| Type | Trigger |
|------|---------|
| `property_selected` | User selects a property in the keyboard |
| `template_inserted` | User inserts a deterministic template response |
| `ai_generation_requested` | User taps Generate with AI |
| `ai_response_inserted` | User inserts an AI-generated response |
| `customer_message_imported` | User explicitly imports a clipboard message |
| `property_searched` | User types in the keyboard search field |
| `listing_import_started` | User initiates listing import (local or AI) |
| `listing_import_confirmed` | User confirms a draft and saves the property |
| `listing_import_discarded` | User discards a draft |

**Response 202:** Accepted (no body).

---

## 7. Error Envelope

All error responses follow this shape:

```json
{
  "error": "snake_case_error_code",
  "message": "Human-readable description.",
  "requestId": "req_uuid"
}
```

---

## 8. Rate Limits (Proposed)

| Endpoint | Limit |
|----------|-------|
| `/generate` | 60 requests / user / hour |
| `/import/listing` | 20 requests / user / hour |
| `/catalog` | 20 requests / user / hour |
| `/auth/login` | 10 requests / IP / 15 minutes |
| `/events` | 300 requests / user / hour |

---

## 9. Security Notes

- All endpoints require TLS 1.2+.
- JWT tokens are validated on every authenticated request.
- The backend never logs the full `customerMessage` field.
- The backend never logs the `description` field from `/import/listing`.
- The backend never returns or stores full property addresses.
- The Anthropic API key is stored in Vercel environment variables, never in responses.
- The iOS application stores the `accessToken` in the iOS Keychain, not in UserDefaults or the App Group.
- `latitude` and `longitude` are returned from `/catalog` only when `isExactLocationShareable == true` on the server record. The server enforces this gate; the iOS application must not override it.
