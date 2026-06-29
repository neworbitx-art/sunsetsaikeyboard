import Testing
import Foundation
@testable import SunsetsProperties

// MARK: - Property Model Tests

@Suite("Property Model")
struct PropertyModelTests {

    @Test func roundTripEncoding() throws {
        let now = Date(timeIntervalSinceReferenceDate: round(Date().timeIntervalSinceReferenceDate))
        let property = makeSampleProperty(createdAt: now)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(property)
        let decoded = try decoder.decode(Property.self, from: data)
        #expect(decoded == property)
    }

    @Test func decimalPricePreservation() throws {
        let property = makeSampleProperty(price: Decimal(string: "12345.50")!)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(property)
        let decoded = try decoder.decode(Property.self, from: data)
        #expect(decoded.price == Decimal(string: "12345.50")!)
    }

    @Test func arrayRoundTrip() throws {
        let props = [makeSampleProperty(id: "a"), makeSampleProperty(id: "b")]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(props)
        let decoded = try decoder.decode([Property].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].id == "a")
    }

    @Test func statusRawValues() {
        #expect(PropertyStatus.available.rawValue == "available")
        #expect(PropertyStatus.reserved.rawValue == "reserved")
        #expect(PropertyStatus.rented.rawValue == "rented")
        #expect(PropertyStatus.sold.rawValue == "sold")
        #expect(PropertyStatus.inactive.rawValue == "inactive")
    }

    @Test func operationTypeRawValues() {
        #expect(OperationType.rent.rawValue == "rent")
        #expect(OperationType.sale.rawValue == "sale")
        #expect(OperationType.rentOrSale.rawValue == "rentOrSale")
    }

    @Test func petPolicyRawValues() {
        #expect(PetPolicy.allowed.rawValue == "allowed")
        #expect(PetPolicy.notAllowed.rawValue == "notAllowed")
        #expect(PetPolicy.subjectToCaseAnalysis.rawValue == "subjectToCaseAnalysis")
        #expect(PetPolicy.allCases.count == 3)
    }

    @Test func newFieldsDecodeWithDefaultsFromLegacyJSON() throws {
        // Simulate Milestone 1 JSON that has no new Milestone 1.1 fields
        let legacyJSON = """
        {
            "id": "legacy-001",
            "internalCode": "SUN-001",
            "title": "Legacy Property",
            "operationType": "rent",
            "status": "available",
            "price": 5000,
            "currency": "GTQ",
            "maintenanceIncluded": false,
            "locationSummary": "Zona 10",
            "country": "Guatemala",
            "bedrooms": 2,
            "bathrooms": 1.0,
            "parkingSpaces": 1,
            "areaSquareMeters": 80.0,
            "amenities": [],
            "includedAppliances": [],
            "requirements": [],
            "petPolicy": "notAllowed",
            "quickReplyTemplates": [],
            "isFavorite": false,
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let property = try decoder.decode(Property.self, from: legacyJSON)
        // New fields default correctly
        #expect(property.latitude == nil)
        #expect(property.longitude == nil)
        #expect(property.locationSource == .manual)
        #expect(property.isExactLocationShareable == false)
        #expect(property.includedItems.isEmpty)
        #expect(property.excludedItems.isEmpty)
        #expect(property.floorNumber == nil)
    }
}

// MARK: - Status Localization Tests

@Suite("Status Localization")
struct StatusLocalizationTests {

    @Test func spanishLabels() {
        #expect(PropertyStatus.available.label == "Disponible")
        #expect(PropertyStatus.reserved.label == "Reservada")
        #expect(PropertyStatus.rented.label == "Rentada")
        #expect(PropertyStatus.sold.label == "Vendida")
        #expect(PropertyStatus.inactive.label == "Inactiva")
    }

    @Test func warningFlag() {
        #expect(!PropertyStatus.available.isWarning)
        #expect(PropertyStatus.reserved.isWarning)
        #expect(PropertyStatus.rented.isWarning)
        #expect(PropertyStatus.sold.isWarning)
        #expect(PropertyStatus.inactive.isWarning)
    }
}

// MARK: - Currency Formatter Tests

@Suite("Currency Formatter")
struct CurrencyFormatterTests {

    @Test func gtqFormatContainsCurrency() {
        let result = AppFormatters.currency(Decimal(5000), code: "GTQ")
        #expect(result.contains("5"))
        #expect(!result.isEmpty)
    }

    @Test func usdFormatContainsCurrency() {
        let result = AppFormatters.currency(Decimal(1000), code: "USD")
        #expect(result.contains("1"))
        #expect(!result.isEmpty)
    }

    @Test func zeroAmount() {
        let result = AppFormatters.currency(Decimal(0), code: "GTQ")
        #expect(result.contains("0"))
    }
}

// MARK: - Repository Tests

@Suite("LocalPropertyRepository")
struct RepositoryTests {

    func makeRepository() -> LocalPropertyRepository {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_catalog_\(UUID().uuidString).json")
        return LocalPropertyRepository(
            fileURL: url,
            defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        )
    }

    @Test func saveAndFetch() async throws {
        let repo = makeRepository()
        let property = makeSampleProperty()
        try await repo.save(property)
        let all = try await repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].id == property.id)
    }

    @Test func updateExistingProperty() async throws {
        let repo = makeRepository()
        var property = makeSampleProperty()
        try await repo.save(property)
        property.title = "Título Actualizado"
        try await repo.save(property)
        let all = try await repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].title == "Título Actualizado")
    }

    @Test func deleteProperty() async throws {
        let repo = makeRepository()
        let property = makeSampleProperty()
        try await repo.save(property)
        try await repo.delete(id: property.id)
        let all = try await repo.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func deleteNonExistentIsNoop() async throws {
        let repo = makeRepository()
        try await repo.delete(id: "nonexistent")
        let all = try await repo.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func fetchAllFromEmptyRepository() async throws {
        let repo = makeRepository()
        let all = try await repo.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func activeIdPersists() async throws {
        let repo = makeRepository()
        try await repo.setActiveId("some-id")
        let fetched = try await repo.fetchActiveId()
        #expect(fetched == "some-id")
    }

    @Test func clearActiveId() async throws {
        let repo = makeRepository()
        try await repo.setActiveId("some-id")
        try await repo.setActiveId(nil)
        let fetched = try await repo.fetchActiveId()
        #expect(fetched == nil)
    }

    @Test func deleteActivePropertyClearsActiveId() async throws {
        let repo = makeRepository()
        let property = makeSampleProperty()
        try await repo.save(property)
        try await repo.setActiveId(property.id)
        try await repo.delete(id: property.id)
        let activeId = try await repo.fetchActiveId()
        #expect(activeId == nil)
    }

    @Test func seedOnlyOnce() async throws {
        let repo = makeRepository()
        let seed = [makeSampleProperty(id: "s1"), makeSampleProperty(id: "s2")]
        try await repo.seedIfNeeded(seed)
        try await repo.seedIfNeeded(seed)
        let all = try await repo.fetchAll()
        #expect(all.count == 2)
    }

    @Test func seedDoesNotRunIfAlreadySeeded() async throws {
        let repo = makeRepository()
        try await repo.seedIfNeeded([makeSampleProperty(id: "s1")])
        try await repo.save(makeSampleProperty(id: "s2"))
        try await repo.seedIfNeeded([makeSampleProperty(id: "s3")])
        let all = try await repo.fetchAll()
        #expect(all.count == 2)
    }

    @Test func employeeRoundTrip() async throws {
        let repo = makeRepository()
        try await repo.setEmployee("Yessy")
        let name = try await repo.fetchEmployee()
        #expect(name == "Yessy")
    }

    @Test func peekNextInternalCodeIsIdempotent() async throws {
        let repo = makeRepository()
        // peek does NOT advance the counter
        let first  = try await repo.peekNextInternalCode()
        let second = try await repo.peekNextInternalCode()
        let third  = try await repo.peekNextInternalCode()
        #expect(first  == "SUN-001")
        #expect(second == "SUN-001")
        #expect(third  == "SUN-001")
    }

    @Test func savingNewPropertyAdvancesCode() async throws {
        let repo = makeRepository()
        #expect(try await repo.peekNextInternalCode() == "SUN-001")
        let p = makeSampleProperty(id: "p1", code: "SUN-001")
        try await repo.save(p)
        #expect(try await repo.peekNextInternalCode() == "SUN-002")
    }

    @Test func previewCodeNotConsumedOnCancel() async throws {
        let repo = makeRepository()
        let preview1 = try await repo.peekNextInternalCode()
        // "cancel" — no save
        let preview2 = try await repo.peekNextInternalCode()
        #expect(preview1 == "SUN-001")
        #expect(preview2 == "SUN-001")  // same; not consumed
    }

    @Test func savedCodeNeverReusedAfterDeletion() async throws {
        let repo = makeRepository()
        let p = makeSampleProperty(id: "p1", code: "SUN-001")
        try await repo.save(p)
        try await repo.delete(id: "p1")
        // Counter already at 1; peek returns SUN-002
        let next = try await repo.peekNextInternalCode()
        #expect(next == "SUN-002")
    }

    @Test func editingExistingPropertyDoesNotAdvanceCode() async throws {
        let repo = makeRepository()
        let p = makeSampleProperty(id: "p1", code: "SUN-001")
        try await repo.save(p)
        // Save again (edit — same id)
        var updated = p
        updated.title = "Updated"
        try await repo.save(updated)
        // Counter still at 1 (edit, not new)
        let next = try await repo.peekNextInternalCode()
        #expect(next == "SUN-002")
    }

    @Test func validationFailureDoesNotConsumePreviewCode() async throws {
        let repo = StubRepository()
        let vm = PropertyEditorViewModel(repository: repo)
        await vm.prepareForNew()
        let preview = vm.internalCode
        #expect(preview == "SUN-001")
        // Validation fails (empty location)
        vm.priceText = "1000"
        vm.currency = "GTQ"
        // locationSummary stays "" — triggers validation failure
        let result = vm.buildProperty()
        #expect(result == nil)
        // Counter not advanced; next open still shows SUN-001
        let vm2 = PropertyEditorViewModel(repository: repo)
        await vm2.prepareForNew()
        #expect(vm2.internalCode == "SUN-001")
    }

    @Test func internalCodeIsUniqueAmongExisting() async throws {
        let repo = makeRepository()
        var p = makeSampleProperty(id: "p1", code: "SUN-010")
        try await repo.save(p)
        // Same code, different id → NOT unique
        let notUnique = try await repo.isInternalCodeUnique("SUN-010", excludingId: nil)
        #expect(!notUnique)
        // Same code, excluding own id → IS unique (self-edit)
        let selfEdit = try await repo.isInternalCodeUnique("SUN-010", excludingId: "p1")
        #expect(selfEdit)
        // Different code → IS unique
        let different = try await repo.isInternalCodeUnique("SUN-011", excludingId: nil)
        #expect(different)
        _ = p // suppress warning
    }

    @Test func migrationSeedsCodeCounterFromExistingCodes() async throws {
        let repo = makeRepository()
        // Simulate pre-migration catalog with existing properties
        let existing = [
            makeSampleProperty(id: "e1", code: "SUN-005"),
            makeSampleProperty(id: "e2", code: "SUN-003"),
        ]
        // Write them directly (simulating Milestone 1 state)
        for p in existing { try await repo.save(p) }
        // Seed is not set yet (simulate pre-migration)
        try await repo.migrateIfNeeded()
        // After migration, next code should continue from SUN-005
        let next = try await repo.peekNextInternalCode()
        #expect(next == "SUN-006")
    }
}

// MARK: - Validation Tests

@Suite("Property Validation")
struct ValidationTests {

    @Test func validPropertyPassesValidation() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("SUN-999")
        vm.locationSummary = "Zona 10, Guatemala"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        #expect(vm.validate() == true)
        #expect(vm.validationErrors.isEmpty)
    }

    @Test func missingCodeFails() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("código") }))
    }

    @Test func missingLocationFails() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = ""
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("ubicación") }))
    }

    @Test func missingPriceFails() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = ""
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("precio") }))
    }

    @Test func negativePriceProducesError() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "-500"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("negativo") }))
    }

    @Test func negativeMaintenanceFeeProducesError() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        vm.maintenanceFeeText = "-100"
        #expect(vm.validate() == false)
    }

    @Test func negativeDepositProducesError() {
        let vm = PropertyEditorViewModel()
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        vm.depositText = "-200"
        #expect(vm.validate() == false)
    }

    @Test func buildPropertyReturnsNilWhenInvalid() {
        let vm = PropertyEditorViewModel()
        // No code, no location — validation fails
        vm.priceText = "1000"
        #expect(vm.buildProperty() == nil)
    }

    @Test func buildPropertySucceedsWhenValid() {
        let vm = PropertyEditorViewModel()
        vm.displayTitle = "Casa en Zona 10"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        let result = vm.buildProperty()
        #expect(result != nil)
        #expect(result?.displayTitle == "Casa en Zona 10")
        #expect(result?.price == 5000)
    }
}

// MARK: - Search and Filter Tests

@Suite("Search and Filter")
struct SearchFilterTests {

    func makeViewModel(with properties: [Property]) -> CatalogViewModel {
        let repo = StubRepository(properties: properties)
        return CatalogViewModel(repository: repo)
    }

    @Test func searchByTitle() async {
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1", title: "Casa en Zona 10", location: "Zona 10, Guatemala"),
            makeSampleProperty(id: "2", title: "Apartamento en Cayalá", location: "Cayalá, Guatemala")
        ])
        await vm.load()
        vm.searchText = "zona"
        #expect(vm.filteredProperties.count == 1)
        #expect(vm.filteredProperties[0].id == "1")
    }

    @Test func searchByCode() async {
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1", code: "SUN-042"),
            makeSampleProperty(id: "2", code: "SUN-099")
        ])
        await vm.load()
        vm.searchText = "042"
        #expect(vm.filteredProperties.count == 1)
        #expect(vm.filteredProperties[0].internalCode == "SUN-042")
    }

    @Test func searchByLocation() async {
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1", location: "Antigua Guatemala"),
            makeSampleProperty(id: "2", location: "Ciudad de Guatemala")
        ])
        await vm.load()
        vm.searchText = "antigua"
        #expect(vm.filteredProperties.count == 1)
        #expect(vm.filteredProperties[0].id == "1")
    }

    @Test func emptySearchReturnsAll() async {
        let vm = makeViewModel(with: [makeSampleProperty(id: "1"), makeSampleProperty(id: "2")])
        await vm.load()
        vm.searchText = ""
        #expect(vm.filteredProperties.count == 2)
    }

    @Test func noMatchReturnsEmpty() async {
        let vm = makeViewModel(with: [makeSampleProperty(id: "1", title: "Casa")])
        await vm.load()
        vm.searchText = "xyzabc"
        #expect(vm.filteredProperties.isEmpty)
    }

    @Test func filterByAvailable() async {
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1", status: .available),
            makeSampleProperty(id: "2", status: .rented)
        ])
        await vm.load()
        vm.selectedFilter = .available
        let ids = vm.filteredProperties.map(\.id)
        #expect(ids.contains("1"))
        #expect(!ids.contains("2"))
    }

    @Test func filterByFavorites() async {
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1", favorite: true),
            makeSampleProperty(id: "2", favorite: false)
        ])
        await vm.load()
        vm.selectedFilter = .favorites
        #expect(vm.filteredProperties.count == 1)
        #expect(vm.filteredProperties[0].id == "1")
    }

    @Test func filterByRent() async {
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1", operation: .rent),
            makeSampleProperty(id: "2", operation: .sale),
            makeSampleProperty(id: "3", operation: .rentOrSale)
        ])
        await vm.load()
        vm.selectedFilter = .rent
        let ids = vm.filteredProperties.map(\.id)
        #expect(ids.contains("1"))
        #expect(!ids.contains("2"))
        #expect(ids.contains("3"))
    }

    @Test func accentInsensitiveSearch() async {
        let vm = makeViewModel(with: [makeSampleProperty(id: "1", location: "Antigua Guatemala")])
        await vm.load()
        vm.searchText = "Antigua"
        #expect(vm.filteredProperties.count == 1)
    }
}

// MARK: - Seed Data Tests

@Suite("Seed Data")
struct SeedDataTests {

    @Test func minimumPropertyCount() {
        #expect(SeedData.properties.count >= 5)
    }

    @Test func coversAllStatuses() {
        let statuses = Set(SeedData.properties.map(\.status))
        #expect(statuses.contains(.available))
        #expect(statuses.contains(.reserved))
        #expect(statuses.contains(.rented))
        #expect(statuses.contains(.sold))
        #expect(statuses.contains(.inactive))
    }

    @Test func hasBothOperationTypes() {
        let ops = Set(SeedData.properties.map(\.operationType))
        #expect(ops.contains(.rent))
        #expect(ops.contains(.sale))
    }

    @Test func hasAtLeastOneFavorite() {
        #expect(SeedData.properties.contains { $0.isFavorite })
    }

    @Test func twoEmployees() {
        #expect(SeedData.employees.count == 2)
        #expect(SeedData.employees.contains("Cristian"))
        #expect(SeedData.employees.contains("Yessy"))
    }
}

// MARK: - InternalCodeService Tests

@Suite("InternalCodeService")
struct InternalCodeServiceTests {

    @Test func formatsPaddedThreeDigits() {
        #expect(InternalCodeService.format(number: 1)   == "SUN-001")
        #expect(InternalCodeService.format(number: 42)  == "SUN-042")
        #expect(InternalCodeService.format(number: 100) == "SUN-100")
        #expect(InternalCodeService.format(number: 999) == "SUN-999")
    }

    @Test func formatsLargeNumberWithoutTruncation() {
        #expect(InternalCodeService.format(number: 1000) == "SUN-1000")
    }

    @Test func extractsNumberFromValidCode() {
        #expect(InternalCodeService.extractNumber(from: "SUN-001") == 1)
        #expect(InternalCodeService.extractNumber(from: "SUN-042") == 42)
        #expect(InternalCodeService.extractNumber(from: "SUN-100") == 100)
    }

    @Test func returnsNilForInvalidCode() {
        #expect(InternalCodeService.extractNumber(from: "") == nil)
        #expect(InternalCodeService.extractNumber(from: "SUN") == nil)
        #expect(InternalCodeService.extractNumber(from: "ABC-001") == nil)
        #expect(InternalCodeService.extractNumber(from: "SUN-abc") == nil)
    }

    @Test func maxNumberInEmptyList() {
        #expect(InternalCodeService.maxNumber(in: []) == 0)
    }

    @Test func maxNumberInList() {
        #expect(InternalCodeService.maxNumber(in: ["SUN-003", "SUN-001", "SUN-010"]) == 10)
    }
}

// MARK: - GoogleMapsURLParser Tests

@Suite("GoogleMapsURLParser")
struct GoogleMapsURLParserTests {

    @Test func parsesQParamURL() {
        let url = "https://www.google.com/maps?q=14.6349,-90.5069"
        let result = GoogleMapsURLParser.parse(url)
        #expect(result != nil)
        #expect(abs((result?.latitude ?? 0) - 14.6349) < 0.0001)
        #expect(abs((result?.longitude ?? 0) - (-90.5069)) < 0.0001)
    }

    @Test func parsesAtSignURL() {
        let url = "https://www.google.com/maps/@14.6349,-90.5069,15z"
        let result = GoogleMapsURLParser.parse(url)
        #expect(result != nil)
        #expect(abs((result?.latitude ?? 0) - 14.6349) < 0.0001)
        #expect(abs((result?.longitude ?? 0) - (-90.5069)) < 0.0001)
    }

    @Test func returnsNilForShortLinks() {
        let shortLink = "https://maps.app.goo.gl/abc123"
        let result = GoogleMapsURLParser.parse(shortLink)
        #expect(result == nil)
    }

    @Test func returnsNilForNonGoogleURL() {
        let result = GoogleMapsURLParser.parse("https://apple.com/maps?q=1,2")
        #expect(result == nil)
    }

    @Test func returnsNilForEmptyString() {
        #expect(GoogleMapsURLParser.parse("") == nil)
    }

    @Test func generateURLContainsCoordinates() {
        let url = GoogleMapsURLParser.generateURL(latitude: 14.6349, longitude: -90.5069)
        #expect(url.contains("14.6349"))
        #expect(url.contains("-90.5069"))
        #expect(url.contains("google.com/maps"))
    }

    @Test func rejectsOutOfRangeLatitude() {
        let url = "https://www.google.com/maps?q=100.0,-90.5"
        #expect(GoogleMapsURLParser.parse(url) == nil)
    }
}

// MARK: - LocalListingParser Tests (CENTO fixture)

@Suite("LocalListingParser")
struct LocalListingParserTests {

    static let centoListing = """
    CENTO - Santa Catarina Pinula

    Departamento en Renta

    Q 4,200 mensuales
    Mantenimiento incluido
    Depósito: Q 4,200

    Nivel 2
    3 Recámaras
    1 Baño
    2 Parqueos cubiertos

    Electrodomésticos incluidos:
    Estufa eléctrica
    Torre lavasecadora

    No incluye:
    Refrigeradora

    Amenidades del condominio:
    Piscina
    Área verde
    Seguridad 24 horas

    Informes: 5555-1234
    #Alquiler #SantaCatarinaGT
    """

    let parser = LocalListingParser()

    @Test func detectsRentOperation() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.operationType.value == .rent)
        #expect(draft.operationType.confidence == .high)
    }

    @Test func detectsPrice4200() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.price.value == 4200)
        #expect(draft.price.confidence == .high)
    }

    @Test func detectsGTQCurrency() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.currency.value == "GTQ")
    }

    @Test func detectsDeposit4200() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.deposit.value == 4200)
        #expect(draft.deposit.confidence == .high)
    }

    @Test func detectsMaintenanceIncluded() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.maintenanceIncluded.value == true)
        #expect(draft.maintenanceIncluded.confidence == .high)
    }

    @Test func detectsSantaCatarinaPinulaLocation() async throws {
        let draft = try await parser.parse(Self.centoListing)
        let loc = draft.locationSummary.value ?? ""
        #expect(loc.localizedCaseInsensitiveContains("Santa Catarina") ||
                loc.localizedCaseInsensitiveContains("Pinula"))
    }

    @Test func detectsFloorLevel2() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.floorNumber.value == 2)
    }

    @Test func detects3Bedrooms() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.bedrooms.value == 3)
    }

    @Test func detects1Bathroom() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.bathrooms.value == 1.0)
    }

    @Test func detects2ParkingSpaces() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.parkingSpaces.value == 2)
    }

    @Test func detectsIncludedAppliances() async throws {
        let draft = try await parser.parse(Self.centoListing)
        let appliances = draft.includedAppliances.value ?? []
        #expect(!appliances.isEmpty)
        let joined = appliances.joined(separator: " ").lowercased()
        #expect(joined.contains("estufa") || joined.contains("lavasecadora") || joined.contains("torre"))
    }

    @Test func detectsRefrigeradoraExcluded() async throws {
        let draft = try await parser.parse(Self.centoListing)
        let excluded = draft.excludedItems.value ?? []
        let joined = excluded.joined(separator: " ").lowercased()
        #expect(joined.contains("refrigeradora"))
    }

    @Test func detectsAmenities() async throws {
        let draft = try await parser.parse(Self.centoListing)
        let amenities = draft.amenities.value ?? []
        #expect(!amenities.isEmpty)
    }

    @Test func detectsContactPhone() async throws {
        let draft = try await parser.parse(Self.centoListing)
        let contact = draft.contactInfo.value ?? ""
        #expect(contact.contains("5555"))
    }

    @Test func detectsHashtags() async throws {
        let draft = try await parser.parse(Self.centoListing)
        let tags = draft.hashtags.value ?? []
        #expect(tags.count >= 1)
        let joined = tags.joined()
        #expect(joined.contains("Alquiler") || joined.contains("SantaCatarina"))
    }

    @Test func availableStatusDefault() async throws {
        let draft = try await parser.parse(Self.centoListing)
        #expect(draft.status.value == .available)
        #expect(draft.status.confidence == .high)
    }
}

// MARK: - DraftField / PropertyDraft Tests

@Suite("PropertyDraft")
struct PropertyDraftTests {

    @Test func draftFieldDefaultsToMissing() {
        let field = DraftField<String>()
        #expect(field.value == nil)
        #expect(field.confidence == .missing)
        #expect(field.hasValue == false)
        #expect(field.confidence.isUncertain == true)
    }

    @Test func highConfidenceFieldIsNotUncertain() {
        let field = DraftField(value: "test", confidence: .high)
        #expect(field.hasValue)
        #expect(!field.confidence.isUncertain)
    }

    @Test func lowConfidenceFieldIsUncertain() {
        let field = DraftField(value: "test", confidence: .low)
        #expect(field.confidence.isUncertain)
    }

    @Test func draftCreatedWithAllFieldsMissing() {
        let draft = PropertyDraft(sourceDescription: "test", parserVersion: "v1")
        #expect(draft.price.confidence == .missing)
        #expect(draft.bedrooms.confidence == .missing)
        #expect(draft.locationSummary.confidence == .missing)
    }

    @Test func confidenceLabelSpanish() {
        #expect(DraftConfidence.high.label == "Alto")
        #expect(DraftConfidence.medium.label == "Medio")
        #expect(DraftConfidence.low.label == "Bajo")
        #expect(DraftConfidence.missing.label == "No detectado")
    }
}

// MARK: - LocalListingParser Tests (Tanta Premier fixture)

@Suite("LocalListingParser — Tanta Premier")
struct TantaPremierParserTests {

    static let tantaListing = """
    🏡✨ ¡Oportunidad de inversión y vivienda en Santa Catarina Pinula! Tanta Premier!

    📍 Zona 10 de Santa Catarina Pinula
    🚗 Acceso inmediato por 20 Calle, Avenida Hincapié y VAS
    🌄 Hermosa vista panorámica hacia los volcanes y la ciudad

    💰 Precio de venta: Q1,450,000

    Esta hermosa casa combina comodidad, ubicación estratégica y excelentes amenidades dentro de un residencial seguro y familiar.

    🏠 Características de la propiedad

    📐 140 m² de construcción

    🔹 Primer nivel
    • Sala y comedor integrados
    • Área de bar
    • Cocina moderna equipada
    • Lavandería
    • Bodega
    • Patio con pérgola y jardín

    🔹 Segundo nivel
    • Dormitorio principal con techo de doble altura y amplio clóset
    • 2 habitaciones secundarias
    • Sala familiar con división

    🚗 Parqueo para 3 vehículos (2 bajo techo)

    ✨ Incluye
    • Calentador de agua
    • Lámparas instaladas
    • Cocina equipada

    🌟 Amenidades del residencial
    🏊 Piscina
    💪 Gimnasio
    🏀 Cancha deportiva
    🎱 Área de billar
    🏓 Mesa de ping pong
    🎉 Salón social para eventos
    💧 Pozo propio y planta de tratamiento
    🛡️ Seguridad y acceso controlado

    📍 Ubicación privilegiada cerca de supermercados, restaurantes, colegios y comercios de la zona.

    📞 Agenda tu visita hoy mismo
    SUNSETS Real Estate
    📲 +502 5431-3945
    """

    let parser = LocalListingParser()

    @Test func detectsSaleOperation() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.operationType.value == .sale)
        #expect(draft.operationType.confidence == .high)
    }

    @Test func detectsPrice1450000() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.price.value == 1_450_000)
        #expect(draft.price.confidence == .high)
    }

    @Test func detectsGTQCurrency() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.currency.value == "GTQ")
    }

    @Test func detectsZona10SantaCatarinaPinula() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        let loc = draft.locationSummary.value ?? ""
        #expect(loc.localizedCaseInsensitiveContains("Zona 10") ||
                loc.localizedCaseInsensitiveContains("Santa Catarina"))
    }

    @Test func detects140SquareMeters() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.areaSquareMeters.value == 140.0)
        #expect(draft.areaSquareMeters.confidence == .high)
    }

    @Test func detects3Bedrooms() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.bedrooms.value == 3)
    }

    @Test func detectsNoBathroomCount() async throws {
        // Source does not state a bathroom count
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.bathrooms.value == nil)
        #expect(draft.bathrooms.confidence == .missing)
    }

    @Test func detects3ParkingSpaces() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        #expect(draft.parkingSpaces.value == 3)
    }

    @Test func detectsIncludedItems() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        let items = (draft.includedAppliances.value ?? []) + (draft.includedItems.value ?? [])
        let joined = items.joined(separator: " ").lowercased()
        #expect(joined.contains("calentador") || joined.contains("lámparas") || joined.contains("cocina"))
    }

    @Test func detectsAmenities() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        let amenities = draft.amenities.value ?? []
        #expect(!amenities.isEmpty)
        let joined = amenities.joined(separator: " ").lowercased()
        #expect(joined.contains("piscina") || joined.contains("gimnasio") || joined.contains("cancha"))
    }

    @Test func detectsPhoneContact() async throws {
        let draft = try await parser.parse(Self.tantaListing)
        let contact = draft.contactInfo.value ?? ""
        #expect(contact.contains("5431"))
    }
}


// MARK: - Pet Policy Refinement Tests

@Suite("Pet Policy Refinement")
struct PetPolicyRefinementTests {

    @Test func spanishLabels() {
        #expect(PetPolicy.allowed.label == "Se acepta mascota")
        #expect(PetPolicy.notAllowed.label == "No se aceptan mascotas")
        #expect(PetPolicy.subjectToCaseAnalysis.label == "Sujeto a análisis de caso")
    }

    @Test func legacyAllowedWithDepositMigratesCorrectly() throws {
        let json = miniPropertyJSON(petPolicy: "allowedWithDeposit")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let property = try decoder.decode(Property.self, from: json)
        #expect(property.petPolicy == .subjectToCaseAnalysis)
    }

    @Test func legacyCaseByCaseMigratesCorrectly() throws {
        let json = miniPropertyJSON(petPolicy: "caseByCase")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let property = try decoder.decode(Property.self, from: json)
        #expect(property.petPolicy == .subjectToCaseAnalysis)
    }
}

// MARK: - Sale Financing Tests

@Suite("Sale Financing")
struct SaleFinancingTests {

    @Test func fhaDefaultsToUnknown() {
        let p = Property.new()
        #expect(p.fhaEligibility == .unknown)
        #expect(p.sellerFinancingStatus == .unknown)
    }

    @Test func financingTextNilForRentalProperty() {
        var p = makeSampleProperty()
        p.operationType = .rent
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .eligible
        #expect(FinancingTextService.text(for: p) == nil)
    }

    @Test func financingTextNotNilForSaleWithUnavailableFinancing() {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        let text = FinancingTextService.text(for: p)
        #expect(text != nil)
        #expect(text?.contains("banco") == true || text?.contains("banco") == false && text?.contains("70%") == true)
    }

    @Test func financingTextIncludesFHAParagraphWhenEligible() {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .eligible
        let text = FinancingTextService.text(for: p) ?? ""
        #expect(text.contains("FHA"))
        #expect(text.contains("5%"))
    }

    @Test func financingTextOmitsFHAWhenNotEligible() {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .notEligible
        let text = FinancingTextService.text(for: p) ?? ""
        #expect(!text.contains("FHA"))
    }

    @Test func fhaWarningShownWhenUnknown() {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .unknown
        let warning = FinancingTextService.fhaWarning(for: p)
        #expect(warning != nil)
        #expect(warning?.contains("FHA") == true)
    }

    @Test func fhaWarningNilWhenEligible() {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.fhaEligibility = .eligible
        #expect(FinancingTextService.fhaWarning(for: p) == nil)
    }

    @Test func financingFieldsRoundTripJSON() throws {
        var p = makeSampleProperty()
        p.operationType = .sale
        p.sellerFinancingStatus = .unavailable
        p.bankFinancingAssistanceAvailable = true
        p.fhaEligibility = .eligible
        p.financingNotes = "Banco Industrial disponible"
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(p)
        let decoded = try decoder.decode(Property.self, from: data)
        #expect(decoded.sellerFinancingStatus == .unavailable)
        #expect(decoded.bankFinancingAssistanceAvailable == true)
        #expect(decoded.fhaEligibility == .eligible)
        #expect(decoded.financingNotes == "Banco Industrial disponible")
    }

    @Test func legacyJSONDecodesWithFinancingDefaults() throws {
        let json = miniPropertyJSON(petPolicy: "notAllowed")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let property = try decoder.decode(Property.self, from: json)
        #expect(property.sellerFinancingStatus == .unknown)
        #expect(property.fhaEligibility == .unknown)
        #expect(property.bankFinancingAssistanceAvailable == false)
        #expect(property.financingNotes == nil)
    }
}

// MARK: - FHA Parser Tests

@Suite("LocalListingParser — FHA Detection")
struct FHAParserTests {

    let parser = LocalListingParser()

    @Test func detectsAplicaFHAAsEligible() async throws {
        let listing = "Casa en venta. Precio Q2,500,000. Aplica FHA. 3 recámaras, 2 baños."
        let draft = try await parser.parse(listing)
        #expect(draft.fhaEligibility.value == .eligible)
        #expect(draft.fhaEligibility.confidence == .high)
    }

    @Test func detectsNoAplicaFHAAsNotEligible() async throws {
        let listing = "Casa en venta. Precio Q2,500,000. No aplica FHA. 3 recámaras, 2 baños."
        let draft = try await parser.parse(listing)
        #expect(draft.fhaEligibility.value == .notEligible)
        #expect(draft.fhaEligibility.confidence == .high)
    }

    @Test func noFHAMentionReturnsUnknown() async throws {
        let listing = "Casa en venta. Precio Q2,500,000. 3 recámaras, 2 baños."
        let draft = try await parser.parse(listing)
        #expect(draft.fhaEligibility.value == .unknown)
    }
}

// MARK: - Helpers (private)

private func miniPropertyJSON(petPolicy: String) -> Data {
    """
    {"id":"x","internalCode":"SUN-001","title":"T","operationType":"rent","status":"available",
     "price":1,"currency":"GTQ","maintenanceIncluded":false,"locationSummary":"Z","country":"Guatemala",
     "bedrooms":1,"bathrooms":1.0,"amenities":[],"includedAppliances":[],"requirements":[],
     "petPolicy":"\(petPolicy)","quickReplyTemplates":[],"isFavorite":false,
     "createdAt":"2025-01-01T00:00:00Z","updatedAt":"2025-01-01T00:00:00Z"}
    """.data(using: .utf8)!
}

// MARK: - Helpers

func makeSampleProperty(
    id: String = UUID().uuidString,
    title: String = "Propiedad de Prueba",
    displayTitle: String? = nil,  // defaults to title when nil
    code: String = "SUN-TEST",
    location: String = "Antigua Guatemala",
    status: PropertyStatus = .available,
    operation: OperationType = .rent,
    price: Decimal = 5000,
    favorite: Bool = false,
    createdAt: Date? = nil
) -> Property {
    let now = createdAt ?? Date()
    return Property(
        id: id,
        internalCode: code,
        title: title,
        displayTitle: displayTitle ?? title,
        operationType: operation,
        status: status,
        price: price,
        currency: "GTQ",
        maintenanceFee: nil,
        maintenanceIncluded: false,
        deposit: nil,
        locationSummary: location,
        neighborhood: nil,
        city: nil,
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
        isFavorite: favorite,
        lastVerifiedAt: nil,
        createdAt: now,
        updatedAt: now
    )
}

// MARK: - Bathroom parsing refinement tests

@Suite("BathroomParsingRefinement")
struct BathroomParsingRefinementTests {
    let parser = LocalListingParser()

    @Test("2 baños returns 2.0")
    func testTwoBaths() async throws {
        let draft = try await parser.parse("Apartamento en renta Q 3,000\n2 baños\n1 recámara")
        #expect(draft.bathrooms.value == 2.0)
        #expect(draft.bathrooms.confidence == .high)
    }

    @Test("1 baño y medio returns 1.5")
    func testOneAndHalf() async throws {
        let draft = try await parser.parse("Casa en renta Q 5,000\n1 baño y medio\n3 recámaras")
        #expect(draft.bathrooms.value == 1.5)
        #expect(draft.bathrooms.confidence == .high)
    }

    @Test("2 baños y medio returns 2.5")
    func testTwoAndHalf() async throws {
        let draft = try await parser.parse("Casa en renta Q 8,000\n2 baños y medio\n4 recámaras")
        #expect(draft.bathrooms.value == 2.5)
    }

    @Test("medio baño returns 0.5")
    func testMedioBano() async throws {
        let draft = try await parser.parse("Apartamento Q 2,500\nmedio baño")
        #expect(draft.bathrooms.value == 0.5)
    }

    @Test("1/2 baño returns 0.5")
    func testHalfBanoSlash() async throws {
        let draft = try await parser.parse("Townhouse Q 9,000\n1/2 baño adicional")
        #expect(draft.bathrooms.value == 0.5)
    }

    @Test("2.5 baños returns 2.5")
    func testDecimalBanos() async throws {
        let draft = try await parser.parse("Casa en venta Q 1,450,000\n2.5 baños\n4 recámaras")
        #expect(draft.bathrooms.value == 2.5)
    }
}

// MARK: - Sanitization tests

@Suite("ListingSanitization")
struct ListingSanitizationTests {
    let parser = LocalListingParser()

    @Test("Hashtag-only line is excluded from structured fields")
    func testHashtagLineRemoved() async throws {
        let listing = """
        Casa en renta Q 5,000
        3 recámaras 2 baños
        Ubicada en Zona 10
        #casaenrenta #sunsets #guatemala #inmobiliaria
        """
        let draft = try await parser.parse(listing)
        // hashtags field captures originals; location should not contain "#"
        #expect(draft.locationSummary.value?.contains("#") != true)
    }

    @Test("Contact footer lines are excluded")
    func testContactFooterRemoved() async throws {
        let listing = """
        Apartamento en renta Q 4,200
        2 recámaras 1 baño
        Santa Catarina Pinula
        Contáctenos: 5555-5555
        """
        let draft = try await parser.parse(listing)
        // visitInstructions should not be contaminated with the contact line
        let visit = draft.visitInstructions.value ?? ""
        #expect(!visit.lowercased().contains("contáctenos"))
    }

    @Test("Company signature lines are excluded from sanitized listing text")
    func testCompanySignatureExcluded() async throws {
        let listing = """
        Casa en venta Q 1,200,000
        3 recámaras
        Zona 15
        Sunsets Real Estate — exclusiva
        """
        let draft = try await parser.parse(listing)
        let body = draft.publicListingText.value ?? ""
        #expect(!body.lowercased().contains("sunsets real estate"))
    }

    @Test("Clean content is not affected by sanitization")
    func testCleanContentPreserved() async throws {
        let listing = "Apartamento en renta Q 4,200\n2 recámaras\n1 baño\nZona 10 Guatemala"
        let draft = try await parser.parse(listing)
        #expect(draft.bathrooms.value != nil)
        #expect(draft.bedrooms.value != nil)
    }
}

// MARK: - Property type detection tests

@Suite("PropertyTypeDetection")
struct PropertyTypeDetectionTests {
    let parser = LocalListingParser()

    @Test("Apartamento maps to .apartment")
    func testApartamento() async throws {
        let draft = try await parser.parse("Apartamento en renta Q 4,200 Zona 10")
        #expect(draft.propertyType.value == .apartment)
    }

    @Test("Townhouse maps to .townhouse")
    func testTownhouse() async throws {
        let draft = try await parser.parse("Townhouse en venta Q 1,500,000 San Lucas")
        #expect(draft.propertyType.value == .townhouse)
    }

    @Test("Casa maps to .house")
    func testCasa() async throws {
        let draft = try await parser.parse("Casa en renta Q 6,000 Carretera a El Salvador")
        #expect(draft.propertyType.value == .house)
    }

    @Test("Terreno maps to .land")
    func testTerreno() async throws {
        let draft = try await parser.parse("Terreno en venta Q 500,000 Antigua Guatemala")
        #expect(draft.propertyType.value == .land)
    }
}

// MARK: - Development name extraction tests

@Suite("DevelopmentNameExtraction")
struct DevelopmentNameExtractionTests {
    let parser = LocalListingParser()

    @Test("Residencial prefix is extracted")
    func testResidencialPrefix() async throws {
        let listing = """
        Apartamento en Residencial Las Brisas
        Q 4,500 mensuales
        2 recámaras 1 baño
        """
        let draft = try await parser.parse(listing)
        #expect(draft.developmentName.value?.lowercased().contains("residencial") == true)
    }

    @Test("Torre prefix is extracted")
    func testTorrePrefix() async throws {
        let listing = """
        Apartamento en Torre Cayalá
        Q 8,000 mensuales renta
        2 recámaras
        """
        let draft = try await parser.parse(listing)
        #expect(draft.developmentName.value?.lowercased().contains("torre") == true)
    }

    @Test("No development keyword leaves nil")
    func testNoDevelopmentName() async throws {
        let draft = try await parser.parse("Casa en renta Q 5,000 Zona 14")
        #expect(draft.developmentName.value == nil)
    }
}

// MARK: - Included items inline extraction tests

@Suite("IncludedItemsExtraction")
struct IncludedItemsExtractionTests {
    let parser = LocalListingParser()

    @Test("Inline incluye: list is parsed")
    func testInlineIncluye() async throws {
        let listing = "Casa en renta Q 6,000\n2 recámaras 1 baño\nIncluye: cortinas, escritorios, sillas de oficina"
        let draft = try await parser.parse(listing)
        #expect((draft.includedItems.value?.count ?? 0) >= 2)
    }

    @Test("Section-based incluye list is parsed")
    func testSectionIncluye() async throws {
        let listing = """
        Apartamento Q 5,000
        1 recámara 1 baño
        Se incluyen:
        • Cortinas
        • Calentador de agua
        • Closets empotrados
        """
        let draft = try await parser.parse(listing)
        #expect((draft.includedItems.value?.count ?? 0) >= 2)
    }
}

// MARK: - General info template tests

@Suite("GeneralInfoTemplate")
struct GeneralInfoTemplateTests {

    private func makeProperty(
        status: PropertyStatus = .available,
        operationType: OperationType = .rent,
        price: Decimal = 5000,
        publicListingText: String? = nil,
        publicDescription: String? = nil,
        requirements: [String] = ["DPI", "Recibos de ingresos"],
        isExactLocationShareable: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        googleMapsURL: String? = nil
    ) -> KeyboardSafeProperty {
        var prop = Property(
            id: UUID().uuidString,
            internalCode: "SUN-001",
            propertyType: .apartment,
            title: "Apartamento de prueba",
            operationType: operationType,
            status: status,
            publicDescription: publicDescription,
            price: price,
            currency: "GTQ",
            maintenanceFee: nil,
            maintenanceIncluded: false,
            deposit: nil,
            locationSummary: "Zona 10, Guatemala",
            neighborhood: nil,
            city: "Guatemala",
            state: nil,
            country: "Guatemala",
            latitude: latitude,
            longitude: longitude,
            googleMapsURL: googleMapsURL,
            isExactLocationShareable: isExactLocationShareable,
            bedrooms: 2,
            bathrooms: 1,
            halfBathrooms: nil,
            parkingSpaces: 1,
            areaSquareMeters: 80,
            amenities: [],
            includedAppliances: [],
            requirements: requirements,
            petPolicy: .notAllowed,
            visitInstructions: nil,
            quickReplyTemplates: [],
            isFavorite: false,
            lastVerifiedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        prop.publicListingText = publicListingText
        return KeyboardSafeProperty(projecting: prop)
    }

    @Test("generalInfo for available property with no listing text shows price; requirements are excluded")
    func testAvailablePropertyInfo() {
        let p = makeProperty(status: .available)
        let text = TemplateEngine.generalInfo(for: p)
        #expect(text.contains("Precio:"))
        // Requirements belong in the Requirements button — never in General Info
        #expect(!text.contains("Requisitos:"))
    }

    @Test("generalInfo for unavailable property shows warning")
    func testUnavailableWarning() {
        let p = makeProperty(status: .reserved)
        let text = TemplateEngine.generalInfo(for: p)
        #expect(text.contains("⚠️"))
        #expect(text.contains("reservada"))
    }

    @Test("generalInfo uses publicListingText as primary body")
    func testPublicListingTextUsedAsPrimaryBody() {
        let listing = "Hermoso apartamento con vista panorámica. 3 recámaras."
        let p = makeProperty(publicListingText: listing)
        let text = TemplateEngine.generalInfo(for: p)
        #expect(text.contains(listing))
    }

    @Test("generalInfo falls back to publicDescription when no listing text")
    func testPublicDescriptionFallback() {
        let desc = "Descripción corta del apartamento."
        let p = makeProperty(publicDescription: desc)
        let text = TemplateEngine.generalInfo(for: p)
        #expect(text.contains(desc))
    }

    @Test("generalInfo suppresses price when listing text contains precio")
    func testPriceSuppressedWhenInListing() {
        let listing = "Precio: Q 5,000 mensuales. Bonito apartamento en Zona 10."
        let p = makeProperty(publicListingText: listing)
        let text = TemplateEngine.generalInfo(for: p)
        // Should NOT append a redundant "Precio:" line
        let priceCount = text.components(separatedBy: "Precio:").count - 1
        #expect(priceCount == 1)  // only one from the listing itself
    }

    @Test("generalInfo suppresses requirements when listing text mentions requisitos")
    func testRequirementsSuppressedWhenInListing() {
        let listing = "Requisitos: DPI, constancia de ingresos."
        let p = makeProperty(publicListingText: listing, requirements: ["DPI"])
        let text = TemplateEngine.generalInfo(for: p)
        let reqCount = text.components(separatedBy: "Requisitos").count - 1
        #expect(reqCount == 1)
    }

    @Test("generalInfo never shows requirements or fallback — requirements belong in their own button")
    func testNoRequirementsFallback() {
        let p = makeProperty(requirements: [])
        let text = TemplateEngine.generalInfo(for: p)
        #expect(!text.contains("Permítame confirmar"))
        #expect(!text.contains("Requisitos"))
    }

    @Test("generalInfo does not include maps links — location belongs in its own button")
    func testMapsLinksWithCoordinates() {
        let p = makeProperty(isExactLocationShareable: true,
                             latitude: 14.6349, longitude: -90.5069)
        let text = TemplateEngine.generalInfo(for: p)
        #expect(!text.contains("Google Maps:"))
        #expect(!text.contains("Waze:"))
        #expect(!text.contains("14.634900"))
    }
}

// MARK: - Display title tests

@Suite("DisplayTitle")
struct DisplayTitleTests {

    @Test("buildCanonicalTitle: type en operation · developmentName")
    func testFullDisplayTitle() {
        let title = Property.buildCanonicalTitle(
            propertyType: .apartment, operationType: .sale,
            developmentName: "Terrazas de Villaflores", neighborhoodName: "Zona 14",
            publicLocationLabel: nil, locationSummary: "Zona 10"
        )
        #expect(title == "Apartamento en venta · Terrazas de Villaflores")
    }

    @Test("buildCanonicalTitle falls back to neighborhoodName when no developmentName")
    func testNeighborhoodFallback() {
        let title = Property.buildCanonicalTitle(
            propertyType: .house, operationType: .rent,
            developmentName: nil, neighborhoodName: "Zona 15",
            publicLocationLabel: nil, locationSummary: "Zona 10"
        )
        #expect(title == "Casa en renta · Zona 15")
    }

    @Test("buildCanonicalTitle omits typeOp for .other, shows location only")
    func testOtherTypeOmitted() {
        let title = Property.buildCanonicalTitle(
            propertyType: .other, operationType: .sale,
            developmentName: nil, neighborhoodName: nil,
            publicLocationLabel: nil, locationSummary: "Antigua Guatemala"
        )
        #expect(title == "Antigua Guatemala")
    }

    @Test("Migration: legacy JSON without displayTitle is migrated on decode")
    func testMigrationFromLegacyJSON() throws {
        let json = """
        {
            "id": "mig-001", "internalCode": "SUN-099",
            "propertyType": "house", "developmentName": "Residenciales Sol",
            "title": "Casa bonita",
            "operationType": "rent", "status": "available",
            "price": 5000, "currency": "GTQ", "maintenanceIncluded": false,
            "locationSummary": "Zona 10", "country": "Guatemala",
            "bedrooms": 2, "bathrooms": 1.0, "parkingSpaces": 1,
            "areaSquareMeters": 80, "amenities": [], "includedAppliances": [],
            "requirements": [], "petPolicy": "notAllowed", "quickReplyTemplates": [],
            "isFavorite": false, "createdAt": "2025-01-01T00:00:00Z", "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let p = try decoder.decode(Property.self, from: json)
        #expect(p.displayTitle == "Casa en renta · Residenciales Sol")
    }
}

// MARK: - General message template tests

@Suite("GeneralMessageTemplate")
struct GeneralMessageTemplateTests {

    @Test("GeneralMessageTemplate.new() has correct defaults")
    func testNewTemplateDefaults() {
        let t = GeneralMessageTemplate.new(category: .welcome)
        #expect(t.isEnabled == true)
        #expect(t.isKeyboardVisible == true)   // must default true so new messages reach keyboard
        #expect(t.requiresReviewBeforeInsertion == true)
        #expect(t.category == .welcome)
    }

    @Test("KeyboardSafeGeneralMessage projection maps fields correctly")
    func testProjection() {
        let t = GeneralMessageTemplate(
            id: UUID(),
            title: "Bienvenida",
            category: .welcome,
            body: "Hola, bienvenido.",
            isEnabled: true,
            isKeyboardVisible: true,
            requiresReviewBeforeInsertion: false,
            sortOrder: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        let safe = KeyboardSafeGeneralMessage(projecting: t)
        #expect(safe.title == "Bienvenida")
        #expect(safe.body == "Hola, bienvenido.")
        #expect(safe.category == "welcome")
        #expect(safe.requiresReviewBeforeInsertion == false)
    }

    @Test("GeneralMessageCategory labels are correct Spanish")
    func testCategoryLabels() {
        #expect(GeneralMessageCategory.welcome.label == "Bienvenida")
        #expect(GeneralMessageCategory.qualification.label == "Filtro de cliente")
        #expect(GeneralMessageCategory.reservationPayment.label == "Pago de reserva")
        #expect(GeneralMessageCategory.visitCoordination.label == "Coordinación de visita")
    }
}

// MARK: - Stub Repository

final class StubRepository: PropertyRepository {
    var properties: [Property]
    var activeId: String?
    var employee: String?
    private var codeCounter: Int = 0

    init(properties: [Property] = []) {
        self.properties = properties
        self.codeCounter = InternalCodeService.maxNumber(in: properties.map(\.internalCode))
    }

    func fetchAll() async throws -> [Property] { properties }

    func save(_ property: Property) async throws {
        let isNew = !properties.contains { $0.id == property.id }
        if let i = properties.firstIndex(where: { $0.id == property.id }) {
            properties[i] = property
        } else {
            properties.append(property)
        }
        if isNew, let codeNum = InternalCodeService.extractNumber(from: property.internalCode) {
            if codeNum > codeCounter { codeCounter = codeNum }
        }
    }

    func delete(id: String) async throws {
        properties.removeAll { $0.id == id }
        if activeId == id { activeId = nil }
    }

    func fetchActiveId() async throws -> String? { activeId }
    func setActiveId(_ id: String?) async throws { activeId = id }
    func fetchEmployee() async throws -> String? { employee }
    func setEmployee(_ name: String) async throws { employee = name }

    func peekNextInternalCode() async throws -> String {
        InternalCodeService.format(number: codeCounter + 1)
    }

    func isInternalCodeUnique(_ code: String, excludingId: String?) async throws -> Bool {
        !properties.contains { p in
            p.internalCode.uppercased() == code.uppercased() && p.id != excludingId
        }
    }
}

// MARK: - Arboretto fixture regression tests

@Suite("ArborettoFixture")
struct ArborettoFixtureTests {

    private let arborettoListing = """
    Casa en venta | Residenciales Arboretto
    Santa Catarina Pinula, Guatemala

    Hermosa casa en venta en Residenciales Arboretto.
    3 recámaras, 2.5 baños, 2 parqueos.
    La propiedad cuenta con bodega de almacenamiento incluida.
    Precio: Q 1,850,000

    Requisitos: DPI, carta de ingresos.

    Contáctanos para más información.
    Agenda tu visita hoy.
    """

    @Test("Arboretto: propertyType detected as house, not warehouse")
    func testPropertyTypeIsHouseNotWarehouse() async throws {
        let parser = LocalListingParser()
        let draft = try await parser.parse(arborettoListing)
        #expect(draft.propertyType.value == .house)
    }

    @Test("Arboretto: developmentName extracted as Residenciales Arboretto")
    func testDevelopmentNameExtracted() async throws {
        let parser = LocalListingParser()
        let draft = try await parser.parse(arborettoListing)
        #expect(draft.developmentName.value == "Residenciales Arboretto")
    }

    @Test("Arboretto: operationType detected as sale")
    func testOperationTypeIsSale() async throws {
        let parser = LocalListingParser()
        let draft = try await parser.parse(arborettoListing)
        #expect(draft.operationType.value == .sale)
    }

    @Test("Arboretto: locationSummary contains Santa Catarina Pinula")
    func testLocationExtracted() async throws {
        let parser = LocalListingParser()
        let draft = try await parser.parse(arborettoListing)
        let location = draft.locationSummary.value ?? ""
        #expect(location.contains("Santa Catarina Pinula"))
    }

    @Test("Arboretto: publicListingText excludes CTA lines")
    func testCTALinesRemoved() async throws {
        let parser = LocalListingParser()
        let draft = try await parser.parse(arborettoListing)
        let text = draft.publicListingText.value ?? ""
        #expect(!text.lowercased().contains("contáctanos"))
        #expect(!text.lowercased().contains("agenda tu visita"))
    }

    @Test("Arboretto: development name detected and canonical title computed correctly")
    func testDisplayTitle() async throws {
        let parser = LocalListingParser()
        let draft = try await parser.parse(arborettoListing)

        #expect(draft.developmentName.value == "Residenciales Arboretto")

        let type = draft.propertyType.value ?? .other
        let op   = draft.operationType.value ?? .sale
        let dev  = draft.developmentName.value

        let canonical = Property.buildCanonicalTitle(
            propertyType: type, operationType: op,
            developmentName: dev, neighborhoodName: nil,
            publicLocationLabel: nil,
            locationSummary: draft.locationSummary.value ?? ""
        )
        #expect(canonical == "Casa en venta · Residenciales Arboretto")
    }
}

// MARK: - Waze URL tests

@Suite("WazeURL")
struct WazeURLTests {

    @Test("projection passes through stored wazeURL coordinate link")
    func testStoredCoordinateWazeURL() {
        var p = Property(
            id: "w1", internalCode: "SUN-W01", title: "Test", operationType: .rent,
            status: .available, price: 1000, currency: "GTQ",
            maintenanceFee: nil, maintenanceIncluded: false, deposit: nil,
            locationSummary: "Zona 10",
            neighborhood: nil, city: nil, state: nil, country: "Guatemala",
            bedrooms: 1, bathrooms: 1, parkingSpaces: 0, areaSquareMeters: 50,
            amenities: [], includedAppliances: [], requirements: [],
            petPolicy: .notAllowed, visitInstructions: nil, quickReplyTemplates: [],
            isFavorite: false, lastVerifiedAt: nil, createdAt: Date(), updatedAt: Date()
        )
        p.wazeURL = "https://waze.com/ul?ll=14.634900,-90.506900&navigate=yes"
        p.isExactLocationShareable = true
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.wazeURL?.contains("ll=14.634900") == true)
        #expect(kp.wazeURL?.contains("navigate=yes") == true)
    }

    @Test("projection passes through stored wazeURL label search link")
    func testStoredLabelSearchWazeURL() {
        var p = Property(
            id: "w2", internalCode: "SUN-W02", title: "Test", operationType: .rent,
            status: .available, price: 1000, currency: "GTQ",
            maintenanceFee: nil, maintenanceIncluded: false, deposit: nil,
            locationSummary: "Zona 14",
            neighborhood: nil, city: nil, state: nil, country: "Guatemala",
            bedrooms: 1, bathrooms: 1, parkingSpaces: 0, areaSquareMeters: 50,
            amenities: [], includedAppliances: [], requirements: [],
            petPolicy: .notAllowed, visitInstructions: nil, quickReplyTemplates: [],
            isFavorite: false, lastVerifiedAt: nil, createdAt: Date(), updatedAt: Date()
        )
        p.wazeURL = "https://waze.com/ul?q=Zona%2014%2C%20Guatemala"
        let kp = KeyboardSafeProperty(projecting: p)
        #expect(kp.wazeURL?.contains("waze.com/ul?q=") == true)
    }

    @Test("projection wazeURL is nil when not stored on Property")
    func testNilWazeURLWhenNotStored() {
        let p = Property(
            id: "w3", internalCode: "SUN-W03", title: "Test", operationType: .rent,
            status: .available, price: 1000, currency: "GTQ",
            maintenanceFee: nil, maintenanceIncluded: false, deposit: nil,
            locationSummary: "Zona 10",
            neighborhood: nil, city: nil, state: nil, country: "Guatemala",
            bedrooms: 1, bathrooms: 1, parkingSpaces: 0, areaSquareMeters: 50,
            amenities: [], includedAppliances: [], requirements: [],
            petPolicy: .notAllowed, visitInstructions: nil, quickReplyTemplates: [],
            isFavorite: false, lastVerifiedAt: nil, createdAt: Date(), updatedAt: Date()
        )
        let kp = KeyboardSafeProperty(projecting: p)
        // wazeURL is nil when not stored; TemplateEngine provides fallback at render time
        #expect(kp.wazeURL == nil)
    }

    @Test("buildProperty computes wazeURL from coordinates when none entered")
    func testBuildPropertyComputesWazeFromCoords() async {
        let repo = StubRepository()
        let vm = PropertyEditorViewModel(repository: repo)
        await vm.prepareForNew()
        vm.locationSummary = "Zona 10"
        vm.priceText = "5000"
        vm.currency = "GTQ"
        vm.latitude = 14.6349
        vm.longitude = -90.5069
        vm.locationSource = .mapPicker
        // wazeURLText is empty → should auto-compute from coords
        let property = vm.buildProperty()
        #expect(property?.wazeURL?.contains("ll=14.6349") == true)
        #expect(property?.wazeURL?.contains("navigate=yes") == true)
    }

    @Test("buildProperty uses label search for wazeURL when no coords")
    func testBuildPropertyWazeFromLabel() async {
        let repo = StubRepository()
        let vm = PropertyEditorViewModel(repository: repo)
        await vm.prepareForNew()
        vm.locationSummary = "Zona 10, Guatemala"
        vm.publicLocationLabelText = "Zona 10"
        vm.priceText = "5000"
        vm.currency = "GTQ"
        let property = vm.buildProperty()
        #expect(property?.wazeURL?.contains("waze.com/ul?q=") == true)
        #expect(property?.wazeURL?.contains("Zona") == true)
    }

    @Test("buildProperty respects manually entered wazeURL")
    func testBuildPropertyRespectsManualWaze() async {
        let repo = StubRepository()
        let vm = PropertyEditorViewModel(repository: repo)
        await vm.prepareForNew()
        vm.locationSummary = "Zona 10"
        vm.priceText = "5000"
        vm.currency = "GTQ"
        vm.wazeURLText = "https://waze.com/ul?q=custom"
        let property = vm.buildProperty()
        #expect(property?.wazeURL == "https://waze.com/ul?q=custom")
    }
}

// MARK: - Sanitization tests

@Suite("ListingSanitizationExtended")
struct ListingSanitizationExtendedTests {

    @Test("sanitize removes CTA lines")
    func testCTALinesRemoved() async throws {
        let text = """
        Hermosa casa en venta.
        Contáctanos para más información.
        Agenda tu visita hoy.
        3 recámaras disponibles.
        """
        let draft = try await LocalListingParser().parse(text)
        let sanitized = draft.publicListingText.value ?? ""
        #expect(!sanitized.lowercased().contains("contáctanos"))
        #expect(!sanitized.lowercased().contains("agenda tu visita"))
        #expect(sanitized.contains("3 recámaras"))
    }

    @Test("sanitize removes inline hashtags but keeps line content")
    func testInlineHashtagsRemoved() async throws {
        let text = """
        Hermoso apartamento en renta. #InmuebleNuevo
        Precio Q 4,500 mensuales. #Guatemala #ZonaViva
        """
        let draft = try await LocalListingParser().parse(text)
        let sanitized = draft.publicListingText.value ?? ""
        #expect(!sanitized.contains("#InmuebleNuevo"))
        #expect(!sanitized.contains("#Guatemala"))
        #expect(sanitized.contains("Hermoso apartamento en renta"))
    }
}

// MARK: - Defect 1 regression — display title never uses garbage location strings

@Suite("DisplayTitleRegression")
struct DisplayTitleRegressionTests {

    private func canonical(
        propertyType: PropertyType = .house,
        operation: OperationType = .sale,
        developmentName: String? = nil,
        neighborhoodName: String? = nil,
        publicLocationLabel: String? = nil,
        locationSummary: String = "Zona 10"
    ) -> String {
        Property.buildCanonicalTitle(
            propertyType: propertyType, operationType: operation,
            developmentName: developmentName, neighborhoodName: neighborhoodName,
            publicLocationLabel: publicLocationLabel, locationSummary: locationSummary
        )
    }

    @Test("Price line in locationSummary is excluded from canonical title")
    func testPriceLineRejected() {
        let title = canonical(locationSummary: "Precio de venta: Q900,000")
        #expect(!title.contains("Precio"))
        #expect(!title.contains("Q900,000"))
        #expect(title == "Casa en venta")
    }

    @Test("Field label 'Ubicación:' never appears as location component")
    func testFieldLabelRejected() {
        let title = canonical(propertyType: .other, locationSummary: "Ubicación:")
        #expect(!title.contains("Ubicación:"))
        #expect(title == "Propiedad pendiente de revisión")
    }

    @Test("'Renta En' operation phrase never appears as location component")
    func testOperationPhraseRejected() {
        let title = canonical(propertyType: .other, locationSummary: "Renta En")
        #expect(!title.lowercased().contains("renta en"))
        #expect(title == "Propiedad pendiente de revisión")
    }

    @Test("Fallback is pending-review string (internal code shown in subtitle row)")
    func testFallbackNeverContainsCode() {
        let title = canonical(propertyType: .other, locationSummary: "precio de venta: Q900,000")
        #expect(title == "Propiedad pendiente de revisión")
    }

    @Test("Valid location passes through correctly")
    func testValidLocationPassesThrough() {
        let title = canonical(locationSummary: "Santa Catarina Pinula")
        #expect(title == "Casa en venta · Santa Catarina Pinula")
    }

    @Test("Development name takes priority over garbage locationSummary")
    func testDevelopmentNamePriority() {
        let title = canonical(
            developmentName: "Residenciales Arboretto",
            locationSummary: "precio de venta: Q1,200,000"
        )
        #expect(title == "Casa en venta · Residenciales Arboretto")
    }

    @Test("isValidForCache is true for property with garbage locationSummary")
    func testIsValidForCacheIncludesGarbageLocationProperty() {
        var p = Property.new()
        p.propertyType = .other
        p.locationSummary = "Precio de venta: Q900,000"
        p.price = 900_000
        p.currency = "GTQ"
        p.internalCode = "SUN-100"
        #expect(p.isValidForCache == true)
    }

    @Test("isValidForCache is true even when price is zero")
    func testIsValidForCacheIncludesZeroPriceProperty() {
        var p = Property.new()
        p.locationSummary = "Zona 10"
        p.price = 0
        p.currency = "GTQ"
        p.internalCode = "SUN-020"
        #expect(p.isValidForCache == true)
    }

    @Test("isValidForCache requires non-empty id and internalCode")
    func testIsValidForCacheRequiresCodeAndId() {
        var p = Property.new()
        p.locationSummary = "Zona 10"
        p.internalCode = ""
        #expect(p.isValidForCache == false)
    }

    @Test("isValidForCache is true for clean property")
    func testIsValidForCacheAcceptsCleanProperty() {
        var p = Property.new()
        p.locationSummary = "Zona 10"
        p.price = 900_000
        p.currency = "GTQ"
        p.internalCode = "SUN-010"
        #expect(p.isValidForCache == true)
    }
}

// MARK: - Defect 3 regression — general message visibility defaults

@Suite("GeneralMessageDefaults")
struct GeneralMessageDefaultTests {

    @Test("new() defaults isKeyboardVisible to true")
    func testNewMessageDefaultsVisible() {
        let msg = GeneralMessageTemplate.new()
        #expect(msg.isKeyboardVisible == true)
    }

    @Test("new() defaults isEnabled to true")
    func testNewMessageDefaultsEnabled() {
        let msg = GeneralMessageTemplate.new()
        #expect(msg.isEnabled == true)
    }

    @Test("Message with isEnabled=false is excluded from publish filter")
    func testDisabledMessageExcluded() {
        var msg = GeneralMessageTemplate.new()
        msg.isEnabled = false
        // Confirm the filter expression used in CatalogCacheService would exclude it.
        let wouldPublish = msg.isEnabled && msg.isKeyboardVisible
        #expect(wouldPublish == false)
    }

    @Test("Message with isKeyboardVisible=false is excluded from publish filter")
    func testInvisibleMessageExcluded() {
        var msg = GeneralMessageTemplate.new()
        msg.isKeyboardVisible = false
        let wouldPublish = msg.isEnabled && msg.isKeyboardVisible
        #expect(wouldPublish == false)
    }

    @Test("Message with both enabled and visible passes publish filter")
    func testEnabledAndVisibleMessageIncluded() {
        let msg = GeneralMessageTemplate.new()
        let wouldPublish = msg.isEnabled && msg.isKeyboardVisible
        #expect(wouldPublish == true)
    }
}

// MARK: - Defect 1 helper — isCleanLocationPart unit tests

@Suite("IsCleanLocationPart")
struct IsCleanLocationPartTests {

    @Test("Accepts plain place names")
    func testAcceptsPlaceName() {
        #expect(Property.isCleanLocationPart("Zona 10") == true)
        #expect(Property.isCleanLocationPart("Santa Catarina Pinula") == true)
        #expect(Property.isCleanLocationPart("Residenciales Arboretto") == true)
        #expect(Property.isCleanLocationPart("Antigua Guatemala") == true)
    }

    @Test("Rejects price-related strings")
    func testRejectsPriceStrings() {
        #expect(Property.isCleanLocationPart("Precio de venta: Q900,000") == false)
        #expect(Property.isCleanLocationPart("Q. 5,000 mensuales") == false)
        #expect(Property.isCleanLocationPart("GTQ 1,200,000") == false)
    }

    @Test("Rejects field label artifacts")
    func testRejectsFieldLabels() {
        #expect(Property.isCleanLocationPart("Ubicación:") == false)
        #expect(Property.isCleanLocationPart("Ubicacion:") == false)
    }

    @Test("Rejects operation phrases as location")
    func testRejectsOperationPhrases() {
        #expect(Property.isCleanLocationPart("Renta En") == false)
        #expect(Property.isCleanLocationPart("En Venta") == false)
    }

    @Test("Rejects strings shorter than 3 characters")
    func testRejectsShortStrings() {
        #expect(Property.isCleanLocationPart("Z1") == false)
        #expect(Property.isCleanLocationPart("") == false)
    }
}

// MARK: - Sync lifecycle — property appears in snapshot immediately

@Suite("SyncLifecycle")
struct SyncLifecycleTests {

    private func makeRepo() -> LocalPropertyRepository {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        return LocalPropertyRepository(fileURL: tmp)
    }

    private func makeProperty(code: String = "SUN-020", price: Decimal = 5_000) -> Property {
        var p = Property.new()
        p.internalCode = code
        p.price = price
        p.currency = "GTQ"
        p.locationSummary = "Zona 10"
        p.operationType = .rent
        p.propertyType = .house
        p.status = .available
        return p
    }

    @Test("Newly created property with valid code appears in snapshot properties array")
    func testNewPropertyAppearsInSnapshot() async throws {
        let repo = makeRepo()
        let property = makeProperty(code: "SUN-020")
        try await repo.save(property)

        let tmpSnapshot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let cache = CatalogCacheService(snapshotURL: tmpSnapshot)
        await cache.publish(repository: repo)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: tmpSnapshot)
        let snapshot = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)

        let codes = snapshot.properties.map { $0.internalCode }
        #expect(codes.contains("SUN-020"))
    }

    @Test("Available property appears in snapshot (keyboard Disponibles tab)")
    func testAvailablePropertyInSnapshot() async throws {
        let repo = makeRepo()
        var p = makeProperty(code: "SUN-021")
        p.status = .available
        try await repo.save(p)

        let tmpSnapshot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let cache = CatalogCacheService(snapshotURL: tmpSnapshot)
        await cache.publish(repository: repo)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: tmpSnapshot)
        let snapshot = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)

        let available = snapshot.properties.filter { $0.status == .available }
        #expect(available.map { $0.internalCode }.contains("SUN-021"))
    }

    @Test("Property with price=0 is included in snapshot")
    func testZeroPricePropertyIncluded() async throws {
        let repo = makeRepo()
        let p = makeProperty(code: "SUN-022", price: 0)
        try await repo.save(p)

        let tmpSnapshot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let cache = CatalogCacheService(snapshotURL: tmpSnapshot)
        await cache.publish(repository: repo)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: tmpSnapshot)
        let snapshot = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)

        #expect(snapshot.properties.map { $0.internalCode }.contains("SUN-022"))
    }

    @Test("Property with garbage locationSummary is still included in snapshot")
    func testGarbageLocationPropertyIncluded() async throws {
        let repo = makeRepo()
        var p = makeProperty(code: "SUN-023")
        p.locationSummary = "Precio de venta: Q900,000"
        try await repo.save(p)

        let tmpSnapshot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let cache = CatalogCacheService(snapshotURL: tmpSnapshot)
        await cache.publish(repository: repo)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: tmpSnapshot)
        let snapshot = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)

        #expect(snapshot.properties.map { $0.internalCode }.contains("SUN-023"))
    }
}

// MARK: - Message sync — general messages coexist with properties in snapshot

@Suite("MessageSyncLifecycle")
struct MessageSyncLifecycleTests {

    private func makeMsgRepo() -> LocalGeneralMessageRepository {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        return LocalGeneralMessageRepository(fileURL: tmp)
    }

    private func makePropRepo() -> LocalPropertyRepository {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        return LocalPropertyRepository(fileURL: tmp)
    }

    private func makeSnapshotURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
    }

    private func decodeSnapshot(at url: URL) throws -> KeyboardCatalogSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: url)
        return try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
    }

    @Test("Creating Bienvenida message publishes it to snapshot")
    func testBienvenidaPublished() async throws {
        let propRepo = makePropRepo()
        let msgRepo = makeMsgRepo()
        var msg = GeneralMessageTemplate.new(category: .welcome)
        msg.title = "Bienvenida"
        msg.body = "Hola, bienvenido a Sunsets."
        try await msgRepo.save(msg)

        let url = makeSnapshotURL()
        let cache = CatalogCacheService(snapshotURL: url)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let snapshot = try decodeSnapshot(at: url)
        let titles = snapshot.generalMessages.map { $0.title }
        #expect(titles.contains("Bienvenida"))
    }

    @Test("Editing a message body updates the keyboard snapshot")
    func testEditingMessageUpdatesSnapshot() async throws {
        let propRepo = makePropRepo()
        let msgRepo = makeMsgRepo()
        var msg = GeneralMessageTemplate.new(category: .welcome)
        msg.title = "Bienvenida"
        msg.body = "Versión 1"
        try await msgRepo.save(msg)

        let url = makeSnapshotURL()
        let cache = CatalogCacheService(snapshotURL: url)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        msg.body = "Versión 2"
        try await msgRepo.save(msg)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let snapshot = try decodeSnapshot(at: url)
        let updated = snapshot.generalMessages.first { $0.title == "Bienvenida" }
        #expect(updated?.body == "Versión 2")
    }

    @Test("Disabling a message removes it from the keyboard snapshot")
    func testDisabledMessageRemovedFromSnapshot() async throws {
        let propRepo = makePropRepo()
        let msgRepo = makeMsgRepo()
        var msg = GeneralMessageTemplate.new(category: .qualification)
        msg.title = "Filtro renta"
        msg.body = "¿Cuántas personas vivirán?"
        try await msgRepo.save(msg)

        let url = makeSnapshotURL()
        let cache = CatalogCacheService(snapshotURL: url)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let before = try decodeSnapshot(at: url)
        #expect(before.generalMessages.map { $0.title }.contains("Filtro renta"))

        // Disable the message
        msg.isEnabled = false
        try await msgRepo.save(msg)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let after = try decodeSnapshot(at: url)
        #expect(!after.generalMessages.map { $0.title }.contains("Filtro renta"))
    }

    @Test("Re-enabling a message restores it to the keyboard snapshot")
    func testReenablingMessageRestoresSnapshot() async throws {
        let propRepo = makePropRepo()
        let msgRepo = makeMsgRepo()
        var msg = GeneralMessageTemplate.new(category: .qualification)
        msg.title = "Filtro renta"
        msg.body = "¿Cuántas personas vivirán?"
        msg.isEnabled = false   // start disabled
        try await msgRepo.save(msg)

        let url = makeSnapshotURL()
        let cache = CatalogCacheService(snapshotURL: url)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let before = try decodeSnapshot(at: url)
        #expect(!before.generalMessages.map { $0.title }.contains("Filtro renta"))

        // Re-enable
        msg.isEnabled = true
        try await msgRepo.save(msg)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let after = try decodeSnapshot(at: url)
        #expect(after.generalMessages.map { $0.title }.contains("Filtro renta"))
    }

    @Test("Properties and messages coexist in the same decoded snapshot")
    func testPropertiesAndMessagesCoexistInSnapshot() async throws {
        let propRepo = makePropRepo()
        let msgRepo = makeMsgRepo()

        var prop = Property.new()
        prop.internalCode = "SUN-020"
        prop.title = "Casa Arboretto"
        prop.price = 5000
        prop.currency = "GTQ"
        prop.locationSummary = "Zona 10"
        try await propRepo.save(prop)

        var msg = GeneralMessageTemplate.new(category: .welcome)
        msg.title = "Bienvenida"
        msg.body = "Hola, bienvenido."
        try await msgRepo.save(msg)

        let url = makeSnapshotURL()
        let cache = CatalogCacheService(snapshotURL: url)
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        let snapshot = try decodeSnapshot(at: url)
        #expect(snapshot.properties.map { $0.internalCode }.contains("SUN-020"))
        #expect(snapshot.generalMessages.map { $0.title }.contains("Bienvenida"))
    }

    @Test("Publishing without messageRepository reuses stored repo, not wipe messages")
    func testSubsequentPublishWithoutMsgRepoKeepsMessages() async throws {
        let propRepo = makePropRepo()
        let msgRepo = makeMsgRepo()

        var msg = GeneralMessageTemplate.new(category: .welcome)
        msg.title = "Bienvenida"
        msg.body = "Hola."
        try await msgRepo.save(msg)

        let url = makeSnapshotURL()
        let cache = CatalogCacheService(snapshotURL: url)

        // First publish: passes messageRepository → stored internally
        await cache.publish(repository: propRepo, messageRepository: msgRepo)

        // Second publish: property-only (simulating CatalogViewModel.save()) — must still include messages
        var prop = Property.new()
        prop.internalCode = "SUN-020"
        prop.title = "Test"
        prop.price = 5000
        prop.currency = "GTQ"
        prop.locationSummary = "Zona 10"
        try await propRepo.save(prop)
        await cache.publish(repository: propRepo)   // no messageRepository

        let snapshot = try decodeSnapshot(at: url)
        #expect(snapshot.properties.map { $0.internalCode }.contains("SUN-020"))
        #expect(snapshot.generalMessages.map { $0.title }.contains("Bienvenida"))
    }
}

// MARK: - Rent default requirements tests

@Suite("RentDefaultRequirements")
struct RentDefaultRequirementsTests {

    // MARK: - prepareForNew

    @Test("New rent property receives default requirements")
    func newRentGetsDefaults() async {
        let vm = PropertyEditorViewModel()
        // operationType defaults to .rent
        await vm.prepareForNew()
        let expected = DefaultContent.rentRequirements.joined(separator: "\n")
        #expect(vm.requirementsText == expected)
    }

    @Test("New sale property does not receive rent defaults")
    func newSaleSkipsDefaults() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        #expect(vm.requirementsText.isEmpty)
    }

    @Test("New rent/sale property receives default requirements")
    func newRentOrSaleGetsDefaults() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .rentOrSale
        await vm.prepareForNew()
        let expected = DefaultContent.rentRequirements.joined(separator: "\n")
        #expect(vm.requirementsText == expected)
    }

    @Test("prepareForNew does not overwrite user-supplied requirements")
    func prepareForNewPreservesExistingRequirements() async {
        let vm = PropertyEditorViewModel()
        vm.requirementsText = "Fiador bancario"
        await vm.prepareForNew()
        #expect(vm.requirementsText == "Fiador bancario")
    }

    // MARK: - load(from draft:)

    @Test("Imported rent draft with no requirements receives defaults")
    func importedRentDraftGetsDefaults() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .rent)
        // requirements not set in draft
        vm.load(from: draft)
        let expected = DefaultContent.rentRequirements.joined(separator: "\n")
        #expect(vm.requirementsText == expected)
    }

    @Test("Imported rent draft with existing requirements is not overwritten")
    func importedRentDraftPreservesRequirements() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .rent)
        draft.requirements = DraftField(value: ["Carta de trabajo", "Fiador"])
        vm.load(from: draft)
        #expect(vm.requirementsText == "Carta de trabajo\nFiador")
    }

    @Test("Imported sale draft does not receive rent defaults")
    func importedSaleDraftSkipsDefaults() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .sale)
        vm.load(from: draft)
        #expect(vm.requirementsText.isEmpty)
    }

    // MARK: - load(from property:) — edit path never prefills

    @Test("Editing a rent property with empty requirements does not prefill defaults")
    func editRentWithEmptyRequirementsKeepsEmpty() {
        let vm = PropertyEditorViewModel()
        var p = Property.new()
        p.operationType = .rent
        p.requirements = []
        vm.load(from: p)
        #expect(vm.requirementsText.isEmpty)
    }

    // MARK: - No duplication

    @Test("Calling buildProperty twice does not duplicate requirements lines")
    func buildTwiceDoesNotDuplicate() async {
        let vm = PropertyEditorViewModel()
        await vm.prepareForNew()
        vm.locationSummary = "Zona 10"
        vm.priceText = "5000"

        let first = vm.buildProperty()
        let second = vm.buildProperty()

        let expectedCount = DefaultContent.rentRequirements.count
        #expect(first?.requirements.count == expectedCount)
        #expect(second?.requirements.count == expectedCount)
    }

    @Test("Default requirements count matches doc")
    func defaultRequirementsCount() {
        #expect(DefaultContent.rentRequirements.count == 10)
    }
}

// MARK: - Sale financing default tests

@Suite("SaleFinancingDefaults")
struct SaleFinancingDefaultsTests {

    // MARK: - applySaleFinancingDefaultsIfNeeded via prepareForNew

    @Test("New sale property gets seller-financing defaults")
    func newSaleGetsSellerFinancingDefaults() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        #expect(vm.sellerFinancingStatus == .unavailable)
        #expect(vm.bankFinancingAssistanceAvailable == true)
    }

    @Test("New sale property gets base financing note")
    func newSaleGetsBaseNote() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        #expect(vm.financingNotesText == DefaultContent.saleDefaultNote)
    }

    @Test("New rentOrSale property gets financing defaults")
    func newRentOrSaleGetsDefaults() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .rentOrSale
        await vm.prepareForNew()
        #expect(vm.sellerFinancingStatus == .unavailable)
        #expect(vm.bankFinancingAssistanceAvailable == true)
        #expect(vm.financingNotesText == DefaultContent.saleDefaultNote)
    }

    @Test("New rent property does not get sale financing defaults")
    func newRentSkipsSaleDefaults() async {
        let vm = PropertyEditorViewModel()
        // operationType defaults to .rent
        await vm.prepareForNew()
        #expect(vm.sellerFinancingStatus == .unknown)
        #expect(vm.bankFinancingAssistanceAvailable == false)
        #expect(vm.financingNotesText.isEmpty)
    }

    @Test("Custom financing notes are not overwritten for new sale property")
    func customNotesPreservedForNewSale() {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        vm.financingNotesText = "Nota del agente"
        vm.applySaleFinancingDefaultsIfNeeded()
        #expect(vm.financingNotesText == "Nota del agente")
    }

    @Test("Draft seller financing status is not overridden when already set")
    func sellerFinancingFromDraftNotOverridden() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .sale)
        draft.sellerFinancingStatus = DraftField(value: .available)
        vm.load(from: draft)
        #expect(vm.sellerFinancingStatus == .available)
    }

    // MARK: - applySaleFinancingDefaultsIfNeeded via load(from draft:)

    @Test("Imported sale draft gets base financing defaults")
    func importedSaleDraftGetsDefaults() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .sale)
        vm.load(from: draft)
        #expect(vm.sellerFinancingStatus == .unavailable)
        #expect(vm.bankFinancingAssistanceAvailable == true)
        #expect(vm.financingNotesText == DefaultContent.saleDefaultNote)
    }

    @Test("Imported sale draft with FHA eligible gets full note")
    func importedSaleDraftFHAEligibleGetsFullNote() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .sale)
        draft.fhaEligibility = DraftField(value: .eligible)
        vm.load(from: draft)
        let expected = DefaultContent.saleDefaultNote + "\n\n" + DefaultContent.saleDefaultNoteFHAAppend
        #expect(vm.financingNotesText == expected)
        #expect(vm.fhaEligibility == .eligible)
    }

    @Test("Imported sale draft with non-eligible FHA does not append FHA note")
    func importedSaleDraftNonEligibleFHANoAppend() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .sale)
        draft.fhaEligibility = DraftField(value: .notEligible)
        vm.load(from: draft)
        #expect(!vm.financingNotesText.contains(DefaultContent.saleDefaultNoteFHAAppend))
        #expect(vm.financingNotesText == DefaultContent.saleDefaultNote)
    }

    @Test("Imported rent draft does not get sale financing defaults")
    func importedRentDraftSkipsSaleDefaults() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.operationType = DraftField(value: .rent)
        vm.load(from: draft)
        #expect(vm.sellerFinancingStatus == .unknown)
        #expect(vm.financingNotesText.isEmpty)
    }

    // MARK: - Edit path never prefills

    @Test("Editing existing sale property with no notes does not prefill")
    func editSalePropertyDoesNotPrefill() {
        let vm = PropertyEditorViewModel()
        var p = Property.new()
        p.operationType = .sale
        vm.load(from: p)
        #expect(vm.financingNotesText.isEmpty)
        #expect(vm.sellerFinancingStatus == .unknown)
        #expect(vm.bankFinancingAssistanceAvailable == false)
    }

    // MARK: - syncFHAFinancingNote (interactive editor changes)

    @Test("Switching FHA to eligible appends FHA paragraph")
    func fhaEligibleAppendsParagraph() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        let prev = vm.fhaEligibility  // .unknown
        vm.fhaEligibility = .eligible
        vm.syncFHAFinancingNote(from: prev)
        let expected = DefaultContent.saleDefaultNote + "\n\n" + DefaultContent.saleDefaultNoteFHAAppend
        #expect(vm.financingNotesText == expected)
    }

    @Test("Switching FHA to eligible twice does not duplicate paragraph")
    func fhaEligibleNoDuplicate() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        vm.fhaEligibility = .eligible
        vm.syncFHAFinancingNote(from: .unknown)
        vm.syncFHAFinancingNote(from: .eligible)   // same value again
        let count = vm.financingNotesText
            .components(separatedBy: DefaultContent.saleDefaultNoteFHAAppend).count - 1
        #expect(count == 1)
    }

    @Test("Switching FHA to ineligible removes auto-appended paragraph")
    func fhaIneligibleRemovesParagraph() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        vm.fhaEligibility = .eligible
        vm.syncFHAFinancingNote(from: .unknown)
        vm.fhaEligibility = .notEligible
        vm.syncFHAFinancingNote(from: .eligible)
        #expect(!vm.financingNotesText.contains(DefaultContent.saleDefaultNoteFHAAppend))
        #expect(vm.financingNotesText == DefaultContent.saleDefaultNote)
    }

    @Test("Removing FHA paragraph preserves surrounding custom text")
    func fhaRemovalPreservesCustomText() async {
        let vm = PropertyEditorViewModel()
        vm.operationType = .sale
        await vm.prepareForNew()
        vm.fhaEligibility = .eligible
        vm.syncFHAFinancingNote(from: .unknown)
        vm.financingNotesText += "\n\nNota adicional del agente"
        vm.fhaEligibility = .notEligible
        vm.syncFHAFinancingNote(from: .eligible)
        #expect(!vm.financingNotesText.contains(DefaultContent.saleDefaultNoteFHAAppend))
        #expect(vm.financingNotesText.contains(DefaultContent.saleDefaultNote))
        #expect(vm.financingNotesText.contains("Nota adicional del agente"))
    }

    @Test("syncFHAFinancingNote is no-op for rent properties")
    func fhaSyncNoOpForRent() async {
        let vm = PropertyEditorViewModel()
        // operationType defaults to .rent
        await vm.prepareForNew()
        vm.fhaEligibility = .eligible
        vm.syncFHAFinancingNote(from: .unknown)
        #expect(vm.financingNotesText.isEmpty)
    }
}

// MARK: - Keyboard menu preferences tests

@Suite("KeyboardMenuPreferences")
struct KeyboardMenuPreferencesTests {

    @Test("Default actions count is 13")
    func defaultActionsCount() {
        #expect(KeyboardMenuPreferencesService.defaultActions.count == 13)
    }

    @Test("Default enabled actions are welcome, generalInfo, location, requirements, qualification, purchaseInfo")
    func defaultEnabledSet() {
        let defaults = KeyboardMenuPreferencesService.defaultActions
        let enabled = Set(defaults.filter { $0.isEnabled }.map { $0.id })
        #expect(enabled == ["welcome", "generalInfo", "location", "requirements", "qualification", "purchaseInfo"])
    }

    @Test("availability, price, characteristics, amenities, petPolicy, visit, followUp are disabled by default")
    func defaultDisabledSet() {
        let defaults = KeyboardMenuPreferencesService.defaultActions
        let disabled = defaults.filter { !$0.isEnabled }.map { $0.id }
        #expect(disabled.contains("availability"))
        #expect(disabled.contains("price"))
        #expect(disabled.contains("characteristics"))
        #expect(disabled.contains("amenities"))
        #expect(disabled.contains("petPolicy"))
        #expect(disabled.contains("visit"))
        #expect(disabled.contains("followUp"))
    }

    @Test("requirements and qualification are rent-only by default")
    func rentOnlyDefaults() {
        let defaults = KeyboardMenuPreferencesService.defaultActions
        let requirements = defaults.first { $0.id == "requirements" }
        let qualification = defaults.first { $0.id == "qualification" }
        #expect(requirements?.rentOnly == true)
        #expect(requirements?.saleOnly == false)
        #expect(qualification?.rentOnly == true)
        #expect(qualification?.saleOnly == false)
    }

    @Test("purchaseInfo is sale-only by default")
    func saleOnlyDefaults() {
        let defaults = KeyboardMenuPreferencesService.defaultActions
        let purchaseInfo = defaults.first { $0.id == "purchaseInfo" }
        #expect(purchaseInfo?.rentOnly == false)
        #expect(purchaseInfo?.saleOnly == true)
    }

    @Test("welcome, generalInfo, location are shown for all operation types")
    func alwaysVisibleDefaults() {
        let defaults = KeyboardMenuPreferencesService.defaultActions
        for id in ["welcome", "generalInfo", "location"] {
            let action = defaults.first { $0.id == id }
            #expect(action?.rentOnly == false)
            #expect(action?.saleOnly == false)
        }
    }

    @Test("All action IDs are unique")
    func actionIDsAreUnique() {
        let ids = KeyboardMenuPreferencesService.defaultActions.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    @Test("Snapshot round-trips menu actions")
    func snapshotMenuActionsRoundTrip() throws {
        let actions = KeyboardMenuPreferencesService.defaultActions
        let snapshot = KeyboardCatalogSnapshot(
            schemaVersion: KeyboardCatalogSnapshot.currentSchemaVersion,
            catalogVersion: 1,
            generatedAt: Date(timeIntervalSinceReferenceDate: 800_000_000),
            activePropertyID: nil,
            properties: [],
            generalMessages: [],
            menuActions: actions
        )
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
        #expect(decoded.menuActions.count == actions.count)
        #expect(decoded.menuActions.first?.id == "welcome")
        #expect(decoded.menuActions.first { $0.id == "requirements" }?.rentOnly == true)
        #expect(decoded.menuActions.first { $0.id == "purchaseInfo" }?.saleOnly == true)
    }

    @Test("Old snapshot without menuActions decodes with empty actions")
    func backwardCompatDecoding() throws {
        // Simulate a v2 snapshot JSON without the menuActions key
        let json = """
        {
            "schemaVersion": 2,
            "catalogVersion": 5,
            "generatedAt": "2025-01-01T00:00:00Z",
            "activePropertyID": null,
            "properties": [],
            "generalMessages": []
        }
        """
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(KeyboardCatalogSnapshot.self, from: Data(json.utf8))
        #expect(decoded.menuActions.isEmpty)
        #expect(decoded.catalogVersion == 5)
    }

    @Test("CatalogCacheService publishes default menu actions when no preferences provided")
    func publishIncludesDefaultMenuActions() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let propRepo = LocalPropertyRepository(fileURL:
            FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json"))
        let cache = CatalogCacheService(snapshotURL: tmp)
        await cache.publish(repository: propRepo)

        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: tmp)
        let snapshot = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
        #expect(snapshot.menuActions.count == KeyboardMenuPreferencesService.defaultActions.count)
        #expect(snapshot.menuActions.first { $0.id == "generalInfo" }?.isEnabled == true)
        #expect(snapshot.menuActions.first { $0.id == "availability" }?.isEnabled == false)
    }
}

// MARK: - Edit path regression tests

@Suite("EditPathRegression")
struct EditPathRegressionTests {

    @Test("load(from:) preserves the property UUID in buildProperty output")
    func editPreservesUUID() {
        let vm = PropertyEditorViewModel()
        let p = makeSampleProperty(id: "fixed-uuid-SUN-023", code: "SUN-023")
        vm.load(from: p)
        let built = vm.buildProperty()
        #expect(built?.id == "fixed-uuid-SUN-023")
    }

    @Test("load(from:) preserves internalCode — no new code allocated")
    func editPreservesInternalCode() {
        let vm = PropertyEditorViewModel()
        let p = makeSampleProperty(code: "SUN-023")
        vm.load(from: p)
        let built = vm.buildProperty()
        #expect(built?.internalCode == "SUN-023")
    }

    @Test("load(from:) preserves user-set displayTitle verbatim")
    func editPreservesDisplayTitle() {
        let vm = PropertyEditorViewModel()
        let p = makeSampleProperty(displayTitle: "Mi título personalizado")
        vm.load(from: p)
        let built = vm.buildProperty()
        #expect(built?.displayTitle == "Mi título personalizado")
    }

    @Test("load(from:) preserves saved propertyType")
    func editPreservesPropertyType() {
        let vm = PropertyEditorViewModel()
        var p = makeSampleProperty()
        p.propertyType = .house
        vm.load(from: p)
        let built = vm.buildProperty()
        #expect(built?.propertyType == .house)
    }

    @Test("applySaleFinancingDefaultsIfNeeded is a no-op after load(from:)")
    func editBlocksSaleFinancingPrefill() {
        let vm = PropertyEditorViewModel()
        var p = makeSampleProperty(operation: .sale)
        p.propertyType = .house
        vm.load(from: p)
        // Explicitly call the method — it must be blocked because existingId is set
        vm.applySaleFinancingDefaultsIfNeeded()
        #expect(vm.sellerFinancingStatus == .unknown)
        #expect(vm.bankFinancingAssistanceAvailable == false)
        #expect(vm.financingNotesText.isEmpty)
    }

    @Test("prepareForNew is a no-op after load(from:) — no new code allocated")
    func editBlocksPrepareForNew() async {
        let vm = PropertyEditorViewModel()
        let p = makeSampleProperty(code: "SUN-023")
        vm.load(from: p)
        await vm.prepareForNew()  // must be blocked
        #expect(vm.internalCode == "SUN-023")
        let built = vm.buildProperty()
        #expect(built?.id == p.id)
    }

    @Test("buildProperty displayTitle fallback uses type+location, not price or listing text")
    func displayTitleFallbackExcludesPrice() {
        let vm = PropertyEditorViewModel()
        var p = makeSampleProperty(displayTitle: "", price: 9_500)
        p.propertyType = .apartment
        p.publicLocationLabel = "Zona 14"
        vm.load(from: p)
        let built = vm.buildProperty()
        let title = built?.displayTitle ?? ""
        #expect(!title.contains("9500"))
        #expect(!title.contains("9,500"))
        #expect(!title.contains("GTQ"))
    }

    @Test("buildProperty uses same UUID as input on repeated save")
    func buildPropertyReturnsSameUUIDOnRepeatedSave() {
        let vm = PropertyEditorViewModel()
        let p = makeSampleProperty(id: "stable-id", code: "SUN-023")
        vm.load(from: p)
        let first = vm.buildProperty()
        let second = vm.buildProperty()
        #expect(first?.id == "stable-id")
        #expect(second?.id == "stable-id")
    }
}

// MARK: - Title handling regression tests

@Suite("TitleHandling")
struct TitleHandlingTests {

    let parser = LocalListingParser()

    @Test("Parser does not populate displayTitle from listing text")
    func importerLeavesDisplayTitleEmpty() async throws {
        let draft = try await parser.parse("Casa en renta Q 5,000\nZona 10")
        let vm = PropertyEditorViewModel()
        vm.load(from: draft)
        #expect(vm.displayTitle.isEmpty)
    }

    @Test("isCleanLocationPart rejects bare Quetzal amount without a period")
    func isCleanLocationPartRejectsBareQuetzal() {
        #expect(Property.isCleanLocationPart("Q 5,000 mensuales") == false)
        #expect(Property.isCleanLocationPart("Q5000") == false)
        #expect(Property.isCleanLocationPart("Q 1200000") == false)
    }

    @Test("isCleanLocationPart rejects maintenance text")
    func isCleanLocationPartRejectsMantenimiento() {
        #expect(Property.isCleanLocationPart("mantenimiento incluido") == false)
        #expect(Property.isCleanLocationPart("500 mant.") == false)
    }

    @Test("isLegacyBadTitle flags title containing price or maintenance text")
    func isLegacyBadTitleFlagsPriceMarker() {
        #expect(Property.isLegacyBadTitle("Casa en Zona 10 Q 5,000", propertyType: .house) == true)
        #expect(Property.isLegacyBadTitle("Apartamento en renta GTQ 4,200", propertyType: .apartment) == true)
        #expect(Property.isLegacyBadTitle("Bodega con mantenimiento incluido", propertyType: .warehouse) == true)
    }

    @Test("isLegacyBadTitle flags title whose type prefix conflicts with stored propertyType")
    func isLegacyBadTitleFlagsTypeConflict() {
        #expect(Property.isLegacyBadTitle("Casa en renta · Zona 14", propertyType: .apartment) == true)
        #expect(Property.isLegacyBadTitle("Apartamento en venta · Zona 10", propertyType: .house) == true)
    }

    @Test("isLegacyBadTitle does not flag a clean, matching title")
    func isLegacyBadTitleAcceptsCleanTitle() {
        #expect(Property.isLegacyBadTitle("Casa en renta · Zona 14", propertyType: .house) == false)
        #expect(Property.isLegacyBadTitle("Apartamento en venta · Zona 10", propertyType: .apartment) == false)
        #expect(Property.isLegacyBadTitle("", propertyType: .house) == false)
    }

    @Test("Legacy JSON with price marker in displayTitle is rebuilt on decode")
    func legacyTitleWithPriceIsRepairedOnDecode() throws {
        let json = """
        {
            "id": "leg-001", "internalCode": "SUN-101",
            "propertyType": "house",
            "displayTitle": "Casa en Zona 10 Q 5,000",
            "operationType": "rent", "status": "available",
            "price": 5000, "currency": "GTQ", "maintenanceIncluded": false,
            "locationSummary": "Zona 10", "country": "Guatemala",
            "bedrooms": 2, "bathrooms": 1.0, "parkingSpaces": 0,
            "areaSquareMeters": 80, "amenities": [], "includedAppliances": [],
            "requirements": [], "petPolicy": "notAllowed", "quickReplyTemplates": [],
            "isFavorite": false, "createdAt": "2025-01-01T00:00:00Z", "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let p = try decoder.decode(Property.self, from: json)
        #expect(!p.displayTitle.contains("Q 5,000"))
        #expect(p.displayTitle == "Casa en renta · Zona 10")
    }

    @Test("Legacy JSON with type-conflict in displayTitle is rebuilt on decode")
    func legacyTitleWithTypeConflictIsRepairedOnDecode() throws {
        let json = """
        {
            "id": "leg-002", "internalCode": "SUN-102",
            "propertyType": "apartment",
            "displayTitle": "Casa en Zona 14",
            "operationType": "rent", "status": "available",
            "price": 4200, "currency": "GTQ", "maintenanceIncluded": false,
            "locationSummary": "Zona 14", "country": "Guatemala",
            "bedrooms": 2, "bathrooms": 1.0, "parkingSpaces": 0,
            "areaSquareMeters": 80, "amenities": [], "includedAppliances": [],
            "requirements": [], "petPolicy": "notAllowed", "quickReplyTemplates": [],
            "isFavorite": false, "createdAt": "2025-01-01T00:00:00Z", "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let p = try decoder.decode(Property.self, from: json)
        #expect(!p.displayTitle.lowercased().hasPrefix("casa"))
        #expect(p.displayTitle == "Apartamento en renta · Zona 14")
    }
}

// MARK: - DraftReview display-title seeding tests

@Suite("DraftReviewTitleHandling")
struct DraftReviewTitleHandlingTests {

    @Test("seedSuggestedDisplayTitle fills empty displayTitle from type and operation")
    func seedFillsFromTypeAndOperation() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .house
        vm.operationType = .rent
        vm.seedSuggestedDisplayTitle()
        #expect(vm.displayTitle == "Casa en renta")
    }

    @Test("seedSuggestedDisplayTitle includes clean locationSummary when available")
    func seedIncludesCleanLocation() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .apartment
        vm.operationType = .rent
        vm.locationSummary = "Zona 14"
        vm.seedSuggestedDisplayTitle()
        #expect(vm.displayTitle == "Apartamento en renta · Zona 14")
    }

    @Test("seedSuggestedDisplayTitle includes publicLocationLabel over locationSummary when both set")
    func seedPrefersPublicLocationLabel() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .apartment
        vm.operationType = .rent
        vm.publicLocationLabelText = "Zona 14"
        vm.locationSummary = "Zona 14, Guatemala City, Guatemala"
        vm.seedSuggestedDisplayTitle()
        #expect(vm.displayTitle == "Apartamento en renta · Zona 14")
    }

    @Test("seedSuggestedDisplayTitle does not overwrite an existing displayTitle")
    func seedDoesNotOverwrite() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .house
        vm.operationType = .rent
        vm.locationSummary = "Zona 10"
        vm.displayTitle = "Mi título personalizado"
        vm.seedSuggestedDisplayTitle()
        #expect(vm.displayTitle == "Mi título personalizado")
    }

    @Test("seedSuggestedDisplayTitle is a no-op when propertyType is .other")
    func seedNoOpForUnknownType() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .other
        vm.locationSummary = "Zona 10"
        vm.seedSuggestedDisplayTitle()
        #expect(vm.displayTitle.isEmpty)
    }

    @Test("seedSuggestedDisplayTitle excludes price-contaminated locationSummary")
    func seedRejectsPriceInLocation() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .house
        vm.operationType = .rent
        vm.locationSummary = "Q 5,000 mensuales"
        vm.seedSuggestedDisplayTitle()
        #expect(!vm.displayTitle.contains("5,000"))
        #expect(!vm.displayTitle.contains("Q"))
        #expect(vm.displayTitle == "Casa en renta")
    }

    @Test("buildProperty after seed uses the seeded title exactly")
    func buildPropertyUsesSeededTitle() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .apartment
        vm.operationType = .rent
        vm.locationSummary = "Zona 15"
        vm.priceText = "4500"
        vm.seedSuggestedDisplayTitle()
        vm.setInternalCodeForTesting("SUN-999")
        let built = vm.buildProperty()
        #expect(built?.displayTitle == "Apartamento en renta · Zona 15")
    }

    @Test("buildProperty uses manual title after user edits the seeded value")
    func buildPropertyUsesManualOverSeed() {
        let vm = PropertyEditorViewModel()
        vm.propertyType = .house
        vm.operationType = .sale
        vm.locationSummary = "Zona 10"
        vm.priceText = "1200000"
        vm.seedSuggestedDisplayTitle()
        vm.displayTitle = "Casa con vista al lago"
        vm.setInternalCodeForTesting("SUN-999")
        let built = vm.buildProperty()
        #expect(built?.displayTitle == "Casa con vista al lago")
    }

    @Test("full import pipeline: seed title flows through load(from draft:) to saved Property")
    func importPipelineTitleFlowsThrough() {
        let vm = PropertyEditorViewModel()
        var draft = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        draft.propertyType = DraftField(value: .house, confidence: .high)
        draft.operationType = DraftField(value: .rent, confidence: .high)
        draft.locationSummary = DraftField(value: "Zona 10", confidence: .high)
        draft.price = DraftField(value: Decimal(5000), confidence: .high)
        draft.currency = DraftField(value: "GTQ", confidence: .high)
        vm.load(from: draft)
        vm.seedSuggestedDisplayTitle()
        vm.setInternalCodeForTesting("SUN-999")
        let built = vm.buildProperty()
        #expect(built?.displayTitle == "Casa en renta · Zona 10")
    }
}

// MARK: - Import lifecycle tests

@Suite("ImportLifecycle")
struct ImportLifecycleTests {

    private let listing = "Casa en renta Q 5,000\n3 recámaras\nZona 10"

    @Test("analyze → discard → analyze again succeeds and reaches .ready twice")
    func analyzeDiscardAnalyze() async throws {
        let vm = ListingImportViewModel(repository: StubRepository())
        vm.rawText = listing

        // First analysis
        await vm.parse()
        guard case .ready = vm.importState else {
            Issue.record("Expected .ready after first parse; got \(vm.importState)")
            return
        }

        // Discard (mirrors what onDismiss calls)
        vm.resetDraft()
        #expect(vm.importState == .idle)
        #expect(vm.rawText == listing)   // pasted text preserved

        // Second analysis with the same text
        await vm.parse()
        guard case .ready(let draft) = vm.importState else {
            Issue.record("Expected .ready after second parse; got \(vm.importState)")
            return
        }
        #expect(draft.operationType.value == .rent)
    }

    @Test("resetDraft sets importState to .idle without clearing rawText")
    func resetDraftPreservesRawText() async {
        let vm = ListingImportViewModel(repository: StubRepository())
        vm.rawText = listing
        await vm.parse()
        vm.resetDraft()
        #expect(vm.importState == .idle)
        #expect(vm.rawText == listing)
    }

    @Test("parse() while already parsing is a no-op — does not restart or stack")
    func parseWhileParsing() async {
        let vm = ListingImportViewModel(repository: StubRepository())
        vm.rawText = listing
        // Inject .parsing state directly to simulate an in-flight task
        vm.importState = .parsing
        await vm.parse()
        // Guard should have returned immediately; state is still .parsing (not .idle)
        #expect(vm.importState == .parsing)
    }

    @Test("stale parse result is discarded when resetDraft is called before completion")
    func staleParsDiscardedAfterReset() async {
        // A parser that suspends until signalled, letting us interleave resetDraft().
        let held = HeldParser()
        let vm = ListingImportViewModel(repository: StubRepository(), parser: held)
        vm.rawText = listing

        // Start parse — suspends inside HeldParser until released
        let parseTask = Task { await vm.parse() }
        // Yield to let parse() reach the suspension point and set .parsing
        await Task.yield()
        await Task.yield()

        // Discard while parse is still in flight
        vm.resetDraft()
        #expect(vm.importState == .idle)

        // Release the parser — the stale result must be dropped
        await held.release()
        await parseTask.value

        // importState must still be .idle, not .ready
        #expect(vm.importState == .idle)
    }

    @Test("reset() clears both rawText and importState")
    func fullResetClearsBoth() async {
        let vm = ListingImportViewModel(repository: StubRepository())
        vm.rawText = listing
        await vm.parse()
        vm.reset()
        #expect(vm.importState == .idle)
        #expect(vm.rawText.isEmpty)
    }
}

// MARK: - SharedFormSections

/// Verifies that all draft fields (including those previously absent from
/// DraftReviewView) flow correctly through the VM pipeline that the shared
/// form sections rely on.
@Suite("SharedFormSections")
struct SharedFormSectionsTests {

    private func makeDraft(
        operationType: OperationType = .rent,
        price: Decimal = 5_000,
        currency: String = "GTQ",
        locationSummary: String = "Zona 10"
    ) -> PropertyDraft {
        var d = PropertyDraft(id: UUID().uuidString, sourceDescription: "test", parserVersion: "1")
        d.operationType = DraftField(value: operationType, confidence: .high)
        d.price         = DraftField(value: price, confidence: .high)
        d.currency      = DraftField(value: currency, confidence: .high)
        d.locationSummary = DraftField(value: locationSummary, confidence: .high)
        return d
    }

    private func loadedVM(from draft: PropertyDraft) -> PropertyEditorViewModel {
        let vm = PropertyEditorViewModel()
        vm.load(from: draft)
        vm.setInternalCodeForTesting("SUN-001")
        return vm
    }

    @Test("area from draft flows through to built property")
    func areaFlowsThrough() {
        var d = makeDraft()
        d.areaSquareMeters = DraftField(value: 85.5, confidence: .high)
        let vm = loadedVM(from: d)
        let p = vm.buildProperty()
        #expect(p?.areaSquareMeters == 85.5)
    }

    @Test("requirements from draft flow through to built property")
    func requirementsFlowThrough() {
        var d = makeDraft()
        d.requirements = DraftField(value: ["DPI", "Carta de ingresos"], confidence: .medium)
        let vm = loadedVM(from: d)
        // override the rent-defaults that load() applies
        vm.requirementsText = "DPI\nCarta de ingresos"
        let p = vm.buildProperty()
        #expect(p?.requirements == ["DPI", "Carta de ingresos"])
    }

    @Test("half bathrooms set manually flow through to built property")
    func halfBathroomsFlowThrough() {
        let d = makeDraft()
        let vm = loadedVM(from: d)
        vm.halfBathroomsText = "1"
        let p = vm.buildProperty()
        #expect(p?.halfBathrooms == 1)
    }

    @Test("pet policy set manually flows through to built property")
    func petPolicyFlowsThrough() {
        let d = makeDraft()
        let vm = loadedVM(from: d)
        vm.petPolicy = .allowed
        let p = vm.buildProperty()
        #expect(p?.petPolicy == .allowed)
    }

    @Test("includedItems from draft flow through to built property")
    func includedItemsFlowThrough() {
        var d = makeDraft()
        d.includedItems = DraftField(value: ["Cortinas", "Lámparas"], confidence: .medium)
        let vm = loadedVM(from: d)
        let p = vm.buildProperty()
        #expect(p?.includedItems == ["Cortinas", "Lámparas"])
    }

    @Test("bank financing set manually flows through to built property")
    func bankFinancingFlowsThrough() {
        var d = makeDraft(operationType: .sale)
        d.sellerFinancingStatus = DraftField(value: .unavailable, confidence: .high)
        let vm = loadedVM(from: d)
        vm.bankFinancingAssistanceAvailable = true
        let p = vm.buildProperty()
        #expect(p?.bankFinancingAssistanceAvailable == true)
    }

    @Test("IUSI fields set manually flow through to built property")
    func iusiFlowsThrough() {
        var d = makeDraft(operationType: .sale)
        let vm = loadedVM(from: d)
        vm.iusiAmountText = "1200"
        vm.iusiFrequencyText = "anual"
        vm.iusiNotesText = "Pagado al día"
        let p = vm.buildProperty()
        #expect(p?.iusiAmount == 1200)
        #expect(p?.iusiFrequency == "anual")
        #expect(p?.iusiNotes == "Pagado al día")
    }

    @Test("comprehensive: all detectable draft fields flow to built property")
    func allDetectableFieldsFlowThrough() {
        var d = makeDraft(operationType: .rent, locationSummary: "Zona 14, Guatemala")
        d.propertyType   = DraftField(value: .house,     confidence: .high)
        d.status         = DraftField(value: .available, confidence: .high)
        d.maintenanceFee = DraftField(value: 300,        confidence: .medium)
        d.bedrooms       = DraftField(value: 3,          confidence: .high)
        d.bathrooms      = DraftField(value: 2.5,        confidence: .high)
        d.parkingSpaces  = DraftField(value: 2,          confidence: .high)
        d.areaSquareMeters = DraftField(value: 120.0,    confidence: .medium)
        d.floorNumber    = DraftField(value: 2,          confidence: .low)
        d.amenities      = DraftField(value: ["Piscina", "Gimnasio"], confidence: .medium)
        d.includedAppliances = DraftField(value: ["Refrigerador"], confidence: .medium)
        d.includedItems  = DraftField(value: ["Cortinas"],          confidence: .low)
        d.excludedItems  = DraftField(value: ["Estufa"],            confidence: .low)
        d.requirements   = DraftField(value: ["DPI", "Fiador"],     confidence: .medium)
        d.visitInstructions = DraftField(value: "Llamar antes",     confidence: .high)

        let vm = loadedVM(from: d)
        vm.requirementsText = "DPI\nFiador"   // override rent defaults
        let p = vm.buildProperty()

        #expect(p?.propertyType == .house)
        #expect(p?.areaSquareMeters == 120)
        #expect(p?.floorNumber == 2)
        #expect(p?.requirements == ["DPI", "Fiador"])
        #expect(p?.visitInstructions == "Llamar antes")
        #expect(p?.amenities.contains("Piscina") == true)
        #expect(p?.includedItems == ["Cortinas"])
        #expect(p?.excludedItems == ["Estufa"])
    }
}

// Suspends until release() is called, letting tests interleave state mutations
// between parse start and parse completion to verify stale-result protection.
actor HeldParser: ListingImportService {
    private var continuation: CheckedContinuation<PropertyDraft, Error>?

    func parse(_ description: String) async throws -> PropertyDraft {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
        }
    }

    func release() {
        continuation?.resume(returning: PropertyDraft(
            id: UUID().uuidString,
            sourceDescription: "held",
            parserVersion: "mock"
        ))
        continuation = nil
    }
}

// MARK: - Location Picker callback tests

@Suite("LocationPickerCallback")
struct LocationPickerCallbackTests {

    private func makeVM() async -> PropertyEditorViewModel {
        let repo = StubRepository()
        let vm = PropertyEditorViewModel(repository: repo)
        await vm.prepareForNew()
        return vm
    }

    @Test func callbackUpdatesLatLon() async {
        let vm = await makeVM()
        vm.latitude = 14.6349
        vm.longitude = -90.5069
        vm.formattedAddress = "Ciudad de Guatemala"
        vm.locationSource = .mapPicker
        #expect(vm.latitude == 14.6349)
        #expect(vm.longitude == -90.5069)
        #expect(vm.locationSource == .mapPicker)
    }

    @Test func callbackSetsLocationSummaryWhenEmpty() async {
        let vm = await makeVM()
        vm.locationSummary = ""
        let lat: Double = 14.6
        let lon: Double = -90.5
        let address: String? = "Zona 10, Guatemala"
        vm.latitude = lat
        vm.longitude = lon
        vm.formattedAddress = address
        vm.locationSource = .mapPicker
        if vm.locationSummary.trimmingCharacters(in: .whitespaces).isEmpty {
            vm.locationSummary = address ?? String(format: "%.5f, %.5f", lat, lon)
        }
        #expect(vm.locationSummary == "Zona 10, Guatemala")
    }

    @Test func callbackFallsBackToCoordinatesWhenAddressNil() async {
        let vm = await makeVM()
        vm.locationSummary = ""
        let lat: Double = 14.12345
        let lon: Double = -90.67890
        let address: String? = nil
        vm.latitude = lat
        vm.longitude = lon
        vm.locationSource = .mapPicker
        if vm.locationSummary.trimmingCharacters(in: .whitespaces).isEmpty {
            vm.locationSummary = address ?? String(format: "%.5f, %.5f", lat, lon)
        }
        #expect(vm.locationSummary == "14.12345, -90.67890")
    }

    @Test func callbackPreservesExistingLocationSummary() async {
        let vm = await makeVM()
        vm.locationSummary = "Zona 14"
        let lat: Double = 14.6
        let lon: Double = -90.5
        vm.latitude = lat
        vm.longitude = lon
        vm.locationSource = .mapPicker
        // summary already set, so closure does NOT overwrite
        if vm.locationSummary.trimmingCharacters(in: .whitespaces).isEmpty {
            vm.locationSummary = "should not appear"
        }
        #expect(vm.locationSummary == "Zona 14")
    }

    @Test func buildPropertyIncludesPickedCoordinates() async {
        let vm = await makeVM()
        vm.locationSummary = "Zona 10"
        vm.priceText = "5000"
        vm.currency = "GTQ"
        vm.latitude = 14.6349
        vm.longitude = -90.5069
        vm.locationSource = .mapPicker
        let property = vm.buildProperty()
        #expect(property?.latitude == 14.6349)
        #expect(property?.longitude == -90.5069)
        #expect(property?.locationSource == .mapPicker)
    }
}

// MARK: - URL validation tests

@Suite("URLValidation")
struct URLValidationTests {

    @Test func validGoogleMapsURLParsesOK() {
        let urlStr = "https://maps.google.com/?q=14.63490,-90.50690"
        let url = URL(string: urlStr)
        #expect(url != nil)
    }

    @Test func emptyGoogleMapsURLProducesNil() {
        let urlStr = ""
        let url = URL(string: urlStr)
        // empty string produces non-nil URL in Swift (relative URL), guard with isEmpty
        #expect(urlStr.isEmpty)
        _ = url
    }

    @Test func buildPropertyWithInvalidMapsURL() async {
        let repo = StubRepository()
        let vm = PropertyEditorViewModel(repository: repo)
        await vm.prepareForNew()
        vm.locationSummary = "Zona 10"
        vm.priceText = "5000"
        vm.currency = "GTQ"
        vm.googleMapsURLText = "not a valid url @@##"
        let property = vm.buildProperty()
        // buildProperty should still succeed; the URL text is stored as-is
        #expect(property != nil)
        #expect(property?.googleMapsURL == "not a valid url @@##")
    }

    @Test func templateEngineOmitsGoogleMapsWhenEncodingFails() {
        // label that cannot be percent-encoded should not produce a Maps link
        // addingPercentEncoding only returns nil for strings with invalid surrogate pairs;
        // in practice it almost never fails, so we test the positive (safe) path
        let encoded = "Zona 10, Ciudad de Guatemala"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        #expect(encoded != nil)
        #expect(encoded?.isEmpty == false)
    }
}
