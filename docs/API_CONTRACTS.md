# API Contracts — Sunsets AI Keyboard

**Version:** 0.2 (Milestone 0 — Approved)
**Last updated:** 2026-06-27
**Status:** Proposed — not implemented. These contracts describe the intended future backend API. Nothing here should be built until Milestone 4.

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

Returns the full keyboard-safe catalog for the authenticated user's organization.

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
      "currency": "MXN",
      "maintenanceFee": 4500,
      "maintenanceIncluded": false,
      "deposit": 170000,
      "locationSummary": "Juárez, CDMX",
      "neighborhood": "Juárez",
      "city": "Ciudad de México",
      "bedrooms": 3,
      "bathrooms": 2.5,
      "halfBathrooms": 1,
      "parkingSpaces": 2,
      "areaSquareMeters": 180.5,
      "amenities": ["Pool", "Gym", "Rooftop", "24h Security", "Concierge"],
      "includedAppliances": ["Refrigerator", "Stove", "Washer", "Dryer"],
      "requirements": ["3 months deposit", "Credit check", "Employment proof"],
      "petPolicy": "notAllowed",
      "visitInstructions": "Call 55-1234-5678 to schedule. Monday–Saturday 10 AM–6 PM.",
      "quickReplyTemplates": [
        {
          "id": "uuid-template-1",
          "label": "Price",
          "bodyTemplate": "El precio de renta es ${{price}} {{currency}} al mes, más ${{maintenanceFee}} de mantenimiento.",
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

**Response 304:** No changes since `since` timestamp.

**Response 401:** Unauthorized.

---

## 3. AI Response Generation

### POST /generate

Generates an AI-assisted reply for the active property and an explicitly provided customer message.

**This endpoint must never receive:**
- The full conversation history.
- The customer's contact information.
- The full property address.
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
    "currency": "MXN",
    "maintenanceFee": 4500,
    "maintenanceIncluded": false,
    "deposit": 170000,
    "locationSummary": "Juárez, CDMX",
    "bedrooms": 3,
    "bathrooms": 2.5,
    "parkingSpaces": 2,
    "areaSquareMeters": 180.5,
    "amenities": ["Pool", "Gym", "Rooftop", "24h Security"],
    "includedAppliances": ["Refrigerator", "Stove", "Washer", "Dryer"],
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
| `property` | Object | Yes | Keyboard-safe property fields only |
| `customerMessage` | String | Yes | Explicitly imported by user; max 2000 chars |
| `responseStyle` | String | Yes | `friendly` \| `formal` \| `concise` |
| `language` | String | No | ISO 639-1; defaults to `"es"` |

**Response 200:**
```json
{
  "responseId": "resp_uuid",
  "text": "¡Hola! Claro, con gusto te informo. El Penthouse Torre Reforma tiene una renta de $85,000 MXN al mes, más $4,500 de mantenimiento...",
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

## 4. Catalog Version Check

See Section 2: `GET /catalog/version`.

---

## 5. Usage Event Recording

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

**Response 202:** Accepted (no body).

---

## 6. Error Envelope

All error responses follow this shape:

```json
{
  "error": "snake_case_error_code",
  "message": "Human-readable description.",
  "requestId": "req_uuid"
}
```

---

## 7. Rate Limits (Proposed)

| Endpoint | Limit |
|----------|-------|
| `/generate` | 60 requests / user / hour |
| `/catalog` | 20 requests / user / hour |
| `/auth/login` | 10 requests / IP / 15 minutes |
| `/events` | 300 requests / user / hour |

---

## 8. Security Notes

- All endpoints require TLS 1.2+.
- JWT tokens are validated on every authenticated request.
- The backend never logs the full `customerMessage` field.
- The backend never returns or stores full property addresses.
- The Anthropic API key is stored in Vercel environment variables, never in responses.
- The iOS application stores the `accessToken` in the iOS Keychain, not in UserDefaults or the App Group.
