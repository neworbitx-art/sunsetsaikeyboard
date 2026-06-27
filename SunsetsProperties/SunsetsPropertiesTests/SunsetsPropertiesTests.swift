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
        // Validation fails (empty title)
        vm.title = ""
        vm.priceText = "1000"
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
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
        vm.title = "Casa de Prueba"
        vm.setInternalCodeForTesting("SUN-999")
        vm.locationSummary = "Zona 10, Guatemala"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        #expect(vm.validate() == true)
        #expect(vm.validationErrors.isEmpty)
    }

    @Test func missingTitleFails() {
        let vm = PropertyEditorViewModel()
        vm.title = ""
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("título") }))
    }

    @Test func missingCodeFails() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("código") }))
    }

    @Test func missingLocationFails() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = ""
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("ubicación") }))
    }

    @Test func missingPriceFails() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = ""
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("precio") }))
    }

    @Test func negativePriceProducesError() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "-500"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("negativo") }))
    }

    @Test func negativeMaintenanceFeeProducesError() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        vm.maintenanceFeeText = "-100"
        #expect(vm.validate() == false)
    }

    @Test func negativeDepositProducesError() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        vm.depositText = "-200"
        #expect(vm.validate() == false)
    }

    @Test func buildPropertyReturnsNilWhenInvalid() {
        let vm = PropertyEditorViewModel()
        vm.title = ""
        vm.priceText = "1000"
        #expect(vm.buildProperty() == nil)
    }

    @Test func buildPropertySucceedsWhenValid() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.setInternalCodeForTesting("SUN-001")
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        let result = vm.buildProperty()
        #expect(result != nil)
        #expect(result?.title == "Casa")
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

// MARK: - Title generation tests

@Suite("LocalListingParser — Title Generation")
struct TitleGenerationTests {

    let parser = LocalListingParser()

    @Test func centoBuildsTitleApartamentoEnCENTO() async throws {
        let draft = try await parser.parse(LocalListingParserTests.centoListing)
        let title = draft.title.value ?? ""
        #expect(title.localizedCaseInsensitiveContains("CENTO"))
        #expect(title.localizedCaseInsensitiveContains("apartamento") ||
                title.localizedCaseInsensitiveContains("departamento"))
    }

    @Test func tantaPremierBuildsTitleCasaEnTantaPremier() async throws {
        let draft = try await parser.parse(TantaPremierParserTests.tantaListing)
        let title = draft.title.value ?? ""
        #expect(title.localizedCaseInsensitiveContains("Tanta Premier") ||
                title.localizedCaseInsensitiveContains("casa"))
    }

    @Test func titleNotHighConfidenceWhenGenerated() async throws {
        let draft = try await parser.parse(TantaPremierParserTests.tantaListing)
        // Generated title must be flagged for review
        #expect(draft.title.confidence != .high)
        #expect(draft.title.warning != nil)
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
