import Foundation
import Observation

@Observable
final class PropertyEditorViewModel {

    // Editable string fields for forms
    var title: String = ""
    var internalCode: String = ""
    var operationType: OperationType = .rent
    var status: PropertyStatus = .available
    var priceText: String = ""
    var currency: String = "GTQ"
    var maintenanceFeeText: String = ""
    var maintenanceIncluded: Bool = false
    var depositText: String = ""
    var locationSummary: String = ""
    var neighborhood: String = ""
    var city: String = ""
    var state: String = ""
    var country: String = "Guatemala"
    var bedroomsText: String = "1"
    var bathroomsText: String = "1"
    var halfBathroomsText: String = ""
    var parkingSpacesText: String = "0"
    var areaText: String = ""
    var amenitiesText: String = ""
    var appliancesText: String = ""
    var requirementsText: String = ""
    var petPolicy: PetPolicy = .notAllowed
    var visitInstructions: String = ""
    var isFavorite: Bool = false

    var validationErrors: [String] = []

    private var existingId: String?
    private var createdAt: Date = Date()

    func load(from property: Property) {
        existingId = property.id
        createdAt = property.createdAt
        title = property.title
        internalCode = property.internalCode
        operationType = property.operationType
        status = property.status
        priceText = property.price == 0 ? "" : plainDecimal(property.price)
        currency = property.currency
        maintenanceFeeText = property.maintenanceFee.map { plainDecimal($0) } ?? ""
        maintenanceIncluded = property.maintenanceIncluded
        depositText = property.deposit.map { plainDecimal($0) } ?? ""
        locationSummary = property.locationSummary
        neighborhood = property.neighborhood ?? ""
        city = property.city ?? ""
        state = property.state ?? ""
        country = property.country
        bedroomsText = "\(property.bedrooms)"
        bathroomsText = AppFormatters.bathrooms(property.bathrooms)
        halfBathroomsText = property.halfBathrooms.map { "\($0)" } ?? ""
        parkingSpacesText = "\(property.parkingSpaces)"
        areaText = property.areaSquareMeters == 0 ? "" : plainDouble(property.areaSquareMeters)
        amenitiesText = property.amenities.joined(separator: "\n")
        appliancesText = property.includedAppliances.joined(separator: "\n")
        requirementsText = property.requirements.joined(separator: "\n")
        petPolicy = property.petPolicy
        visitInstructions = property.visitInstructions ?? ""
        isFavorite = property.isFavorite
    }

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

    func buildProperty() -> Property? {
        guard validate() else { return nil }
        guard let price = parseDecimal(priceText) else { return nil }
        let now = Date()
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
            neighborhood: nilIfEmpty(neighborhood),
            city: nilIfEmpty(city),
            state: nilIfEmpty(state),
            country: country.trimmingCharacters(in: .whitespaces),
            bedrooms: Int(bedroomsText) ?? 0,
            bathrooms: Double(bathroomsText) ?? 1,
            halfBathrooms: Int(halfBathroomsText),
            parkingSpaces: Int(parkingSpacesText) ?? 0,
            areaSquareMeters: Double(areaText) ?? 0,
            amenities: parseLines(amenitiesText),
            includedAppliances: parseLines(appliancesText),
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
        text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func nilIfEmpty(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }

    private func plainDecimal(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        return ns.stringValue
    }

    private func plainDouble(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(value)
    }
}
