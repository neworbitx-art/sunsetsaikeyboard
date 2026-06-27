import Foundation

struct Property: Identifiable, Codable, Equatable {
    var id: String
    var internalCode: String
    var title: String
    var operationType: OperationType
    var status: PropertyStatus

    var price: Decimal
    var currency: String
    var maintenanceFee: Decimal?
    var maintenanceIncluded: Bool
    var deposit: Decimal?

    var locationSummary: String
    var neighborhood: String?
    var city: String?
    var state: String?
    var country: String

    var bedrooms: Int
    var bathrooms: Double
    var halfBathrooms: Int?
    var parkingSpaces: Int
    var areaSquareMeters: Double

    var amenities: [String]
    var includedAppliances: [String]
    var requirements: [String]
    var petPolicy: PetPolicy
    var visitInstructions: String?

    var quickReplyTemplates: [QuickReplyTemplate]
    var isFavorite: Bool

    var lastVerifiedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    // Validation: fields that must be present before keyboard cache inclusion
    var isValidForCache: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !internalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !locationSummary.trimmingCharacters(in: .whitespaces).isEmpty &&
        !currency.trimmingCharacters(in: .whitespaces).isEmpty &&
        price > 0
    }

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
}
