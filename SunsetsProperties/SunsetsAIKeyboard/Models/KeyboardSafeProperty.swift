import Foundation

// MARK: - Keyboard menu action (keyboard extension version)

struct KBMenuAction: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let isEnabled: Bool
    let rentOnly: Bool
    let saleOnly: Bool
}

// MARK: - Keyboard catalog snapshot

struct KeyboardCatalogSnapshot: Codable {
    static let currentSchemaVersion = 3

    let schemaVersion: Int
    let catalogVersion: Int
    let generatedAt: Date
    let activePropertyID: String?
    let properties: [KeyboardSafeProperty]
    let generalMessages: [KBGeneralMessage]
    let menuActions: [KBMenuAction]
}

// Backward-compatible decoder: menuActions defaults to [] for old snapshots.
extension KeyboardCatalogSnapshot {
    enum CodingKeys: String, CodingKey {
        case schemaVersion, catalogVersion, generatedAt, activePropertyID
        case properties, generalMessages, menuActions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion    = try c.decode(Int.self, forKey: .schemaVersion)
        catalogVersion   = try c.decode(Int.self, forKey: .catalogVersion)
        generatedAt      = try c.decode(Date.self, forKey: .generatedAt)
        activePropertyID = try c.decodeIfPresent(String.self, forKey: .activePropertyID)
        properties       = try c.decode([KeyboardSafeProperty].self, forKey: .properties)
        generalMessages  = try c.decode([KBGeneralMessage].self, forKey: .generalMessages)
        menuActions      = (try? c.decodeIfPresent([KBMenuAction].self, forKey: .menuActions)) ?? []
    }
}

// MARK: - General message (keyboard extension version)

struct KBGeneralMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let category: String   // raw GeneralMessageCategory value
    let body: String
    let sortOrder: Int
    let requiresReviewBeforeInsertion: Bool

    var categoryLabel: String {
        switch category {
        case "welcome":              return "Bienvenida"
        case "qualification":        return "Filtro de cliente"
        case "reservationPayment":   return "Pago de reserva"
        case "visitCoordination":    return "Coordinación de visita"
        case "followUp":             return "Seguimiento"
        case "contactInfo":          return "Información de contacto"
        default:                     return "Personalizado"
        }
    }
}

// MARK: - Keyboard-safe property (extension-only version, uses raw string values)

struct KeyboardSafeProperty: Codable, Identifiable, Equatable {

    // Identity
    let id: String
    let internalCode: String
    let propertyType: String   // PropertyType raw value
    let developmentName: String?
    let displayTitle: String
    let title: String
    let operationType: String   // "rent" | "sale" | "rentOrSale"
    let status: String          // "available" | "reserved" | "rented" | "sold" | "inactive"
    let publicDescription: String?
    let publicListingText: String?   // full sanitized listing body

    // Price
    let price: Decimal
    let currency: String
    let maintenanceFee: Decimal?
    let maintenanceIncluded: Bool
    let deposit: Decimal?

    // Location (public only)
    let locationSummary: String
    let publicLocationLabel: String?
    let neighborhood: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let googleMapsURL: String?
    let wazeURL: String?             // coordinate-based or label-based Waze link
    let isExactLocationShareable: Bool

    // Space
    let bedrooms: Int
    let bathrooms: Double
    let halfBathrooms: Int?
    let parkingSpaces: Int
    let areaSquareMeters: Double

    // Features
    let amenities: [String]
    let includedAppliances: [String]
    let includedItems: [String]
    let excludedItems: [String]
    let requirements: [String]
    let petPolicy: String       // "allowed" | "notAllowed" | "subjectToCaseAnalysis"
    let visitInstructions: String?

    // Financing (sale only)
    let sellerFinancingStatus: String   // "unavailable" | "available" | "unknown"
    let bankFinancingAssistanceAvailable: Bool
    let fhaEligibility: String          // "eligible" | "notEligible" | "unknown"
    let financingNotes: String?

    // IUSI (sale only)
    let iusiAmount: Decimal?
    let iusiFrequency: String?
    let iusiVerifiedAt: Date?
    let iusiNotes: String?

    // Meta
    let quickReplyTemplates: [KBQuickReplyTemplate]
    let isFavorite: Bool
    let lastVerifiedAt: Date?
    let updatedAt: Date
}

// MARK: - Quick-reply template (extension-only, category as raw string)

struct KBQuickReplyTemplate: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let bodyTemplate: String
    let category: String
}

// MARK: - Convenience computed properties

extension KeyboardSafeProperty {

    var isAvailable: Bool { status == "available" }
    var isForSale: Bool { operationType == "sale" || operationType == "rentOrSale" }
    var isForRent: Bool { operationType == "rent" || operationType == "rentOrSale" }

    var displayLocation: String {
        publicLocationLabel ?? locationSummary
    }

    var statusLabel: String {
        switch status {
        case "available": return "Disponible"
        case "reserved":  return "Reservada"
        case "rented":    return "Rentada"
        case "sold":      return "Vendida"
        case "inactive":  return "Inactiva"
        default:          return status
        }
    }

    var operationLabel: String {
        switch operationType {
        case "rent":      return "Renta"
        case "sale":      return "Venta"
        case "rentOrSale": return "Renta o Venta"
        default:          return operationType
        }
    }

    var hasWarning: Bool { status != "available" }
}
