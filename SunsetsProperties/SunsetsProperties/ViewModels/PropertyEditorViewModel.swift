import Foundation
import Observation

@Observable
final class PropertyEditorViewModel {

    // MARK: - Identity (internalCode is auto-generated; private(set) prevents user editing)
    private(set) var internalCode: String = ""
    var title: String = ""
    var operationType: OperationType = .rent
    var status: PropertyStatus = .available

    // MARK: - Price
    var priceText: String = ""
    var currency: String = "GTQ"
    var maintenanceFeeText: String = ""
    var maintenanceIncluded: Bool = false
    var depositText: String = ""

    // MARK: - Location (public)
    var locationSummary: String = ""
    var publicLocationLabelText: String = ""
    var neighborhood: String = ""
    var city: String = ""
    var state: String = ""
    var country: String = "Guatemala"

    // MARK: - Location (private / coordinate)
    var latitude: Double? = nil
    var longitude: Double? = nil
    var formattedAddress: String? = nil
    var googleMapsURLText: String = ""
    var locationSource: LocationSource = .manual
    var isExactLocationShareable: Bool = false

    // MARK: - Space
    var bedroomsText: String = "1"
    var bathroomsText: String = "1"
    var halfBathroomsText: String = ""
    var parkingSpacesText: String = "0"
    var areaText: String = ""
    var floorNumberText: String = ""

    // MARK: - Features
    var amenitiesText: String = ""
    var appliancesText: String = ""
    var includedItemsText: String = ""
    var excludedItemsText: String = ""
    var requirementsText: String = ""
    var petPolicy: PetPolicy = .notAllowed
    var visitInstructions: String = ""
    var isFavorite: Bool = false

    // MARK: - State
    var validationErrors: [String] = []
    var isGeneratingCode: Bool = false

    private var existingId: String?
    private var createdAt: Date = Date()
    private let repository: (any PropertyRepository)?

    init(repository: (any PropertyRepository)? = nil) {
        self.repository = repository
    }

    // MARK: - Code generation

    func prepareForNew() async {
        guard existingId == nil, internalCode.isEmpty else { return }
        isGeneratingCode = true
        defer { isGeneratingCode = false }
        do {
            internalCode = try await repository?.peekNextInternalCode() ?? "SUN-???"
        } catch {
            internalCode = "SUN-???"
        }
    }

    // Used only by tests to inject a code without a real repository
    func setInternalCodeForTesting(_ code: String) {
        internalCode = code
    }

    // MARK: - Load from Property

    func load(from property: Property) {
        existingId = property.id
        createdAt = property.createdAt
        internalCode = property.internalCode
        title = property.title
        operationType = property.operationType
        status = property.status

        priceText = property.price == 0 ? "" : plainDecimal(property.price)
        currency = property.currency
        maintenanceFeeText = property.maintenanceFee.map { plainDecimal($0) } ?? ""
        maintenanceIncluded = property.maintenanceIncluded
        depositText = property.deposit.map { plainDecimal($0) } ?? ""

        locationSummary = property.locationSummary
        publicLocationLabelText = property.publicLocationLabel ?? ""
        neighborhood = property.neighborhood ?? ""
        city = property.city ?? ""
        state = property.state ?? ""
        country = property.country
        latitude = property.latitude
        longitude = property.longitude
        formattedAddress = property.formattedAddress
        googleMapsURLText = property.googleMapsURL ?? ""
        locationSource = property.locationSource
        isExactLocationShareable = property.isExactLocationShareable

        bedroomsText = "\(property.bedrooms)"
        bathroomsText = AppFormatters.bathrooms(property.bathrooms)
        halfBathroomsText = property.halfBathrooms.map { "\($0)" } ?? ""
        parkingSpacesText = "\(property.parkingSpaces)"
        areaText = property.areaSquareMeters == 0 ? "" : plainDouble(property.areaSquareMeters)
        floorNumberText = property.floorNumber.map { "\($0)" } ?? ""

        amenitiesText = property.amenities.joined(separator: "\n")
        appliancesText = property.includedAppliances.joined(separator: "\n")
        includedItemsText = property.includedItems.joined(separator: "\n")
        excludedItemsText = property.excludedItems.joined(separator: "\n")
        requirementsText = property.requirements.joined(separator: "\n")
        petPolicy = property.petPolicy
        visitInstructions = property.visitInstructions ?? ""
        isFavorite = property.isFavorite
    }

    // MARK: - Load from Draft

    func load(from draft: PropertyDraft) {
        if let t = draft.title.value { title = t }
        if let op = draft.operationType.value { operationType = op }
        if let st = draft.status.value { status = st }
        if let p = draft.price.value { priceText = plainDecimal(p) }
        if let cur = draft.currency.value { currency = cur }
        if let dep = draft.deposit.value { depositText = plainDecimal(dep) }
        if let fee = draft.maintenanceFee.value { maintenanceFeeText = plainDecimal(fee) }
        if let mi = draft.maintenanceIncluded.value { maintenanceIncluded = mi }
        if let loc = draft.locationSummary.value { locationSummary = loc }
        // Numeric fields: clear to empty when draft has no value, so the review
        // screen doesn't silently show a default (e.g. "1 baño" when not detected).
        bedroomsText = draft.bedrooms.value.map { "\($0)" } ?? ""
        bathroomsText = draft.bathrooms.value.map { AppFormatters.bathrooms($0) } ?? ""
        parkingSpacesText = draft.parkingSpaces.value.map { "\($0)" } ?? ""
        areaText = draft.areaSquareMeters.value.map { plainDouble($0) } ?? ""
        floorNumberText = draft.floorNumber.value.map { "\($0)" } ?? ""
        if let am = draft.amenities.value { amenitiesText = am.joined(separator: "\n") }
        if let ap = draft.includedAppliances.value { appliancesText = ap.joined(separator: "\n") }
        if let inc = draft.includedItems.value { includedItemsText = inc.joined(separator: "\n") }
        if let exc = draft.excludedItems.value { excludedItemsText = exc.joined(separator: "\n") }
        if let req = draft.requirements.value { requirementsText = req.joined(separator: "\n") }
        if let vis = draft.visitInstructions.value { visitInstructions = vis }
    }

    // MARK: - Validate

    @discardableResult
    func validate() -> Bool {
        var errors: [String] = []

        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("El título es requerido.")
        }
        if internalCode.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("El código interno es requerido.")
        }
        if locationSummary.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("La ubicación es requerida.")
        }
        if currency.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("La moneda es requerida.")
        }

        let price = parseDecimal(priceText)
        if price == nil {
            errors.append("El precio es requerido.")
        } else if let p = price, p < 0 {
            errors.append("El precio no puede ser negativo.")
        }

        if let fee = parseDecimal(maintenanceFeeText), fee < 0 {
            errors.append("El mantenimiento no puede ser negativo.")
        }
        if let dep = parseDecimal(depositText), dep < 0 {
            errors.append("El depósito no puede ser negativo.")
        }

        if let beds = Int(bedroomsText), beds < 0 {
            errors.append("El número de recámaras no puede ser negativo.")
        }
        if let baths = Double(bathroomsText), baths < 0 {
            errors.append("El número de baños no puede ser negativo.")
        }
        if let parking = Int(parkingSpacesText), parking < 0 {
            errors.append("El número de parqueos no puede ser negativo.")
        }
        if let area = Double(areaText), area < 0 {
            errors.append("El área no puede ser negativa.")
        }

        validationErrors = errors
        return errors.isEmpty
    }

    // MARK: - Build

    func buildProperty() -> Property? {
        guard validate() else { return nil }
        guard let price = parseDecimal(priceText) else { return nil }

        let now = Date()

        // Resolve coordinates from a pasted Google Maps URL when none are set
        var lat = latitude
        var lon = longitude
        var source = locationSource
        let urlText = googleMapsURLText.trimmingCharacters(in: .whitespaces)
        if !urlText.isEmpty, lat == nil || lon == nil {
            if let coord = GoogleMapsURLParser.parse(urlText) {
                lat = coord.latitude
                lon = coord.longitude
                source = .googleMapsURL
            }
        }

        // Generate maps URL from coordinates if none explicitly entered
        let resolvedMapsURL: String?
        if !urlText.isEmpty {
            resolvedMapsURL = urlText
        } else if let lat, let lon {
            resolvedMapsURL = GoogleMapsURLParser.generateURL(latitude: lat, longitude: lon)
        } else {
            resolvedMapsURL = nil
        }

        return Property(
            id: existingId ?? UUID().uuidString,
            internalCode: internalCode.trimmingCharacters(in: .whitespaces),
            title: title.trimmingCharacters(in: .whitespaces),
            operationType: operationType,
            status: status,
            price: price,
            currency: currency.trimmingCharacters(in: .whitespaces).uppercased(),
            maintenanceFee: parseDecimal(maintenanceFeeText),
            maintenanceIncluded: maintenanceIncluded,
            deposit: parseDecimal(depositText),
            locationSummary: locationSummary.trimmingCharacters(in: .whitespaces),
            publicLocationLabel: nilIfEmpty(publicLocationLabelText),
            neighborhood: nilIfEmpty(neighborhood),
            city: nilIfEmpty(city),
            state: nilIfEmpty(state),
            country: country.trimmingCharacters(in: .whitespaces),
            formattedAddress: formattedAddress,
            latitude: lat,
            longitude: lon,
            googleMapsURL: resolvedMapsURL,
            locationSource: source,
            isExactLocationShareable: isExactLocationShareable,
            bedrooms: Int(bedroomsText) ?? 0,
            bathrooms: Double(bathroomsText) ?? 1,
            halfBathrooms: Int(halfBathroomsText),
            parkingSpaces: Int(parkingSpacesText) ?? 0,
            areaSquareMeters: Double(areaText) ?? 0,
            floorNumber: Int(floorNumberText),
            amenities: parseLines(amenitiesText),
            includedAppliances: parseLines(appliancesText),
            includedItems: parseLines(includedItemsText),
            excludedItems: parseLines(excludedItemsText),
            requirements: parseLines(requirementsText),
            petPolicy: petPolicy,
            visitInstructions: nilIfEmpty(visitInstructions),
            quickReplyTemplates: [],
            isFavorite: isFavorite,
            lastVerifiedAt: nil,
            createdAt: existingId != nil ? createdAt : now,
            updatedAt: now
        )
    }

    // MARK: - Helpers

    private func parseDecimal(_ text: String) -> Decimal? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }

    private func parseLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func nilIfEmpty(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }

    private func plainDecimal(_ value: Decimal) -> String {
        (value as NSDecimalNumber).stringValue
    }

    private func plainDouble(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(value)
    }
}
