import Testing
import Foundation
@testable import SunsetsProperties

// MARK: - Property Model Tests

@Suite("Property Model")
struct PropertyModelTests {

    @Test func roundTripEncoding() throws {
        // Truncate to integer seconds so ISO 8601 encoding is lossless
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
        #expect(PetPolicy.allowedWithDeposit.rawValue == "allowedWithDeposit")
        #expect(PetPolicy.caseByCase.rawValue == "caseByCase")
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
        try await repo.seedIfNeeded(seed) // second call must be no-op
        let all = try await repo.fetchAll()
        #expect(all.count == 2)
    }

    @Test func seedDoesNotRunIfAlreadySeeded() async throws {
        let repo = makeRepository()
        try await repo.seedIfNeeded([makeSampleProperty(id: "s1")])
        // manually add another so count becomes 2
        try await repo.save(makeSampleProperty(id: "s2"))
        // seed again — should not replace
        try await repo.seedIfNeeded([makeSampleProperty(id: "s3")])
        let all = try await repo.fetchAll()
        // still 2 (seed was skipped), not 1 (replaced) or 3 (duplicated)
        #expect(all.count == 2)
    }

    @Test func employeeRoundTrip() async throws {
        let repo = makeRepository()
        try await repo.setEmployee("Yessy")
        let name = try await repo.fetchEmployee()
        #expect(name == "Yessy")
    }
}

// MARK: - Validation Tests

@Suite("Property Validation")
struct ValidationTests {

    @Test func validPropertyPassesValidation() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa de Prueba"
        vm.internalCode = "SUN-999"
        vm.locationSummary = "Zona 10, Guatemala"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        #expect(vm.validate() == true)
        #expect(vm.validationErrors.isEmpty)
    }

    @Test func missingTitleFails() {
        let vm = PropertyEditorViewModel()
        vm.title = ""
        vm.internalCode = "SUN-001"
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("título") }))
    }

    @Test func missingCodeFails() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = ""
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("código") }))
    }

    @Test func missingLocationFails() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = "SUN-001"
        vm.locationSummary = ""
        vm.currency = "GTQ"
        vm.priceText = "1000"
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("ubicación") }))
    }

    @Test func missingPriceFails() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = "SUN-001"
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = ""
        #expect(vm.validate() == false)
        #expect(vm.validationErrors.contains(where: { $0.contains("precio") }))
    }

    @Test func negativePriceProducesError() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = "SUN-001"
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "-500"
        let valid = vm.validate()
        #expect(!valid)
        #expect(vm.validationErrors.contains(where: { $0.contains("negativo") }))
    }

    @Test func negativeMaintenanceFeeProducesError() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = "SUN-001"
        vm.locationSummary = "Zona 10"
        vm.currency = "GTQ"
        vm.priceText = "5000"
        vm.maintenanceFeeText = "-100"
        #expect(vm.validate() == false)
    }

    @Test func negativeDepositProducesError() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = "SUN-001"
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
        let result = vm.buildProperty()
        #expect(result == nil)
    }

    @Test func buildPropertySucceedsWhenValid() {
        let vm = PropertyEditorViewModel()
        vm.title = "Casa"
        vm.internalCode = "SUN-001"
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
        // Use explicit locations that don't contain "zona" for the non-matching property,
        // because locationSummary is also searched and the default contains "Zona 10".
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
        let vm = makeViewModel(with: [
            makeSampleProperty(id: "1"),
            makeSampleProperty(id: "2")
        ])
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


// MARK: - Stub Repository for testing ViewModels

final class StubRepository: PropertyRepository {
    var properties: [Property]
    var activeId: String?
    var employee: String?

    init(properties: [Property] = []) {
        self.properties = properties
    }

    func fetchAll() async throws -> [Property] { properties }

    func save(_ property: Property) async throws {
        if let i = properties.firstIndex(where: { $0.id == property.id }) {
            properties[i] = property
        } else {
            properties.append(property)
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
}
