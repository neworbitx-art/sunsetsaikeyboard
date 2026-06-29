import Foundation
import Observation

@Observable
final class PropertyEditorViewModel {

    // MARK: - Identity (internalCode is auto-generated; private(set) prevents user editing)
    private(set) var internalCode: String = ""
    var propertyType: PropertyType = .other
    var displayTitle: String = ""
    var operationType: OperationType = .rent
    var status: PropertyStatus = .available
    var publicDescription: String = ""
    var publicListingText: String = ""

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

    /// Suggested display title auto-computed from type, operation, and public location label.
    /// Used as the TextField placeholder and as a fallback when displayTitle is empty on save.
    var suggestedDisplayTitle: String {
        guard propertyType != .other else { return "" }
        let typeOp = "\(propertyType.label) en \(operationType.titleWord)"
        let loc = publicLocationLabelText.trimmingCharacters(in: .whitespaces)
        return loc.isEmpty ? typeOp : "\(typeOp) · \(loc)"
    }

    // MARK: - Financing (sale only)
    var sellerFinancingStatus: SellerFinancingStatus = .unknown
    var bankFinancingAssistanceAvailable: Bool = false
    var fhaEligibility: FHAEligibility = .unknown
    var financingNotesText: String = ""

    // MARK: - IUSI (sale only)
    var iusiAmountText: String = ""
    var iusiFrequencyText: String = ""
    var iusiVerifiedAt: Date? = nil
    var iusiNotesText: String = ""

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
        applyRentRequirementsIfNeeded()
        applySaleFinancingDefaultsIfNeeded()
    }

    // Used only by tests to inject a code without a real repository
    func setInternalCodeForTesting(_ code: String) {
        internalCode = code
    }

    /// Prefills `displayTitle` with a canonical suggestion when the field is empty.
    /// Called by DraftReviewView right after `load(from:)` so the user sees an editable
    /// starting point. Does nothing when `displayTitle` is already set or `propertyType`
    /// is `.other` (unknown type → no meaningful suggestion).
    func seedSuggestedDisplayTitle() {
        guard displayTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard propertyType != .other else { return }
        displayTitle = Property.buildCanonicalTitle(
            propertyType: propertyType,
            operationType: operationType,
            developmentName: nil,
            neighborhoodName: nil,
            publicLocationLabel: nilIfEmpty(publicLocationLabelText),
            locationSummary: locationSummary
        )
    }

    // MARK: - Load from Property

    func load(from property: Property) {
        existingId = property.id
        createdAt = property.createdAt
        internalCode = property.internalCode
        propertyType = property.propertyType
        displayTitle = property.displayTitle
        operationType = property.operationType
        status = property.status
        publicDescription   = property.publicDescription ?? ""
        publicListingText   = property.publicListingText ?? ""

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

        sellerFinancingStatus = property.sellerFinancingStatus
        bankFinancingAssistanceAvailable = property.bankFinancingAssistanceAvailable
        fhaEligibility = property.fhaEligibility
        financingNotesText = property.financingNotes ?? ""

        iusiAmountText = property.iusiAmount.map { plainDecimal($0) } ?? ""
        iusiFrequencyText = property.iusiFrequency ?? ""
        iusiVerifiedAt = property.iusiVerifiedAt
        iusiNotesText = property.iusiNotes ?? ""
    }

    // MARK: - Load from Draft

    func load(from draft: PropertyDraft) {
        if let pt = draft.propertyType.value { propertyType = pt }
        if let pl = draft.publicListingText.value   { publicListingText = pl }
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
        if let fs = draft.sellerFinancingStatus.value { sellerFinancingStatus = fs }
        if let fha = draft.fhaEligibility.value { fhaEligibility = fha }
        applyRentRequirementsIfNeeded()
        applySaleFinancingDefaultsIfNeeded()
    }

    // MARK: - Validate

    @discardableResult
    func validate() -> Bool {
        var errors: [String] = []

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

        let effectiveDisplayTitle: String = {
            let t = displayTitle.trimmingCharacters(in: .whitespaces)
            return t.isEmpty ? suggestedDisplayTitle : t
        }()

        return Property(
            id: existingId ?? UUID().uuidString,
            internalCode: internalCode.trimmingCharacters(in: .whitespaces),
            propertyType: propertyType,
            title: effectiveDisplayTitle,
            displayTitle: effectiveDisplayTitle,
            operationType: operationType,
            status: status,
            publicDescription: nilIfEmpty(publicDescription),
            publicListingText: nilIfEmpty(publicListingText),
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
            sellerFinancingStatus: sellerFinancingStatus,
            bankFinancingAssistanceAvailable: bankFinancingAssistanceAvailable,
            fhaEligibility: fhaEligibility,
            financingNotes: nilIfEmpty(financingNotesText),
            iusiAmount: parseDecimal(iusiAmountText),
            iusiFrequency: nilIfEmpty(iusiFrequencyText),
            iusiVerifiedAt: iusiVerifiedAt,
            iusiNotes: nilIfEmpty(iusiNotesText),
            quickReplyTemplates: [],
            isFavorite: isFavorite,
            lastVerifiedAt: nil,
            createdAt: existingId != nil ? createdAt : now,
            updatedAt: now
        )
    }

    // MARK: - Default content

    private func applyRentRequirementsIfNeeded() {
        guard operationType == .rent || operationType == .rentOrSale else { return }
        guard requirementsText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        requirementsText = DefaultContent.rentRequirements.joined(separator: "\n")
    }

    // Prefills sale financing defaults for new and imported properties only.
    // Guarded by existingId == nil so the edit path never triggers prefill.
    func applySaleFinancingDefaultsIfNeeded() {
        guard existingId == nil else { return }
        guard operationType == .sale || operationType == .rentOrSale else { return }
        if sellerFinancingStatus == .unknown { sellerFinancingStatus = .unavailable }
        bankFinancingAssistanceAvailable = true
        if financingNotesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            financingNotesText = DefaultContent.saleDefaultNote
        }
        let fhaText = DefaultContent.saleDefaultNoteFHAAppend
        if fhaEligibility == .eligible, !financingNotesText.contains(fhaText) {
            let base = financingNotesText.trimmingCharacters(in: .whitespacesAndNewlines)
            financingNotesText = base.isEmpty ? fhaText : base + "\n\n" + fhaText
        }
    }

    // Called from the view's .onChange(of: vm.fhaEligibility) to keep the FHA paragraph
    // in sync with the picker without touching any surrounding custom text.
    func syncFHAFinancingNote(from previousEligibility: FHAEligibility) {
        guard operationType == .sale || operationType == .rentOrSale else { return }
        let fhaText = DefaultContent.saleDefaultNoteFHAAppend
        if fhaEligibility == .eligible {
            guard !financingNotesText.contains(fhaText) else { return }
            let base = financingNotesText.trimmingCharacters(in: .whitespacesAndNewlines)
            financingNotesText = base.isEmpty ? fhaText : base + "\n\n" + fhaText
        } else if previousEligibility == .eligible {
            var text = financingNotesText
            if let range = text.range(of: "\n\n" + fhaText) {
                text.removeSubrange(range)
            } else if let range = text.range(of: fhaText + "\n\n") {
                text.removeSubrange(range)
            } else if let range = text.range(of: fhaText) {
                text.removeSubrange(range)
            }
            financingNotesText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
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
