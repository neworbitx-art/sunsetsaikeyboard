import Foundation

// MARK: - Template Engine (keyboard extension)
// Generates deterministic Spanish replies from a KeyboardSafeProperty.

enum TemplateEngine {

    // MARK: - Category labels (matches TemplateCategory in main app)

    static let categories: [(id: String, label: String)] = [
        ("generalInfo",     "Información general"),
        ("availability",    "Disponibilidad"),
        ("price",           "Precio"),
        ("location",        "Ubicación"),
        ("requirements",    "Requisitos"),
        ("characteristics", "Características"),
        ("amenities",       "Amenidades"),
        ("petPolicy",       "Mascotas"),
        ("purchaseInfo",    "Información de compra"),
        ("visit",           "Agendar visita"),
        ("followUp",        "Seguimiento"),
    ]

    // Returns only the categories applicable to the selected property.
    static func applicableCategories(for property: KeyboardSafeProperty) -> [(id: String, label: String)] {
        categories.filter { cat in
            if cat.id == "purchaseInfo" { return property.isForSale }
            return true
        }
    }

    // MARK: - Generate reply

    static func generate(categoryID: String, for property: KeyboardSafeProperty, employeeName: String? = nil) -> String {
        switch categoryID {
        case "generalInfo":     return generalInfo(for: property)
        case "availability":    return availability(for: property)
        case "price":           return price(for: property)
        case "location":        return location(for: property)
        case "requirements":    return requirements(for: property)
        case "characteristics": return characteristics(for: property)
        case "amenities":       return amenities(for: property)
        case "petPolicy":       return pets(for: property)
        case "purchaseInfo":    return purchaseInfo(for: property)
        case "visit":           return visit(for: property)
        case "followUp":        return followUp(for: property, employeeName: employeeName)
        default:                return general(for: property)
        }
    }

    // MARK: - General information (combined)

    static func generalInfo(for property: KeyboardSafeProperty) -> String {
        var sections: [String] = []

        if property.status != "available" {
            sections.append("⚠️ Esta propiedad está \(property.statusLabel.lowercased()) y no está disponible actualmente.")
        }

        // Primary body: full sanitized listing text (preferred over short description)
        let listingLower: String
        if let listing = property.publicListingText,
           !listing.trimmingCharacters(in: .whitespaces).isEmpty {
            sections.append(listing.trimmingCharacters(in: .whitespaces))
            listingLower = listing.lowercased()
        } else if let desc = property.publicDescription,
                  !desc.trimmingCharacters(in: .whitespaces).isEmpty {
            sections.append(desc.trimmingCharacters(in: .whitespaces))
            listingLower = desc.lowercased()
        } else {
            listingLower = ""
        }

        // Append price only when not already present in listing body
        let hasPriceInListing = listingLower.contains("precio") ||
                                listingLower.contains(" q.") || listingLower.contains("gtq") ||
                                listingLower.contains("usd")
        if !hasPriceInListing {
            let priceStr = fmt(property.price, currency: property.currency)
            var priceSection: String
            switch property.operationType {
            case "rent":  priceSection = "\(priceStr) mensuales."
            case "sale":  priceSection = "\(priceStr)."
            default:      priceSection = "\(priceStr)."
            }
            if let fee = property.maintenanceFee {
                let feeStr = fmt(fee, currency: property.currency)
                priceSection += property.maintenanceIncluded
                    ? " Mantenimiento (\(feeStr)/mes) incluido."
                    : " Mantenimiento \(feeStr)/mes no incluido."
            }
            sections.append("Precio: \(priceSection)")
        }

        // Append requirements only when not already present
        if !listingLower.contains("requisito") {
            let reqs = property.requirements.filter { !$0.isEmpty }
            if reqs.isEmpty {
                sections.append("Requisitos: Permítame confirmar los requisitos específicos de esta propiedad.")
            } else {
                sections.append("Requisitos: \(reqs.joined(separator: ", ")).")
            }
        }

        // Append maps links when approved location is available
        let maps = buildMapsLinks(for: property)
        if !maps.isEmpty { sections.append(maps) }

        return sections.joined(separator: "\n\n")
    }

    private static func buildMapsLinks(for property: KeyboardSafeProperty) -> String {
        var parts: [String] = []
        if let lat = property.latitude, let lon = property.longitude {
            let gmURL = String(format: "https://www.google.com/maps/search/?api=1&query=%.6f,%.6f", lat, lon)
            let wzURL = String(format: "https://waze.com/ul?ll=%.6f,%.6f&navigate=yes", lat, lon)
            parts.append("Google Maps:\n\(gmURL)")
            parts.append("Waze:\n\(wzURL)")
        } else if let wzURL = property.wazeURL, !wzURL.isEmpty {
            let label = property.publicLocationLabel ?? property.locationSummary
            if let encoded = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                parts.append("Google Maps:\nhttps://www.google.com/maps/search/?api=1&query=\(encoded)")
            }
            parts.append("Waze:\n\(wzURL)")
        } else if property.isExactLocationShareable, let url = property.googleMapsURL, !url.isEmpty {
            parts.append("Google Maps:\n\(url)")
        }
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Availability

    static func availability(for property: KeyboardSafeProperty) -> String {
        switch property.status {
        case "available":
            return "Sí, la propiedad continúa disponible. ¿Le gustaría que coordinemos una visita?"
        case "reserved":
            return "La propiedad \(property.displayTitle) actualmente se encuentra reservada. ¿Le puedo compartir alguna otra opción disponible?"
        case "rented":
            return "La propiedad \(property.displayTitle) actualmente se encuentra rentada. ¿Le puedo compartir alguna otra opción disponible?"
        case "sold":
            return "La propiedad \(property.displayTitle) ha sido vendida. ¿Le puedo compartir alguna otra opción disponible?"
        default:
            return "La propiedad \(property.displayTitle) no está disponible en este momento. ¿Le puedo compartir alguna otra opción?"
        }
    }

    // MARK: - Price

    static func price(for property: KeyboardSafeProperty) -> String {
        var parts: [String] = []
        let priceStr = fmt(property.price, currency: property.currency)

        switch property.operationType {
        case "sale":
            parts.append("El precio de venta es de \(priceStr).")
        case "rent":
            parts.append("El precio de renta es de \(priceStr) mensuales.")
        default:
            parts.append("El precio es de \(priceStr).")
        }

        if let fee = property.maintenanceFee {
            let feeStr = fmt(fee, currency: property.currency)
            if property.maintenanceIncluded {
                parts.append("El mantenimiento de \(feeStr) mensuales está incluido en el precio.")
            } else {
                parts.append("El mantenimiento es de \(feeStr) mensuales (no incluido).")
            }
        }

        if property.isForRent, let deposit = property.deposit {
            let depStr = fmt(deposit, currency: property.currency)
            parts.append("Se requiere depósito de \(depStr).")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Location

    static func location(for property: KeyboardSafeProperty) -> String {
        let label = property.displayLocation
        var parts: [String] = ["📍 Ubicación: \(label)"]

        if let lat = property.latitude, let lon = property.longitude {
            parts.append("Google Maps:\n\(String(format: "https://www.google.com/maps/search/?api=1&query=%.6f,%.6f", lat, lon))")
            parts.append("Waze:\n\(String(format: "https://waze.com/ul?ll=%.6f,%.6f&navigate=yes", lat, lon))")
        } else if let wzURL = property.wazeURL, !wzURL.isEmpty {
            let encoded = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            parts.append("Google Maps:\nhttps://www.google.com/maps/search/?api=1&query=\(encoded)")
            parts.append("Waze:\n\(wzURL)")
        } else if property.isExactLocationShareable, let url = property.googleMapsURL, !url.isEmpty {
            parts.append("Google Maps:\n\(url)")
        }

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Requirements

    static func requirements(for property: KeyboardSafeProperty) -> String {
        let reqs = property.requirements.filter { !$0.isEmpty }
        guard !reqs.isEmpty else {
            return "Permítame confirmar los requisitos específicos de esta propiedad."
        }
        let list = reqs.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        return "Los requisitos son:\n\(list)"
    }

    // MARK: - Characteristics

    static func characteristics(for property: KeyboardSafeProperty) -> String {
        var lines: [String] = []

        if property.bedrooms > 0 {
            lines.append("• \(property.bedrooms) recámara\(property.bedrooms == 1 ? "" : "s")")
        }
        if property.bathrooms > 0 {
            lines.append("• \(fmtDouble(property.bathrooms)) baño\(property.bathrooms == 1 ? "" : "s")")
        }
        if property.parkingSpaces > 0 {
            lines.append("• \(property.parkingSpaces) lugar\(property.parkingSpaces == 1 ? "" : "es") de estacionamiento")
        }
        if property.areaSquareMeters > 0 {
            lines.append("• \(fmtDouble(property.areaSquareMeters)) m²")
        }

        let included = (property.includedAppliances + property.includedItems).filter { !$0.isEmpty }
        if !included.isEmpty {
            lines.append("• Incluye: \(included.joined(separator: ", "))")
        }
        let excluded = property.excludedItems.filter { !$0.isEmpty }
        if !excluded.isEmpty {
            lines.append("• No incluye: \(excluded.joined(separator: ", "))")
        }

        guard !lines.isEmpty else {
            return "Permítame confirmar las características específicas de esta propiedad."
        }
        return "\(property.displayTitle) cuenta con:\n\(lines.joined(separator: "\n"))"
    }

    // MARK: - Amenities

    static func amenities(for property: KeyboardSafeProperty) -> String {
        let ams = property.amenities.filter { !$0.isEmpty }
        guard !ams.isEmpty else {
            return "Permítame confirmar las amenidades de esta propiedad."
        }
        return "El inmueble cuenta con las siguientes amenidades: \(ams.joined(separator: ", "))."
    }

    // MARK: - Pets

    static func pets(for property: KeyboardSafeProperty) -> String {
        switch property.petPolicy {
        case "allowed":               return "Se acepta mascota."
        case "notAllowed":            return "No se aceptan mascotas."
        case "subjectToCaseAnalysis": return "Sujeto a análisis de caso."
        default:                      return "Permítame confirmar la política de mascotas de esta propiedad."
        }
    }

    // MARK: - Purchase information

    static func purchaseInfo(for property: KeyboardSafeProperty) -> String {
        guard property.isForSale else {
            return "Esta información aplica únicamente para propiedades en venta."
        }

        var parts: [String] = []
        parts.append("El precio de venta es de \(fmt(property.price, currency: property.currency)).")

        switch property.sellerFinancingStatus {
        case "available":
            parts.append("Esta propiedad ofrece financiamiento directo con el vendedor.")
        case "unavailable":
            var bankPart = "No ofrece financiamiento directo. Sin embargo, se puede gestionar financiamiento bancario."
            if property.bankFinancingAssistanceAvailable {
                bankPart += " Sunsets puede asistirle en el proceso. Los porcentajes de enganche, avalúo, elegibilidad y aprobación dependen de la institución financiera."
            }
            parts.append(bankPart)
            if property.fhaEligibility == "eligible" {
                parts.append("Esta propiedad es elegible para financiamiento FHA, que permite un enganche de tan solo el 5%.")
            }
        default:
            if property.bankFinancingAssistanceAvailable {
                parts.append("Se puede gestionar financiamiento bancario. Sunsets puede asistirle en el proceso. Los porcentajes de enganche, avalúo, elegibilidad y aprobación dependen de la institución financiera.")
            }
        }

        if let iusiAmt = property.iusiAmount {
            var iusiPart = "El IUSI de esta propiedad es de \(fmt(iusiAmt, currency: property.currency))"
            if let freq = property.iusiFrequency, !freq.isEmpty { iusiPart += " (\(freq))" }
            if let verifiedAt = property.iusiVerifiedAt { iusiPart += ", verificado el \(fmtDate(verifiedAt))" }
            iusiPart += "."
            parts.append(iusiPart)
        }

        if let notes = property.iusiNotes, !notes.isEmpty { parts.append(notes) }
        if let finNotes = property.financingNotes, !finNotes.isEmpty { parts.append(finNotes) }

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Visit

    static func visit(for property: KeyboardSafeProperty) -> String {
        if let instructions = property.visitInstructions, !instructions.isEmpty {
            return "Para coordinar una visita a \(property.displayTitle): \(instructions)"
        }
        return "Con gusto le agendo una visita a \(property.displayTitle). ¿Qué fecha y horario le vendría bien?"
    }

    // MARK: - Follow-up

    static func followUp(for property: KeyboardSafeProperty, employeeName: String? = nil) -> String {
        let greeting = currentGreeting()
        if let name = employeeName, !name.isEmpty {
            return "\(greeting), soy \(name) de Sunsets Real Estate. Le escribo para dar seguimiento a su consulta sobre \(property.displayTitle). ¿Tiene alguna pregunta o le gustaría coordinar una visita?"
        }
        return "\(greeting), le escribimos de Sunsets Real Estate para dar seguimiento a su consulta sobre \(property.displayTitle). ¿Tiene alguna pregunta o le gustaría coordinar una visita?"
    }

    // MARK: - General

    static func general(for property: KeyboardSafeProperty) -> String {
        let label = property.displayLocation
        let priceStr = fmt(property.price, currency: property.currency)
        return "\(property.displayTitle) (\(property.internalCode)) — \(label). \(property.operationLabel): \(priceStr)."
    }

    // MARK: - Helpers

    private static func fmt(_ amount: Decimal, currency code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "es_GT")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(code) \(amount)"
    }

    private static func fmtDouble(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private static func fmtDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_GT")
        return formatter.string(from: date)
    }

    private static func currentGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Buenos días" }
        if hour < 19 { return "Buenas tardes" }
        return "Buenas noches"
    }
}
