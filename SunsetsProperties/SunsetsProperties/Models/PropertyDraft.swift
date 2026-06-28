import Foundation

// MARK: - DraftConfidence

enum DraftConfidence: String, Codable, CaseIterable, Sendable {
    case high    // Parser is confident; value shown without emphasis
    case medium  // Parser found a candidate but context is ambiguous
    case low     // Parser guessed; must be reviewed
    case missing // Field not found in the source text

    var isUncertain: Bool { self == .low || self == .missing }

    var label: String {
        switch self {
        case .high:    return "Alto"
        case .medium:  return "Medio"
        case .low:     return "Bajo"
        case .missing: return "No detectado"
        }
    }
}

// MARK: - DraftField

struct DraftField<T: Codable & Sendable>: Codable, Sendable {
    var value: T?
    var confidence: DraftConfidence
    var warning: String?

    init(value: T? = nil, confidence: DraftConfidence = .missing, warning: String? = nil) {
        self.value = value
        self.confidence = confidence
        self.warning = warning
    }

    var hasValue: Bool { value != nil && confidence != .missing }
}

// MARK: - PropertyDraft

struct PropertyDraft: Identifiable, Sendable {
    var id: String
    var sourceDescription: String
    var parserVersion: String
    var createdAt: Date

    var propertyType: DraftField<PropertyType>
    var developmentName: DraftField<String>
    var publicDescription: DraftField<String>   // short description fragment
    var publicListingText: DraftField<String>   // full sanitized listing body
    var title: DraftField<String>
    var operationType: DraftField<OperationType>
    var status: DraftField<PropertyStatus>
    var price: DraftField<Decimal>
    var currency: DraftField<String>
    var deposit: DraftField<Decimal>
    var maintenanceFee: DraftField<Decimal>
    var maintenanceIncluded: DraftField<Bool>
    var locationSummary: DraftField<String>
    var bedrooms: DraftField<Int>
    var bathrooms: DraftField<Double>
    var parkingSpaces: DraftField<Int>
    var floorNumber: DraftField<Int>
    var areaSquareMeters: DraftField<Double>
    var amenities: DraftField<[String]>
    var includedAppliances: DraftField<[String]>
    var includedItems: DraftField<[String]>
    var excludedItems: DraftField<[String]>
    var requirements: DraftField<[String]>
    var visitInstructions: DraftField<String>
    var contactInfo: DraftField<String>
    var hashtags: DraftField<[String]>

    // MARK: - Financing (sale only)
    var sellerFinancingStatus: DraftField<SellerFinancingStatus>
    var fhaEligibility: DraftField<FHAEligibility>

    init(id: String = UUID().uuidString, sourceDescription: String, parserVersion: String) {
        self.id = id
        self.sourceDescription = sourceDescription
        self.parserVersion = parserVersion
        self.createdAt = Date()
        self.propertyType = DraftField()
        self.developmentName = DraftField()
        self.publicDescription = DraftField()
        self.publicListingText = DraftField()
        self.title = DraftField()
        self.operationType = DraftField()
        self.status = DraftField()
        self.price = DraftField()
        self.currency = DraftField()
        self.deposit = DraftField()
        self.maintenanceFee = DraftField()
        self.maintenanceIncluded = DraftField()
        self.locationSummary = DraftField()
        self.bedrooms = DraftField()
        self.bathrooms = DraftField()
        self.parkingSpaces = DraftField()
        self.floorNumber = DraftField()
        self.areaSquareMeters = DraftField()
        self.amenities = DraftField()
        self.includedAppliances = DraftField()
        self.includedItems = DraftField()
        self.excludedItems = DraftField()
        self.requirements = DraftField()
        self.visitInstructions = DraftField()
        self.contactInfo = DraftField()
        self.hashtags = DraftField()
        self.sellerFinancingStatus = DraftField()
        self.fhaEligibility = DraftField()
    }
}
