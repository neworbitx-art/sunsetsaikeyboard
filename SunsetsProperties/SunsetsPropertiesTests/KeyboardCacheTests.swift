import Testing
import Foundation
@testable import SunsetsProperties

// MARK: - KeyboardSafeProperty projection tests

@Suite("KeyboardSafeProperty Projection")
struct KeyboardSafePropertyProjectionTests {

    func makeFullProperty(
        id: String = "test-id",
        title: String = "Casa de Prueba",
        code: String = "SUN-001",
        status: PropertyStatus = .available,
        operation: OperationType = .rent,
        price: Decimal = 5_000,
        currency: String = "GTQ",
        petPolicy: PetPolicy = .notAllowed,
        isExactLocationShareable: Bool = false,
        latitude: Double? = 14.6349,
        longitude: Double? = -90.5069,
        googleMapsURL: String? = nil,
        isFavorite: Bool = false
    ) -> Property {
        var p = Property(
            id: id,
            internalCode: code,
            title: title,
            operationType: operation,
            status: status,
            price: price,
            currency: currency,
            maintenanceFee: nil,
            maintenanceIncluded: false,
            deposit: nil,
            locationSummary: "Zona 10, Guatemala",
            neighborhood: nil,
            city: "Guatemala",
            state: nil,
            country: "Guatemala",
            bedrooms: 3,
            bathrooms: 2,
            halfBathrooms: nil,
            parkingSpaces: 1,
            areaSquareMeters: 120,
            amenities: ["Piscina", "Gimnasio"],
            includedAppliances: ["Estufa"],
            requirements: ["Fiador"],
            petPolicy: petPolicy,
            visitInstructions: nil,
            quickReplyTemplates: [],
            isFavorite: isFavorite,
            lastVerifiedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        p.latitude = latitude
        p.longitude = longitude
        p.isExactLocationShareable = isExactLocationShareable
        p.googleMapsURL = googleMapsURL
        return p
    }

    @Test func projectionCopiesBasicFields() {
        let p = makeFullProperty(id: "abc", title: "Mi Casa", code: "SUN-007")
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.id == "abc")
        #expect(kp.title == "Mi Casa")
        #expect(kp.internalCode == "SUN-007")
    }

    @Test func projectionCopiesPrice() {
        let p = makeFullProperty(price: Decimal(12_500), currency: "USD")
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.price == Decimal(12_500))
        #expect(kp.currency == "USD")
    }

    @Test func coordinatesHiddenWhenNotShareable() {
        let p = makeFullProperty(isExactLocationShareable: false, latitude: 14.6349, longitude: -90.5069)
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.latitude == nil)
        #expect(kp.longitude == nil)
        #expect(kp.isExactLocationShareable == false)
    }

    @Test func coordinatesExposedWhenShareable() {
        let p = makeFullProperty(isExactLocationShareable: true, latitude: 14.6349, longitude: -90.5069)
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.latitude != nil)
        #expect(kp.longitude != nil)
        #expect(abs((kp.latitude ?? 0) - 14.6349) < 0.0001)
        #expect(abs((kp.longitude ?? 0) - (-90.5069)) < 0.0001)
    }

    @Test func googleMapsURLCopied() {
        let url = "https://goo.gl/maps/test123"
        let p = makeFullProperty(isExactLocationShareable: true, googleMapsURL: url)
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.googleMapsURL == url)
    }

    @Test func projectionCopiesAmenities() {
        let p = makeFullProperty()
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.amenities == ["Piscina", "Gimnasio"])
    }

    @Test func projectionCopiesPetPolicy() {
        let p = makeFullProperty(petPolicy: .allowed)
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.petPolicy == .allowed)
    }

    @Test func projectionCopiesFavoriteFlag() {
        let p = makeFullProperty(isFavorite: true)
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.isFavorite == true)
    }
}

// MARK: - KeyboardCatalogSnapshot encoding tests

@Suite("KeyboardCatalogSnapshot Encoding")
struct KeyboardCatalogSnapshotEncodingTests {

    func makeSnapshot(properties: [KeyboardSafeProperty] = [], activeID: String? = nil) -> KeyboardCatalogSnapshot {
        KeyboardCatalogSnapshot(
            schemaVersion: KeyboardCatalogSnapshot.currentSchemaVersion,
            catalogVersion: 1,
            generatedAt: Date(timeIntervalSinceReferenceDate: 800_000_000),
            activePropertyID: activeID,
            properties: properties,
            generalMessages: []
        )
    }

    @Test func snapshotRoundTripsJSON() throws {
        let snapshot = makeSnapshot(activeID: "prop-1")
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
        #expect(decoded.schemaVersion == 3)
        #expect(decoded.catalogVersion == 1)
        #expect(decoded.activePropertyID == "prop-1")
    }

    @Test func snapshotWithNullActiveID() throws {
        let snapshot = makeSnapshot(activeID: nil)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
        #expect(decoded.activePropertyID == nil)
    }

    @Test func schemaVersionIsCurrentVersion() {
        #expect(KeyboardCatalogSnapshot.currentSchemaVersion == 3)
    }

    @Test func propertiesArrayRoundTrips() throws {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let prop = makeKeyboardSafeProperty(id: "a", updatedAt: now)
        let snapshot = makeSnapshot(properties: [prop])
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
        #expect(decoded.properties.count == 1)
        #expect(decoded.properties[0].id == "a")
    }

    func makeKeyboardSafeProperty(id: String = "test", updatedAt: Date = Date()) -> KeyboardSafeProperty {
        let p = ProjectionTests_Helper.makeFullProperty(id: id)
        return KeyboardSafeProperty(projecting: p)
    }
}

private enum ProjectionTests_Helper {
    static func makeFullProperty(id: String = "test") -> Property {
        Property(
            id: id,
            internalCode: "SUN-001",
            title: "Propiedad",
            operationType: .rent,
            status: .available,
            price: 5_000,
            currency: "GTQ",
            maintenanceFee: nil,
            maintenanceIncluded: false,
            deposit: nil,
            locationSummary: "Zona 10",
            neighborhood: nil,
            city: "Guatemala",
            state: nil,
            country: "Guatemala",
            bedrooms: 2,
            bathrooms: 1,
            halfBathrooms: nil,
            parkingSpaces: 1,
            areaSquareMeters: 80,
            amenities: [],
            includedAppliances: [],
            requirements: [],
            petPolicy: .notAllowed,
            visitInstructions: nil,
            quickReplyTemplates: [],
            isFavorite: false,
            lastVerifiedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - TemplateEngine tests

@Suite("TemplateEngine — Availability")
struct TemplateEngineAvailabilityTests {

    func kp(status: PropertyStatus) -> KeyboardSafeProperty {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.status = status
        return KeyboardSafeProperty(projecting: p)
    }

    @Test func availablePropertyGivesConfirmation() {
        let text = TemplateEngine.availability(for: kp(status: .available))
        #expect(text.contains("disponible"))
        #expect(text.contains("visita"))
    }

    @Test func reservedPropertyMentionsState() {
        let text = TemplateEngine.availability(for: kp(status: .reserved))
        #expect(text.contains("reservada") || text.contains("disponible"))
    }

    @Test func rentedPropertyMentionsState() {
        let text = TemplateEngine.availability(for: kp(status: .rented))
        #expect(text.contains("rentada") || text.contains("disponible"))
    }

    @Test func soldPropertyMentionsState() {
        let text = TemplateEngine.availability(for: kp(status: .sold))
        #expect(text.contains("vendida") || text.contains("disponible"))
    }

    @Test func availableDoesNotMentionNegativeState() {
        let text = TemplateEngine.availability(for: kp(status: .available))
        #expect(!text.lowercased().contains("reservada"))
        #expect(!text.lowercased().contains("vendida"))
    }
}

@Suite("TemplateEngine — Price")
struct TemplateEnginePriceTests {

    func kp(
        operation: OperationType = .rent,
        price: Decimal = 5_000,
        fee: Decimal? = nil,
        feeIncluded: Bool = false,
        deposit: Decimal? = nil
    ) -> KeyboardSafeProperty {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = operation
        p.price = price
        p.maintenanceFee = fee
        p.maintenanceIncluded = feeIncluded
        p.deposit = deposit
        return KeyboardSafeProperty(projecting: p)
    }

    @Test func rentMentionsMensuales() {
        let text = TemplateEngine.price(for: kp(operation: .rent))
        #expect(text.contains("renta") || text.contains("mensuales"))
    }

    @Test func saleMentionsVenta() {
        let text = TemplateEngine.price(for: kp(operation: .sale))
        #expect(text.contains("venta"))
    }

    @Test func maintenanceFeeIncludedMentioned() {
        let text = TemplateEngine.price(for: kp(fee: 500, feeIncluded: true))
        #expect(text.contains("mantenimiento"))
        #expect(text.contains("incluido"))
    }

    @Test func maintenanceFeeNotIncludedMentioned() {
        let text = TemplateEngine.price(for: kp(fee: 500, feeIncluded: false))
        #expect(text.contains("mantenimiento"))
        #expect(text.contains("no incluido"))
    }

    @Test func depositMentionedForRent() {
        let text = TemplateEngine.price(for: kp(operation: .rent, deposit: 5_000))
        #expect(text.contains("depósito"))
    }

    @Test func depositNotMentionedForSale() {
        let text = TemplateEngine.price(for: kp(operation: .sale, deposit: 5_000))
        #expect(!text.contains("depósito"))
    }
}

@Suite("TemplateEngine — Location")
struct TemplateEngineLocationTests {

    @Test func locationAlwaysIncludesPublicLabel() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.publicLocationLabel = "Zona 10"
        p.isExactLocationShareable = false
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        #expect(text.contains("Zona 10"))
    }

    @Test func locationFallsBackToLabelSearchWhenNoCoordinates() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = false
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        // Always emits label-search links even without confirmed coordinates
        #expect(text.contains("maps/search") || text.contains("maps.google.com"))
        #expect(text.contains("waze.com"))
    }

    @Test func locationWithCoordinatesUsesExactLinks() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = true
        p.latitude = 14.6349
        p.longitude = -90.5069
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        #expect(text.contains("14.634900"))
        #expect(text.contains("-90.506900"))
        #expect(text.contains("waze.com/ul?ll="))
    }

    @Test func locationWithShareableURLIncludesStoredLink() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = true
        p.googleMapsURL = "https://maps.google.com?q=14.6,-90.5"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        #expect(text.contains("https://maps.google.com"))
    }

    @Test func locationWithShareableFalseUsesLabelSearchNotStoredURL() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = false
        p.googleMapsURL = "https://maps.google.com?q=14.6,-90.5"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        // Stored coordinate URL is NOT shown when isExactLocationShareable=false
        #expect(!text.contains("maps.google.com?q=14.6"))
        // Label-search IS emitted as safe fallback
        #expect(text.contains("maps/search") || text.contains("waze.com"))
    }

    @Test func locationWithStoredWazeURLUsesIt() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = false
        p.wazeURL = "https://waze.com/ul?q=Zona+10"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        #expect(text.contains("https://waze.com/ul?q=Zona+10"))
    }
}

@Suite("TemplateEngine — Pet Policy")
struct TemplateEnginePetsTests {

    @Test func allowedExactPhrase() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.petPolicy = .allowed
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(TemplateEngine.pets(for: kp) == "Se acepta mascota.")
    }

    @Test func notAllowedExactPhrase() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.petPolicy = .notAllowed
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(TemplateEngine.pets(for: kp) == "No se aceptan mascotas.")
    }

    @Test func subjectToCaseAnalysisExactPhrase() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.petPolicy = .subjectToCaseAnalysis
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(TemplateEngine.pets(for: kp) == "Sujeto a análisis de caso.")
    }
}

@Suite("TemplateEngine — Purchase Info")
struct TemplateEnginePurchaseInfoTests {

    @Test func rentalPropertyRejected() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .rent
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.purchaseInfo(for: kp)
        #expect(text.contains("únicamente"))
    }

    @Test func sellerFinancingAvailableMentioned() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .available
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.purchaseInfo(for: kp)
        #expect(text.contains("financiamiento") || text.contains("vendedor"))
    }

    @Test func fhaEligibleMentionsFHA() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .eligible
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.purchaseInfo(for: kp)
        #expect(text.contains("FHA"))
        #expect(text.contains("5%"))
    }

    @Test func fhaNotEligibleOmitsFHA() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .notEligible
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.purchaseInfo(for: kp)
        #expect(!text.contains("FHA"))
    }

    @Test func iusiMentionedWhenPresent() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.iusiAmount = Decimal(string: "1500.00")
        p.iusiFrequency = "anual"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.purchaseInfo(for: kp)
        #expect(text.contains("IUSI"))
        #expect(text.contains("anual"))
    }

    @Test func iusiOmittedWhenNil() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.iusiAmount = nil
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.purchaseInfo(for: kp)
        #expect(!text.contains("IUSI"))
    }
}

@Suite("TemplateEngine — Characteristics")
struct TemplateEngineCharacteristicsTests {

    @Test func includesBedroomCount() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.bedrooms = 3
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.characteristics(for: kp)
        #expect(text.contains("3"))
        #expect(text.contains("recámara"))
    }

    @Test func includesArea() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.areaSquareMeters = 120
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.characteristics(for: kp)
        #expect(text.contains("120"))
        #expect(text.contains("m²"))
    }
}

@Suite("TemplateEngine — Follow-Up")
struct TemplateEngineFollowUpTests {

    @Test func greetingPresent() {
        let p = ProjectionTests_Helper.makeFullProperty()
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.followUp(for: kp, employeeName: nil)
        let hasGreeting = text.hasPrefix("Buenos días") || text.hasPrefix("Buenas tardes") || text.hasPrefix("Buenas noches")
        #expect(hasGreeting)
    }

    @Test func employeeNameIncludedWhenProvided() {
        let p = ProjectionTests_Helper.makeFullProperty()
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.followUp(for: kp, employeeName: "Yessy")
        #expect(text.contains("Yessy"))
    }

    @Test func genericMessageWhenNoEmployee() {
        let p = ProjectionTests_Helper.makeFullProperty()
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.followUp(for: kp, employeeName: nil)
        #expect(text.contains("Sunsets Real Estate"))
        #expect(!text.contains("soy"))
    }
}

@Suite("TemplateEngine — Generate Dispatcher")
struct TemplateEngineDispatcherTests {

    func kp() -> KeyboardSafeProperty {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.status = .available
        return KeyboardSafeProperty(projecting: p)
    }

    @Test func dispatchesAvailability() {
        let text = TemplateEngine.generate(category: .availability, for: kp())
        #expect(text.contains("disponible"))
    }

    @Test func dispatchesPrice() {
        let text = TemplateEngine.generate(category: .price, for: kp())
        #expect(text.contains("venta") || text.contains("precio"))
    }

    @Test func dispatchesPets() {
        let text = TemplateEngine.generate(category: .petPolicy, for: kp())
        let valid = ["Se acepta mascota.", "No se aceptan mascotas.", "Sujeto a análisis de caso."]
        let isOneOf = valid.contains { text.hasPrefix($0) || text == $0 } || text.contains("confirmar")
        #expect(isOneOf)
    }

    @Test func dispatchesPurchaseInfo() {
        let text = TemplateEngine.generate(category: .purchaseInfo, for: kp())
        #expect(text.contains("venta") || text.contains("financiamiento") || text.contains("únicamente"))
    }

    @Test func purchaseInfoOmittedForRental() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .rent
        let kpRent = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generate(category: .purchaseInfo, for: kpRent)
        #expect(text.contains("únicamente") || text.contains("aplica"))
    }
}

// MARK: - IUSI model tests

@Suite("IUSI Fields")
struct IUSIFieldTests {

    @Test func iusiFieldsRoundTripJSON() throws {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.iusiAmount = Decimal(string: "2500.00")
        p.iusiFrequency = "anual"
        p.iusiNotes = "Pagado al día"
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(p)
        let decoded = try decoder.decode(Property.self, from: data)
        #expect(decoded.iusiAmount == Decimal(string: "2500.00"))
        #expect(decoded.iusiFrequency == "anual")
        #expect(decoded.iusiNotes == "Pagado al día")
    }

    @Test func iusiFieldsDefaultToNilInLegacyJSON() throws {
        let json = #"""
        {"id":"x","internalCode":"SUN-001","title":"T","operationType":"sale","status":"available",
         "price":1000000,"currency":"GTQ","maintenanceIncluded":false,"locationSummary":"Z","country":"Guatemala",
         "bedrooms":3,"bathrooms":2.0,"amenities":[],"includedAppliances":[],"requirements":[],
         "petPolicy":"notAllowed","quickReplyTemplates":[],"isFavorite":false,
         "createdAt":"2025-01-01T00:00:00Z","updatedAt":"2025-01-01T00:00:00Z"}
        """#.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let p = try decoder.decode(Property.self, from: json)
        #expect(p.iusiAmount == nil)
        #expect(p.iusiFrequency == nil)
        #expect(p.iusiVerifiedAt == nil)
        #expect(p.iusiNotes == nil)
    }

    @Test func projectionCopiesIUSIFields() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.operationType = .sale
        p.iusiAmount = Decimal(string: "1800.00")
        p.iusiFrequency = "semestral"
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.iusiAmount == Decimal(string: "1800.00"))
        #expect(kp.iusiFrequency == "semestral")
    }
}

// MARK: - Location sharing round-trip tests

@Suite("LocationSharing")
struct LocationSharingTests {

    private func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }
    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }

    @Test func wazeURLRoundTripsInProperty() throws {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.wazeURL = "https://waze.com/ul?ll=14.634900,-90.506900&navigate=yes"
        let data = try makeEncoder().encode(p)
        let decoded = try makeDecoder().decode(Property.self, from: data)
        #expect(decoded.wazeURL == "https://waze.com/ul?ll=14.634900,-90.506900&navigate=yes")
    }

    @Test func wazeURLDefaultsToNilInLegacyJSON() throws {
        let json = #"""
        {"id":"x","internalCode":"SUN-001","title":"T","operationType":"rent","status":"available",
         "price":5000,"currency":"GTQ","maintenanceIncluded":false,"locationSummary":"Zona 10",
         "country":"Guatemala","bedrooms":2,"bathrooms":1.0,"amenities":[],"includedAppliances":[],
         "requirements":[],"petPolicy":"notAllowed","quickReplyTemplates":[],"isFavorite":false,
         "createdAt":"2025-01-01T00:00:00Z","updatedAt":"2025-01-01T00:00:00Z"}
        """#.data(using: .utf8)!
        let p = try makeDecoder().decode(Property.self, from: json)
        #expect(p.wazeURL == nil)
    }

    @Test func wazeURLProjectedToKeyboardSafeProperty() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.wazeURL = "https://waze.com/ul?q=Zona%2010"
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.wazeURL == "https://waze.com/ul?q=Zona%2010")
    }

    @Test func googleMapsURLProjectedToKeyboardSafeProperty() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.googleMapsURL = "https://www.google.com/maps?q=14.634900,-90.506900"
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.googleMapsURL == "https://www.google.com/maps?q=14.634900,-90.506900")
    }

    @Test func publicLocationLabelProjectedToKeyboardSafeProperty() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.publicLocationLabel = "Zona 10, Ciudad de Guatemala"
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.publicLocationLabel == "Zona 10, Ciudad de Guatemala")
    }

    @Test func snapshotRoundTripsWazeURL() throws {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.wazeURL = "https://waze.com/ul?ll=14.634900,-90.506900&navigate=yes"
        p.isExactLocationShareable = true
        p.latitude = 14.6349
        p.longitude = -90.5069
        let kp = KeyboardSafeProperty(projecting: p)
        let snapshot = KeyboardCatalogSnapshot(
            schemaVersion: KeyboardCatalogSnapshot.currentSchemaVersion,
            catalogVersion: 1,
            generatedAt: Date(timeIntervalSinceReferenceDate: 800_000_000),
            activePropertyID: nil,
            properties: [kp],
            generalMessages: []
        )
        let data = try makeEncoder().encode(snapshot)
        let decoded = try makeDecoder().decode(KeyboardCatalogSnapshot.self, from: data)
        #expect(decoded.properties.first?.wazeURL == "https://waze.com/ul?ll=14.634900,-90.506900&navigate=yes")
    }

    @Test func locationTemplateWithCoordinatesEmitsBothLinks() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = true
        p.latitude = 14.6349
        p.longitude = -90.5069
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        #expect(text.contains("maps/search") || text.contains("maps.google.com"))
        #expect(text.contains("waze.com/ul?ll="))
    }

    @Test func locationTemplateWithPublicLabelUsesItInHeader() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.publicLocationLabel = "Zona 14, Guatemala"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        #expect(text.contains("📍 Ubicación: Zona 14, Guatemala"))
    }

    @Test func locationTemplateFallsBackToSearchWhenNoCoords() {
        var p = ProjectionTests_Helper.makeFullProperty()
        p.isExactLocationShareable = false
        p.publicLocationLabel = "Zona 10"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.location(for: kp)
        // Label is encoded into search URLs
        #expect(text.contains("Zona"))
        #expect(text.contains("maps/search") || text.contains("waze.com"))
    }

    @Test func generalInfoOmitsMapsLinksAndRequirements() {
        // Location and requirements belong in their own keyboard buttons, never in General Info
        var p = ProjectionTests_Helper.makeFullProperty()
        p.publicLocationLabel = "Zona 10"
        p.isExactLocationShareable = true
        p.latitude = 14.6349
        p.longitude = -90.5069
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(!text.contains("maps/search"))
        #expect(!text.contains("maps.google.com"))
        #expect(!text.contains("waze.com"))
        #expect(!text.contains("Requisitos:"))
        #expect(text.contains("Precio:"))
    }
}

// MARK: - General Info template tests

@Suite("TemplateEngine — General Info")
struct TemplateEngineGeneralInfoTests {

    private func makeProperty() -> Property {
        ProjectionTests_Helper.makeFullProperty()
    }

    // MARK: Listing-text path

    @Test func generalInfoUsesListingTextAsMainBody() {
        var p = makeProperty()
        p.publicListingText = "Hermoso apartamento en Zona 10 con acabados de lujo."
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("Hermoso apartamento en Zona 10 con acabados de lujo."))
    }

    @Test func generalInfoDoesNotAppendRequirementsWhenListingPresent() {
        var p = makeProperty()
        p.publicListingText = "Apartamento disponible en Zona 14."
        p.requirements = ["Fiador", "3 meses de garantía"]
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(!text.contains("Requisitos:"))
        #expect(!text.contains("Fiador"))
    }

    @Test func generalInfoDoesNotAppendMapsLinksWhenListingPresent() {
        var p = makeProperty()
        p.publicListingText = "Casa en venta en Zona 15."
        p.isExactLocationShareable = true
        p.latitude = 14.6349
        p.longitude = -90.5069
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        // Location links belong in the Location button only
        #expect(!text.contains("maps/search"))
        #expect(!text.contains("maps.google.com"))
        #expect(!text.contains("waze.com"))
    }

    @Test func generalInfoAppendsPriceWhenAbsentFromListing() {
        var p = makeProperty()
        p.publicListingText = "Lindo apartamento ideal para profesionales."
        p.price = 6_500
        p.currency = "GTQ"
        p.operationType = .rent
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("Precio:"))
        #expect(text.contains("mensuales"))
    }

    @Test func generalInfoDoesNotDuplicatePriceWhenAlreadyInListing() {
        var p = makeProperty()
        p.publicListingText = "Apartamento. Precio Q 6,500.00 mensuales. Excelente ubicación."
        p.price = 6_500
        p.currency = "GTQ"
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        // "precio" keyword is in listing → should not add a second Precio: block
        let priceCount = text.components(separatedBy: "Precio:").count - 1
        #expect(priceCount == 0)
    }

    // MARK: Structured-fields path (no listing text)

    @Test func generalInfoDoesNotAppendRequirementsWhenNoListing() {
        var p = makeProperty()
        p.requirements = ["Fiador", "2 meses de garantía"]
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(!text.contains("Requisitos:"))
        #expect(!text.contains("Fiador"))
    }

    @Test func generalInfoDoesNotAppendMapsLinksWhenNoListing() {
        var p = makeProperty()
        p.isExactLocationShareable = true
        p.latitude = 14.6349
        p.longitude = -90.5069
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(!text.contains("maps/search"))
        #expect(!text.contains("maps.google.com"))
        #expect(!text.contains("waze.com"))
    }

    @Test func generalInfoBuildsCharacteristicsFromStructuredFields() {
        var p = makeProperty()
        p.bedrooms = 3
        p.bathrooms = 2
        p.parkingSpaces = 1
        p.areaSquareMeters = 120
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("3"))
        #expect(text.contains("recámara"))
        #expect(text.contains("120") || text.contains("m²"))
    }

    @Test func generalInfoIncludesAmenitiesWhenNoListing() {
        var p = makeProperty()
        p.amenities = ["Piscina", "Gimnasio"]
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("Amenidades:"))
        #expect(text.contains("Piscina"))
        #expect(text.contains("Gimnasio"))
    }

    @Test func generalInfoIncludesIncludedItemsWhenNoListing() {
        var p = makeProperty()
        p.includedAppliances = ["Estufa", "Refrigeradora"]
        p.includedItems = ["Escritorio"]
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("Incluye:"))
        #expect(text.contains("Estufa"))
        #expect(text.contains("Escritorio"))
    }

    @Test func generalInfoIncludesExcludedItemsWhenNoListing() {
        var p = makeProperty()
        p.excludedItems = ["Cortinas", "Línea blanca"]
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("No incluye:"))
        #expect(text.contains("Cortinas"))
    }

    @Test func generalInfoShowsStatusWarningForUnavailableProperty() {
        var p = makeProperty()
        p.status = .reserved
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(text.contains("⚠️"))
        #expect(text.contains("disponible"))
    }

    @Test func generalInfoDoesNotShowStatusWarningWhenAvailable() {
        var p = makeProperty()
        p.status = .available
        let kp = KeyboardSafeProperty(projecting: p)
        let text = TemplateEngine.generalInfo(for: kp)
        #expect(!text.contains("⚠️"))
    }
}
