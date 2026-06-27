import Foundation

// MARK: - Protocol

protocol ListingImportService: Sendable {
    func parse(_ description: String) async throws -> PropertyDraft
}

// MARK: - LocalListingParser

// Deterministic, offline, no network calls.
// Supports emoji-prefixed section headers, multi-level bedroom counting,
// and Guatemala real-estate vocabulary.
struct LocalListingParser: ListingImportService {

    static let version = "local-v2"

    func parse(_ description: String) async throws -> PropertyDraft {
        var draft = PropertyDraft(sourceDescription: description, parserVersion: Self.version)
        let text = description
        let lower = text.lowercased()
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        draft.operationType       = detectOperationType(lower)
        draft.price               = detectPrice(lower)
        draft.currency            = detectCurrency(lower)
        draft.maintenanceIncluded = detectMaintenanceIncluded(lower)
        draft.maintenanceFee      = detectMaintenanceFee(lower)
        draft.deposit             = detectDeposit(lower)
        draft.bedrooms            = detectBedrooms(lower, lines: lines)
        draft.bathrooms           = detectBathrooms(lower)
        draft.parkingSpaces       = detectParking(lower)
        draft.floorNumber         = detectFloor(lower, lines: lines)
        draft.areaSquareMeters    = detectArea(lower)
        draft.amenities           = detectAmenities(lower, lines: lines)
        draft.includedAppliances  = detectIncludedAppliances(lower, lines: lines)
        draft.includedItems       = detectIncludedItems(lower, lines: lines)
        draft.excludedItems       = detectExcludedItems(lower, lines: lines)
        draft.visitInstructions   = detectVisitInstructions(lower, lines: lines)
        draft.contactInfo         = detectContactInfo(text)
        draft.hashtags            = detectHashtags(text)
        draft.locationSummary     = detectLocation(text, lower: lower, lines: lines)
        draft.title               = detectTitle(lines, lower: lower,
                                                location: draft.locationSummary.value)
        draft.status              = DraftField(value: .available, confidence: .high)

        return draft
    }

    // MARK: - Operation type

    private func detectOperationType(_ lower: String) -> DraftField<OperationType> {
        let hasRent = lower.contains("renta") || lower.contains("alquiler")
        let hasSale = lower.contains("venta") || lower.contains("precio de venta")
        if hasRent && hasSale {
            return DraftField(value: .rentOrSale, confidence: .medium,
                              warning: "Se encontraron 'renta' y 'venta'. Verifique el tipo de operación.")
        } else if hasRent {
            return DraftField(value: .rent, confidence: .high)
        } else if hasSale {
            return DraftField(value: .sale, confidence: .high)
        }
        return DraftField(confidence: .missing, warning: "No se detectó el tipo de operación.")
    }

    // MARK: - Price

    private func detectPrice(_ lower: String) -> DraftField<Decimal> {
        // Match "Q 4,200" "Q4200" "Q1,450,000" "GTQ 4200"
        // Also match "Precio de venta: Q1,450,000"
        if let match = lower.firstMatch(of: /(?:q\.?|gtq)\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)/) {
            let raw = String(match.output.1).replacingOccurrences(of: ",", with: "")
            if let d = Decimal(string: raw), d > 0 {
                return DraftField(value: d, confidence: .high)
            }
        }
        return DraftField(confidence: .missing, warning: "No se detectó el precio.")
    }

    // MARK: - Currency

    private func detectCurrency(_ lower: String) -> DraftField<String> {
        if lower.contains("gtq") || lower.contains("quetzal") {
            return DraftField(value: "GTQ", confidence: .high)
        }
        if lower.contains("usd") || lower.contains("dólar") || lower.contains("dolar") {
            return DraftField(value: "USD", confidence: .high)
        }
        if lower.firstMatch(of: /q\.?\s*\d/) != nil {
            return DraftField(value: "GTQ", confidence: .medium)
        }
        return DraftField(value: "GTQ", confidence: .low, warning: "Moneda inferida como GTQ; verifique.")
    }

    // MARK: - Maintenance

    private func detectMaintenanceIncluded(_ lower: String) -> DraftField<Bool> {
        if lower.contains("mantenimiento incluido") ||
           lower.contains("mantenimiento: incluido") ||
           lower.contains("cuota incluida") ||
           lower.contains("sin costo adicional de mantenimiento") {
            return DraftField(value: true, confidence: .high)
        }
        if lower.contains("mantenimiento aparte") || lower.contains("más mantenimiento") {
            return DraftField(value: false, confidence: .high)
        }
        if lower.contains("mantenimiento") {
            return DraftField(value: false, confidence: .medium,
                              warning: "Se mencionó mantenimiento pero no está claro si está incluido.")
        }
        return DraftField(value: false, confidence: .low,
                          warning: "No se menciona mantenimiento.")
    }

    private func detectMaintenanceFee(_ lower: String) -> DraftField<Decimal> {
        if let match = lower.firstMatch(of: /mantenimiento[:\s]+q\.?\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)/) {
            let raw = String(match.output.1).replacingOccurrences(of: ",", with: "")
            if let d = Decimal(string: raw), d > 0 {
                return DraftField(value: d, confidence: .high)
            }
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Deposit

    private func detectDeposit(_ lower: String) -> DraftField<Decimal> {
        if let match = lower.firstMatch(of: /(?:depósito|deposito|fianza)[:\s]+q\.?\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)/) {
            let raw = String(match.output.1).replacingOccurrences(of: ",", with: "")
            if let d = Decimal(string: raw), d > 0 {
                return DraftField(value: d, confidence: .high)
            }
        }
        if let match = lower.firstMatch(of: /q\.?\s*(\d{1,3}(?:,\d{3})*)\s+(?:de\s+)?(?:depósito|deposito|fianza)/) {
            let raw = String(match.output.1).replacingOccurrences(of: ",", with: "")
            if let d = Decimal(string: raw), d > 0 {
                return DraftField(value: d, confidence: .high)
            }
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Bedrooms

    private func detectBedrooms(_ lower: String, lines: [String]) -> DraftField<Int> {
        let qualifiers = ["secundar", "adicional", "principal", "extra", "master"]

        // Strategy 1: look for an unqualified standalone count on any line.
        // "3 Recámaras" on its own → high confidence total.
        // "2 habitaciones secundarias" → line contains a qualifier → skip.
        for line in lines {
            let ll = line.lowercased()
            let linePattern = /(\d+)\s+(?:recámaras?|habitaciones?|dormitorios?|cuartos?|bedrooms?)/
            if let match = ll.firstMatch(of: linePattern),
               let n = Int(match.output.1) {
                if !qualifiers.contains(where: { ll.contains($0) }) {
                    return DraftField(value: n, confidence: .high)
                }
            }
        }

        // Strategy 2: written numbers ("dos habitaciones")
        let writtenNums: [(String, Int)] = [
            ("una", 1), ("un", 1), ("dos", 2), ("tres", 3), ("cuatro", 4),
            ("cinco", 5), ("seis", 6), ("siete", 7), ("ocho", 8)
        ]
        let bedroomWords = ["recámara", "habitación", "dormitorio", "cuarto"]
        for (w, n) in writtenNums {
            for word in bedroomWords where lower.contains("\(w) \(word)") {
                return DraftField(value: n, confidence: .medium)
            }
        }

        // Strategy 3: count across floor sections.
        // "Dormitorio/habitación principal" → +1; "2 habitaciones secundarias" → +2.
        var total = 0
        var found = false
        for line in lines {
            let ll = line.lowercased()
            let principalPattern = /(?:dormitorio|recámara|habitación)\s+principal/
            if ll.firstMatch(of: principalPattern) != nil {
                total += 1
                found = true
            }
            let secondaryPattern = /(\d+)\s+(?:habitaciones?|dormitorios?|recámaras?)\s+(?:secundarias?|adicionales?|extras?)/
            if let match = ll.firstMatch(of: secondaryPattern),
               let n = Int(match.output.1) {
                total += n
                found = true
            }
        }
        if found && total > 0 {
            return DraftField(value: total, confidence: .medium,
                              warning: "Recámaras contadas por secciones. Verifique el total.")
        }

        return DraftField(confidence: .missing, warning: "No se detectó el número de recámaras.")
    }

    // MARK: - Bathrooms

    private func detectBathrooms(_ lower: String) -> DraftField<Double> {
        let pattern = /(\d+(?:[.,]\d+)?)\s*(?:baños?|bathrooms?)/
        if let match = lower.firstMatch(of: pattern) {
            let raw = String(match.output.1).replacingOccurrences(of: ",", with: ".")
            if let d = Double(raw) {
                return DraftField(value: d, confidence: .high)
            }
        }
        return DraftField(confidence: .missing, warning: "No se detectó el número de baños.")
    }

    // MARK: - Parking

    private func detectParking(_ lower: String) -> DraftField<Int> {
        // "parqueo para 3 vehículos"
        if let match = lower.firstMatch(of: /parqueo\s+para\s+(\d+)/), let n = Int(match.output.1) {
            return DraftField(value: n, confidence: .high)
        }
        // "3 parqueos / estacionamientos / cajones / garages / espacios de parqueo"
        let pattern = /(\d+)\s*(?:parqueos?|estacionamientos?|cajones?|garages?|espacios?\s+de\s+parqueo|lugares?\s+de\s+parqueo)/
        if let match = lower.firstMatch(of: pattern), let n = Int(match.output.1) {
            return DraftField(value: n, confidence: .high)
        }
        // "N vehículos" after a parking keyword on the same line
        if let match = lower.firstMatch(of: /(\d+)\s*vehículos?/), let n = Int(match.output.1) {
            return DraftField(value: n, confidence: .medium,
                              warning: "Parqueos inferidos de 'N vehículos'. Verifique.")
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Floor

    private func detectFloor(_ lower: String, lines: [String]) -> DraftField<Int> {
        let pattern = /(?:nivel|piso|planta|floor)\s*(\d+)/
        if let match = lower.firstMatch(of: pattern), let n = Int(match.output.1) {
            return DraftField(value: n, confidence: .high)
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Area

    private func detectArea(_ lower: String) -> DraftField<Double> {
        // "140 m²" "140 m2" "140 mts²" "140 metros cuadrados" "140 mts cuadrados"
        let pattern = /(\d+(?:\.\d+)?)\s*(?:m²|m2|mts²|metros?\s+cuadrados?|mts\.?\s+cuadrados?)/
        if let match = lower.firstMatch(of: pattern),
           let d = Double(match.output.1), d > 0 {
            return DraftField(value: d, confidence: .high)
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Amenities

    private func detectAmenities(_ lower: String, lines: [String]) -> DraftField<[String]> {
        let items = extractSection(
            from: lines,
            headers: ["amenidades del residencial", "amenidades del condominio",
                      "amenidades del edificio", "amenidades", "áreas comunes",
                      "amenities", "servicios del condominio",
                      "áreas del condominio", "comodidades"],
            stopWords: ["electrodomésticos", "no incluye", "requisitos", "informes", "depósito",
                        "precio", "contacto"])
        if items.isEmpty { return DraftField(confidence: .missing) }
        return DraftField(value: items, confidence: .medium)
    }

    // MARK: - Included appliances

    private func detectIncludedAppliances(_ lower: String, lines: [String]) -> DraftField<[String]> {
        let items = extractSection(
            from: lines,
            headers: ["electrodomésticos incluidos", "electrodomésticos:", "electrodomésticos",
                      "appliances", "equipamiento:"],
            stopWords: ["no incluye", "excluye", "amenidades", "requisitos", "informes"])
        if items.isEmpty { return DraftField(confidence: .missing) }
        return DraftField(value: items, confidence: .medium)
    }

    // MARK: - Included items

    private func detectIncludedItems(_ lower: String, lines: [String]) -> DraftField<[String]> {
        let items = extractSection(
            from: lines,
            headers: ["incluye", "✨ incluye", "incluye:", "se incluye:",
                      "items incluidos:", "incluye adicionalmente:"],
            stopWords: ["no incluye", "excluye", "amenidades", "requisitos",
                        "electrodomésticos", "precio", "informes"])
        if items.isEmpty { return DraftField(confidence: .missing) }
        return DraftField(value: items, confidence: .medium)
    }

    // MARK: - Excluded items

    private func detectExcludedItems(_ lower: String, lines: [String]) -> DraftField<[String]> {
        let items = extractSection(
            from: lines,
            headers: ["no incluye:", "no incluye", "excluye:", "sin incluir:",
                      "no se incluye:"],
            stopWords: ["amenidades", "electrodomésticos", "requisitos", "informes"])
        if items.isEmpty { return DraftField(confidence: .missing) }
        return DraftField(value: items, confidence: .high)
    }

    // MARK: - Visit instructions

    private func detectVisitInstructions(_ lower: String, lines: [String]) -> DraftField<String> {
        let sectionItems = extractSection(
            from: lines,
            headers: ["informes:", "información:", "contacto:", "para más info",
                      "para agendar", "visitas:"],
            stopWords: ["#"])
        if !sectionItems.isEmpty {
            return DraftField(value: sectionItems.joined(separator: " "), confidence: .medium,
                              warning: "Verifique las instrucciones de visita.")
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Contact info (reference only, not saved to Property)

    private func detectContactInfo(_ text: String) -> DraftField<String> {
        // Guatemala phone: "5431-3945" or "+502 5431-3945"
        if let match = text.firstMatch(of: /\+?502\s*(\d{4}[-\s]\d{4})/) {
            return DraftField(value: String(match.output.1), confidence: .high,
                              warning: "Mostrado como referencia únicamente. No se guardará en la propiedad.")
        }
        if let match = text.firstMatch(of: /\b(\d{4}[-\s]\d{4})\b/) {
            return DraftField(value: String(match.output.1), confidence: .high,
                              warning: "Mostrado como referencia únicamente. No se guardará en la propiedad.")
        }
        if let match = text.firstMatch(of: /\b(\d{8})\b/) {
            return DraftField(value: String(match.output.1), confidence: .medium,
                              warning: "Mostrado como referencia únicamente. No se guardará en la propiedad.")
        }
        return DraftField(confidence: .missing)
    }

    // MARK: - Hashtags

    private func detectHashtags(_ text: String) -> DraftField<[String]> {
        let tags = text.matches(of: /#\w+/).map { String($0.output) }
        if tags.isEmpty { return DraftField(confidence: .missing) }
        return DraftField(value: tags, confidence: .high)
    }

    // MARK: - Location

    private func detectLocation(_ text: String, lower: String, lines: [String]) -> DraftField<String> {
        // Strategy 1: Line starting with 📍 in first 6 lines
        for line in lines.prefix(6) {
            let stripped = stripLeadingDecoration(line)
            let strippedLower = stripped.lowercased()
            // Starts with "📍" in the original or stripped starts with "zona", "municipio", "colonia"
            if line.hasPrefix("📍") || line.hasPrefix("\u{1F4CD}") {
                let loc = stripped.trimmingCharacters(in: .whitespaces)
                if loc.count > 3 {
                    return DraftField(value: loc, confidence: .high)
                }
            }
            // Also catch lines that are purely location info after a pin emoji
            _ = strippedLower
        }

        // Strategy 2: "TITLE - Location" pattern in first 3 lines
        for line in lines.prefix(3) {
            let parts = line.components(separatedBy: " - ")
            if parts.count >= 2 {
                let candidate = parts[1].trimmingCharacters(in: .whitespaces)
                let generics = ["renta", "venta", "alquiler", "disponible",
                                "departamento", "casa", "apartamento"]
                let clean = candidate.replacing(/#\w+/, with: "").trimmingCharacters(in: .whitespaces)
                if !clean.isEmpty && !generics.contains(clean.lowercased()) && clean.count > 3 {
                    return DraftField(value: clean, confidence: .medium,
                                      warning: "Ubicación extraída del título. Verifique.")
                }
            }
        }

        // Strategy 3: explicit keyword patterns
        let keywordPatterns: [Regex<(Substring, Substring)>] = [
            /(?:ubicado en|localizado en)\s+([A-Za-záéíóúÁÉÍÓÚüÜñÑ, ]+)/,
            /zona\s+\d+\s+(?:de\s+)?([A-Za-záéíóúÁÉÍÓÚüÜñÑ ]+)/,
            /en\s+(santa\s+catarina\s+[a-záéíóúüñ]+|antigua\s+guatemala|ciudad\s+de\s+guatemala|[A-Za-záéíóúÁÉÍÓÚüÜñÑ]{5,}(?:\s+[A-Za-záéíóúÁÉÍÓÚüÜñÑ]+)*)/
        ]
        for pattern in keywordPatterns {
            if let match = lower.firstMatch(of: pattern) {
                let candidate = String(match.output.1)
                    .trimmingCharacters(in: .whitespaces)
                    .capitalized
                if candidate.count > 3 {
                    return DraftField(value: candidate, confidence: .low,
                                      warning: "Ubicación inferida. Verifique y corrija si es necesario.")
                }
            }
        }

        return DraftField(confidence: .missing,
                          warning: "No se detectó la ubicación. Ingrese manualmente.")
    }

    // MARK: - Title

    private func detectTitle(_ lines: [String], lower: String, location: String?) -> DraftField<String> {
        let propType = detectPropertyType(lower)

        // Strategy 1: "TITLE - Location" → left side is development name
        if let first = lines.first {
            let parts = first.components(separatedBy: " - ")
            if parts.count >= 2 {
                let left = stripLeadingDecoration(parts[0]).trimmingCharacters(in: .whitespaces)
                if !left.isEmpty && !isPromoPhrase(left) && left.count <= 40 {
                    let type = propType ?? "Propiedad"
                    return DraftField(value: "\(type) en \(left)", confidence: .medium,
                                      warning: "Título generado. Verifique.")
                }
            }
        }

        // Strategy 2: detect development name from heading text
        // "¡ ... ! DevelopmentName!" — text after last ! in first line
        for line in lines.prefix(2) {
            let stripped = stripLeadingDecoration(line)
            let exclamParts = stripped.components(separatedBy: "!")
            // Take last non-empty part
            if let devCandidate = exclamParts.reversed()
                .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                let dev = devCandidate.trimmingCharacters(in: .whitespacesAndNewlines)
                if dev.count >= 3 && dev.count <= 40 && !isPromoPhrase(dev) &&
                   !dev.lowercased().hasPrefix("agenda") {
                    let type = propType ?? "Propiedad"
                    return DraftField(value: "\(type) en \(dev)", confidence: .medium,
                                      warning: "Título generado. Verifique.")
                }
            }
        }

        // Strategy 3: property type + known location
        if let type = propType, let loc = location, !loc.isEmpty {
            return DraftField(value: "\(type) en \(loc)", confidence: .low,
                              warning: "Título generado de la ubicación detectada. Verifique.")
        }

        return DraftField(confidence: .missing,
                          warning: "Ingrese el título de la propiedad.")
    }

    // MARK: - Property type detection

    private func detectPropertyType(_ lower: String) -> String? {
        // Order matters: check more specific terms first
        let map: [(String, String)] = [
            ("townhouse",    "Townhouse"),
            ("town house",   "Townhouse"),
            ("apartamento",  "Apartamento"),
            ("departamento", "Apartamento"),   // normalize
            ("oficina",      "Oficina"),
            ("local comercial", "Local"),
            ("local",        "Local"),
            ("terreno",      "Terreno"),
            ("bodega",       "Bodega"),
            ("casa",         "Casa"),
        ]
        for (keyword, label) in map where lower.contains(keyword) {
            return label
        }
        return nil
    }

    // MARK: - Helpers

    /// Strip leading emoji, punctuation, bullet markers, and spaces from a line.
    private func stripLeadingDecoration(_ line: String) -> String {
        line.replacing(/^[\s📍🏡✨🔹🌟💰📐🚗•\-\*¡!]+/, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Returns true if the string looks like a promotional phrase to discard.
    private func isPromoPhrase(_ s: String) -> Bool {
        let lower = s.lowercased()
        let promos = ["oportunidad", "inversión", "vivienda", "hermosa", "excelente",
                      "próximo hogar", "agenda tu visita", "información", "contáctenos",
                      "no te pierdas", "sunsets"]
        return promos.contains(where: { lower.contains($0) }) || s.count < 3
    }

    // MARK: - Section extraction

    /// Collects bullet-listed items beneath a recognised section header.
    /// Compares the *decoration-stripped* lowercase line against headers.
    private func extractSection(from lines: [String], headers: [String], stopWords: [String]) -> [String] {
        var collecting = false
        var items: [String] = []

        for line in lines {
            let lower = line.lowercased()
            let stripped = stripLeadingDecoration(line).lowercased()

            if !collecting {
                let matchesHeader = headers.contains { h in
                    stripped.hasPrefix(h) || stripped == h.trimmingCharacters(in: .punctuationCharacters)
                }
                if matchesHeader {
                    collecting = true
                    // Inline item after ":"
                    if let colonIdx = line.firstIndex(of: ":") {
                        let afterColon = String(line[line.index(after: colonIdx)...])
                            .trimmingCharacters(in: .whitespaces)
                        if !afterColon.isEmpty { items.append(afterColon) }
                    }
                }
            } else {
                if stopWords.contains(where: { lower.contains($0) }) { break }
                // A new section header (non-bullet, no leading decoration) stops collection
                let isHeader = !line.hasPrefix("•") && !line.hasPrefix("-") &&
                               !line.hasPrefix("*") && !line.hasPrefix(" ") &&
                               stripped.count > 2 &&
                               headers.contains(where: { stripped.hasPrefix($0) })
                if isHeader { break }

                let cleaned = stripped
                if !cleaned.isEmpty && cleaned.count > 1 {
                    items.append(cleaned.capitalized == cleaned ? cleaned :
                                 (cleaned.prefix(1).uppercased() + cleaned.dropFirst()))
                }
            }
        }
        return items
    }
}

// MARK: - ClaudeListingParser (stub — implemented in Milestone 4)

enum ClaudeListingParserError: Error {
    case notImplemented
}

struct ClaudeListingParser: ListingImportService {
    func parse(_ description: String) async throws -> PropertyDraft {
        throw ClaudeListingParserError.notImplemented
    }
}
