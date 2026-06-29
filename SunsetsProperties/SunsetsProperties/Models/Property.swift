import Foundation

struct Property: Identifiable, Codable, Equatable {

    // MARK: - Identity
    var id: String
    var internalCode: String
    var propertyType: PropertyType = .other
    var developmentName: String? = nil
    var neighborhoodName: String? = nil
    var title: String = ""        // legacy mirror kept in JSON for backward compat; equals displayTitle on all new saves
    var displayTitle: String = "" // stored, user-editable title; migration-computed or user-set
    var operationType: OperationType
    var status: PropertyStatus

    // MARK: - Public content
    var publicDescription: String? = nil       // short optional description (manually entered)
    var publicListingText: String? = nil       // full sanitized listing text (set by importer)

    // MARK: - Price
    var price: Decimal
    var currency: String
    var maintenanceFee: Decimal?
    var maintenanceIncluded: Bool
    var deposit: Decimal?

    // MARK: - Location (public-facing)
    var locationSummary: String
    var publicLocationLabel: String? = nil
    var neighborhood: String?
    var city: String?
    var state: String?
    var country: String

    // MARK: - Location (private / extended — never copied to keyboard cache)
    var fullAddress: String? = nil
    var formattedAddress: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var googleMapsURL: String? = nil
    var wazeURL: String? = nil
    var locationSource: LocationSource = .manual
    var isExactLocationShareable: Bool = false

    // MARK: - Space
    var bedrooms: Int
    var bathrooms: Double
    var halfBathrooms: Int?
    var parkingSpaces: Int
    var areaSquareMeters: Double
    var floorNumber: Int? = nil
    var totalFloors: Int? = nil

    // MARK: - Features
    var amenities: [String]
    var includedAppliances: [String]
    var includedItems: [String] = []
    var excludedItems: [String] = []
    var requirements: [String]
    var petPolicy: PetPolicy
    var visitInstructions: String?

    // MARK: - Financing (sale only)
    var sellerFinancingStatus: SellerFinancingStatus = .unknown
    var bankFinancingAssistanceAvailable: Bool = false
    var fhaEligibility: FHAEligibility = .unknown
    var financingNotes: String? = nil

    // MARK: - IUSI (sale only)
    var iusiAmount: Decimal? = nil
    var iusiFrequency: String? = nil
    var iusiVerifiedAt: Date? = nil
    var iusiNotes: String? = nil

    // MARK: - Templates
    var quickReplyTemplates: [QuickReplyTemplate]

    // MARK: - Meta
    var isFavorite: Bool
    var lastVerifiedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Validation

    /// Returns true when the string is a plausible place name and not a parser artifact.
    /// Used by migration and tests to filter location candidates before composing the canonical title.
    static func isCleanLocationPart(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard t.count >= 3 else { return false }
        let lower = t.lowercased()
        let badPhrases = [
            "precio", "precio de venta", "precio de renta",
            "ubicación:", "ubicacion:",
            " q.", "q.", "gtq", "usd",
            "mantenimiento", "mant.",
            "http://", "https://", "www.",
            "@",
            "renta en", "en renta", "en venta", "venta en",
            "contáctanos", "contactanos", "contáctenos", "contactenos",
            "whatsapp", "teléfono", "telefono",
            "información y citas", "informacion y citas",
        ]
        if badPhrases.contains(where: { lower.contains($0) }) { return false }
        // Reject bare Quetzal amounts that have no period: "Q 5,000", "Q5000"
        if lower.range(of: #"q\s*\d"#, options: .regularExpression) != nil { return false }
        return true
    }

    /// Returns true when a stored displayTitle is suspected to contain parser-injected price
    /// text, maintenance info, or a property-type label that conflicts with the structured field.
    /// The decoder uses this to trigger a canonical rebuild for affected legacy records.
    static func isLegacyBadTitle(_ title: String, propertyType: PropertyType) -> Bool {
        let lower = title.lowercased()
        // Price / currency markers (with or without a period separator)
        if lower.range(of: #"q\s*\d"#, options: .regularExpression) != nil { return true }
        if lower.contains("gtq") || lower.contains("usd") { return true }
        if lower.contains("mantenimiento") { return true }
        // Type conflict: title begins with a recognised type label different from the stored type
        guard propertyType != .other else { return false }
        for candidate in PropertyType.allCases where candidate != .other {
            if lower.hasPrefix(candidate.label.lowercased() + " en ") && candidate != propertyType {
                return true
            }
        }
        return false
    }

    /// Computes the canonical display title from structured fields.
    /// Used by the decoder for migration and by tests directly.
    static func buildCanonicalTitle(
        propertyType: PropertyType,
        operationType: OperationType,
        developmentName: String?,
        neighborhoodName: String?,
        publicLocationLabel: String?,
        locationSummary: String
    ) -> String {
        let typeOp: String? = propertyType != .other
            ? "\(propertyType.label) en \(operationType.titleWord)"
            : nil
        let locationCandidates: [String?] = [developmentName, neighborhoodName, publicLocationLabel, locationSummary]
        let locationPart = locationCandidates
            .compactMap { $0 }
            .first { isCleanLocationPart($0) }
        let parts = [typeOp, locationPart].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? "Propiedad pendiente de revisión" : parts.joined(separator: " · ")
    }

    /// Diagnostic flag: true when the stored displayTitle is non-empty and is not the pending-review fallback.
    var isValidDisplayTitle: Bool {
        let t = displayTitle.trimmingCharacters(in: .whitespaces)
        return !t.isEmpty && t != "Propiedad pendiente de revisión"
    }

    /// Every property with a non-empty id and internal code is included in the keyboard catalog.
    /// Incomplete prices, locations, or titles use safe display fallbacks in the keyboard UI.
    var isValidForCache: Bool {
        !id.trimmingCharacters(in: .whitespaces).isEmpty &&
        !internalCode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Factory
    static func new() -> Property {
        let now = Date()
        return Property(
            id: UUID().uuidString,
            internalCode: "",
            operationType: .rent,
            status: .available,
            price: 0,
            currency: "GTQ",
            maintenanceFee: nil,
            maintenanceIncluded: false,
            deposit: nil,
            locationSummary: "",
            neighborhood: nil,
            city: nil,
            state: nil,
            country: "Guatemala",
            bedrooms: 1,
            bathrooms: 1,
            halfBathrooms: nil,
            parkingSpaces: 0,
            areaSquareMeters: 0,
            amenities: [],
            includedAppliances: [],
            requirements: [],
            petPolicy: .notAllowed,
            visitInstructions: nil,
            quickReplyTemplates: [],
            isFavorite: false,
            lastVerifiedAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Coding keys (used by synthesised encode(to:) and the custom decode in the extension)
    enum CodingKeys: String, CodingKey {
        case id, internalCode, propertyType, developmentName, neighborhoodName, title, displayTitle, operationType, status
        case publicDescription, publicListingText
        case price, currency, maintenanceFee, maintenanceIncluded, deposit
        case locationSummary, publicLocationLabel
        case neighborhood, city, state, country
        case fullAddress, formattedAddress
        case latitude, longitude, googleMapsURL, wazeURL, locationSource, isExactLocationShareable
        case bedrooms, bathrooms, halfBathrooms, parkingSpaces, areaSquareMeters
        case floorNumber, totalFloors
        case amenities, includedAppliances, includedItems, excludedItems
        case requirements, petPolicy, visitInstructions
        case sellerFinancingStatus, bankFinancingAssistanceAvailable, fhaEligibility, financingNotes
        case iusiAmount, iusiFrequency, iusiVerifiedAt, iusiNotes
        case quickReplyTemplates
        case isFavorite
        case lastVerifiedAt, createdAt, updatedAt
    }
}

// MARK: - Migration-safe decoder
// Placed in an extension so the compiler-synthesised memberwise init is preserved.
extension Property {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id              = try c.decode(String.self, forKey: .id)
        internalCode    = try c.decode(String.self, forKey: .internalCode)
        propertyType    = try c.decodeIfPresent(PropertyType.self, forKey: .propertyType) ?? .other
        developmentName = try c.decodeIfPresent(String.self, forKey: .developmentName)
        neighborhoodName = try c.decodeIfPresent(String.self, forKey: .neighborhoodName)
        title           = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        operationType   = try c.decode(OperationType.self, forKey: .operationType)
        status          = try c.decode(PropertyStatus.self, forKey: .status)
        publicDescription   = try c.decodeIfPresent(String.self, forKey: .publicDescription)
        publicListingText   = try c.decodeIfPresent(String.self, forKey: .publicListingText)

        price               = try c.decode(Decimal.self, forKey: .price)
        currency            = try c.decode(String.self, forKey: .currency)
        maintenanceFee      = try c.decodeIfPresent(Decimal.self, forKey: .maintenanceFee)
        maintenanceIncluded = try c.decodeIfPresent(Bool.self, forKey: .maintenanceIncluded) ?? false
        deposit             = try c.decodeIfPresent(Decimal.self, forKey: .deposit)

        locationSummary         = try c.decode(String.self, forKey: .locationSummary)
        publicLocationLabel     = try c.decodeIfPresent(String.self, forKey: .publicLocationLabel)
        neighborhood            = try c.decodeIfPresent(String.self, forKey: .neighborhood)
        city                    = try c.decodeIfPresent(String.self, forKey: .city)
        state                   = try c.decodeIfPresent(String.self, forKey: .state)
        country                 = try c.decodeIfPresent(String.self, forKey: .country) ?? "Guatemala"
        fullAddress             = try c.decodeIfPresent(String.self, forKey: .fullAddress)
        formattedAddress        = try c.decodeIfPresent(String.self, forKey: .formattedAddress)
        latitude                = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude               = try c.decodeIfPresent(Double.self, forKey: .longitude)
        googleMapsURL           = try c.decodeIfPresent(String.self, forKey: .googleMapsURL)
        wazeURL                 = try c.decodeIfPresent(String.self, forKey: .wazeURL)
        locationSource          = try c.decodeIfPresent(LocationSource.self, forKey: .locationSource) ?? .manual
        isExactLocationShareable = try c.decodeIfPresent(Bool.self, forKey: .isExactLocationShareable) ?? false

        bedrooms         = try c.decode(Int.self, forKey: .bedrooms)
        bathrooms        = try c.decode(Double.self, forKey: .bathrooms)
        halfBathrooms    = try c.decodeIfPresent(Int.self, forKey: .halfBathrooms)
        parkingSpaces    = try c.decodeIfPresent(Int.self, forKey: .parkingSpaces) ?? 0
        areaSquareMeters = try c.decodeIfPresent(Double.self, forKey: .areaSquareMeters) ?? 0
        floorNumber      = try c.decodeIfPresent(Int.self, forKey: .floorNumber)
        totalFloors      = try c.decodeIfPresent(Int.self, forKey: .totalFloors)

        amenities           = try c.decodeIfPresent([String].self, forKey: .amenities) ?? []
        includedAppliances  = try c.decodeIfPresent([String].self, forKey: .includedAppliances) ?? []
        includedItems       = try c.decodeIfPresent([String].self, forKey: .includedItems) ?? []
        excludedItems       = try c.decodeIfPresent([String].self, forKey: .excludedItems) ?? []
        requirements        = try c.decodeIfPresent([String].self, forKey: .requirements) ?? []

        // Migrate legacy pet policy values to the current 3-case enum.
        // "allowedWithDeposit" and "caseByCase" both map to .subjectToCaseAnalysis.
        let rawPetPolicy = try c.decodeIfPresent(String.self, forKey: .petPolicy) ?? PetPolicy.notAllowed.rawValue
        switch rawPetPolicy {
        case PetPolicy.allowed.rawValue:               petPolicy = .allowed
        case PetPolicy.notAllowed.rawValue:            petPolicy = .notAllowed
        case "allowedWithDeposit", "caseByCase",
             PetPolicy.subjectToCaseAnalysis.rawValue: petPolicy = .subjectToCaseAnalysis
        default:                                       petPolicy = .notAllowed
        }

        visitInstructions   = try c.decodeIfPresent(String.self, forKey: .visitInstructions)

        sellerFinancingStatus          = try c.decodeIfPresent(SellerFinancingStatus.self, forKey: .sellerFinancingStatus) ?? .unknown
        bankFinancingAssistanceAvailable = try c.decodeIfPresent(Bool.self, forKey: .bankFinancingAssistanceAvailable) ?? false
        fhaEligibility                 = try c.decodeIfPresent(FHAEligibility.self, forKey: .fhaEligibility) ?? .unknown
        financingNotes                 = try c.decodeIfPresent(String.self, forKey: .financingNotes)

        iusiAmount      = try c.decodeIfPresent(Decimal.self, forKey: .iusiAmount)
        iusiFrequency   = try c.decodeIfPresent(String.self, forKey: .iusiFrequency)
        iusiVerifiedAt  = try c.decodeIfPresent(Date.self, forKey: .iusiVerifiedAt)
        iusiNotes       = try c.decodeIfPresent(String.self, forKey: .iusiNotes)

        quickReplyTemplates = try c.decodeIfPresent([QuickReplyTemplate].self, forKey: .quickReplyTemplates) ?? []

        isFavorite     = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        lastVerifiedAt = try c.decodeIfPresent(Date.self, forKey: .lastVerifiedAt)
        createdAt      = try c.decode(Date.self, forKey: .createdAt)
        updatedAt      = try c.decode(Date.self, forKey: .updatedAt)

        // Migration: if displayTitle key is present, validate it.
        // Legacy titles that contain price markers or a property-type mismatch are rebuilt
        // from structured fields. An absent key (old JSON) always triggers a canonical rebuild.
        if c.contains(.displayTitle) {
            let stored = (try c.decodeIfPresent(String.self, forKey: .displayTitle)) ?? ""
            if !stored.isEmpty && Property.isLegacyBadTitle(stored, propertyType: propertyType) {
                displayTitle = Property.buildCanonicalTitle(
                    propertyType: propertyType,
                    operationType: operationType,
                    developmentName: developmentName,
                    neighborhoodName: neighborhoodName,
                    publicLocationLabel: publicLocationLabel,
                    locationSummary: locationSummary
                )
            } else {
                displayTitle = stored
            }
        } else {
            displayTitle = Property.buildCanonicalTitle(
                propertyType: propertyType,
                operationType: operationType,
                developmentName: developmentName,
                neighborhoodName: neighborhoodName,
                publicLocationLabel: publicLocationLabel,
                locationSummary: locationSummary
            )
        }
    }
}
