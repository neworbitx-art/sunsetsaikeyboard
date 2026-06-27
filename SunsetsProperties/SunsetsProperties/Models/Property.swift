import Foundation

struct Property: Identifiable, Codable, Equatable {

    // MARK: - Identity
    var id: String
    var internalCode: String
    var title: String
    var operationType: OperationType
    var status: PropertyStatus

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

    // MARK: - Templates
    var quickReplyTemplates: [QuickReplyTemplate]

    // MARK: - Meta
    var isFavorite: Bool
    var lastVerifiedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Validation
    var isValidForCache: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !internalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !locationSummary.trimmingCharacters(in: .whitespaces).isEmpty &&
        !currency.trimmingCharacters(in: .whitespaces).isEmpty &&
        price > 0
    }

    // MARK: - Factory
    static func new() -> Property {
        let now = Date()
        return Property(
            id: UUID().uuidString,
            internalCode: "",
            title: "",
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
        case id, internalCode, title, operationType, status
        case price, currency, maintenanceFee, maintenanceIncluded, deposit
        case locationSummary, publicLocationLabel
        case neighborhood, city, state, country
        case fullAddress, formattedAddress
        case latitude, longitude, googleMapsURL, locationSource, isExactLocationShareable
        case bedrooms, bathrooms, halfBathrooms, parkingSpaces, areaSquareMeters
        case floorNumber, totalFloors
        case amenities, includedAppliances, includedItems, excludedItems
        case requirements, petPolicy, visitInstructions
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
        title           = try c.decode(String.self, forKey: .title)
        operationType   = try c.decode(OperationType.self, forKey: .operationType)
        status          = try c.decode(PropertyStatus.self, forKey: .status)

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
        petPolicy           = try c.decodeIfPresent(PetPolicy.self, forKey: .petPolicy) ?? .notAllowed
        visitInstructions   = try c.decodeIfPresent(String.self, forKey: .visitInstructions)

        quickReplyTemplates = try c.decodeIfPresent([QuickReplyTemplate].self, forKey: .quickReplyTemplates) ?? []

        isFavorite     = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        lastVerifiedAt = try c.decodeIfPresent(Date.self, forKey: .lastVerifiedAt)
        createdAt      = try c.decode(Date.self, forKey: .createdAt)
        updatedAt      = try c.decode(Date.self, forKey: .updatedAt)
    }
}
