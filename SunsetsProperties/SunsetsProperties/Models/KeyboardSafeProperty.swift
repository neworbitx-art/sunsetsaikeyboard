import Foundation

// MARK: - Keyboard menu action (published in snapshot; isEnabled is user-controlled)

struct KeyboardMenuAction: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var isEnabled: Bool
    var rentOnly: Bool    // only show for rent/rentOrSale properties
    var saleOnly: Bool    // only show for sale/rentOrSale properties
}

// MARK: - Keyboard-safe snapshot envelope

struct KeyboardCatalogSnapshot: Codable {
    static let currentSchemaVersion = 3

    let schemaVersion: Int
    let catalogVersion: Int
    let generatedAt: Date
    let activePropertyID: String?
    let properties: [KeyboardSafeProperty]
    let generalMessages: [KeyboardSafeGeneralMessage]
    var menuActions: [KeyboardMenuAction] = []
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
        generalMessages  = try c.decode([KeyboardSafeGeneralMessage].self, forKey: .generalMessages)
        menuActions      = (try? c.decodeIfPresent([KeyboardMenuAction].self, forKey: .menuActions)) ?? []
    }
}

// MARK: - Keyboard-safe property projection

struct KeyboardSafeProperty: Codable, Identifiable, Equatable {

    // Identity
    let id: String
    let internalCode: String
    let propertyType: PropertyType
    let developmentName: String?
    let displayTitle: String
    let title: String
    let operationType: OperationType
    let status: PropertyStatus
    let publicDescription: String?
    let publicListingText: String?  // full sanitized listing body (primary body for Información general)

    // Price
    let price: Decimal
    let currency: String
    let maintenanceFee: Decimal?
    let maintenanceIncluded: Bool
    let deposit: Decimal?

    // Location (public only — fullAddress and formattedAddress are excluded)
    let locationSummary: String
    let publicLocationLabel: String?
    let neighborhood: String?
    let city: String?
    let latitude: Double?           // projected only when isExactLocationShareable
    let longitude: Double?          // projected only when isExactLocationShareable
    let googleMapsURL: String?
    let wazeURL: String?            // coordinate-based or label-based Waze link (nil when no approved location)
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
    let petPolicy: PetPolicy
    let visitInstructions: String?

    // Financing (sale only)
    let sellerFinancingStatus: SellerFinancingStatus
    let bankFinancingAssistanceAvailable: Bool
    let fhaEligibility: FHAEligibility
    let financingNotes: String?

    // IUSI (sale only)
    let iusiAmount: Decimal?
    let iusiFrequency: String?
    let iusiVerifiedAt: Date?
    let iusiNotes: String?

    // Meta
    let quickReplyTemplates: [QuickReplyTemplate]
    let isFavorite: Bool
    let lastVerifiedAt: Date?
    let updatedAt: Date
}

// MARK: - Projection from full Property

extension KeyboardSafeProperty {
    init(projecting property: Property) {
        id               = property.id
        internalCode     = property.internalCode
        propertyType     = property.propertyType
        developmentName  = property.developmentName
        displayTitle     = property.displayTitle
        title             = property.title
        operationType     = property.operationType
        status            = property.status
        publicDescription = property.publicDescription
        publicListingText = property.publicListingText

        price               = property.price
        currency            = property.currency
        maintenanceFee      = property.maintenanceFee
        maintenanceIncluded = property.maintenanceIncluded
        deposit             = property.deposit

        locationSummary         = property.locationSummary
        publicLocationLabel     = property.publicLocationLabel
        neighborhood            = property.neighborhood
        city                    = property.city
        googleMapsURL            = property.googleMapsURL
        isExactLocationShareable = property.isExactLocationShareable

        // Coordinates projected only when explicitly shareable
        if property.isExactLocationShareable {
            latitude  = property.latitude
            longitude = property.longitude
        } else {
            latitude  = nil
            longitude = nil
        }

        // Waze URL: coordinate-based when exact sharing approved; label-based otherwise
        if property.isExactLocationShareable,
           let lat = property.latitude, let lon = property.longitude {
            wazeURL = String(format: "https://waze.com/ul?ll=%.6f,%.6f&navigate=yes", lat, lon)
        } else if let label = property.publicLocationLabel, !label.isEmpty,
                  let encoded = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            wazeURL = "https://waze.com/ul?q=\(encoded)"
        } else {
            wazeURL = nil
        }

        bedrooms         = property.bedrooms
        bathrooms        = property.bathrooms
        halfBathrooms    = property.halfBathrooms
        parkingSpaces    = property.parkingSpaces
        areaSquareMeters = property.areaSquareMeters

        amenities          = property.amenities
        includedAppliances = property.includedAppliances
        includedItems      = property.includedItems
        excludedItems      = property.excludedItems
        requirements       = property.requirements
        petPolicy          = property.petPolicy
        visitInstructions  = property.visitInstructions

        sellerFinancingStatus          = property.sellerFinancingStatus
        bankFinancingAssistanceAvailable = property.bankFinancingAssistanceAvailable
        fhaEligibility                 = property.fhaEligibility
        financingNotes                 = property.financingNotes

        iusiAmount     = property.iusiAmount
        iusiFrequency  = property.iusiFrequency
        iusiVerifiedAt = property.iusiVerifiedAt
        iusiNotes      = property.iusiNotes

        quickReplyTemplates = property.quickReplyTemplates
        isFavorite          = property.isFavorite
        lastVerifiedAt      = property.lastVerifiedAt
        updatedAt           = property.updatedAt
    }
}
