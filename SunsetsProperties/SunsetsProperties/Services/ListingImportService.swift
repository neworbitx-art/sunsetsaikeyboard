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
        // Sanitize first: removes hashtags, contact footers, CTAs, company signatures
        let sanitized = sanitize(description)
        let lower = sanitized.lowercased()
        let lines = sanitized.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Store the full sanitized text as the public listing body (editable before save)
        if !sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.publicListingText = DraftField(
                value: sanitized.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: .medium,
                warning: "Revise el texto sanitizado. Se usará en Información general del teclado."
            )
        }

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
        draft.contactInfo         = detectContactInfo(description)  // use original for phone
        draft.hashtags            = detectHashtags(description)     // use original for hashtags
        draft.locationSummary       = detectLocation(sanitized, lower: lower, lines: lines)
        let detectedDev             = detectDevelopmentName(lines)
        if let dev = detectedDev { draft.developmentName = DraftField(value: dev, confidence: .medium) }
        // Property type: heading-first detection (prevents room names from overriding type)
        draft.propertyType          = detectStructuredPropertyType(lower, lines: lines)
        draft.status                = DraftField(value: .available, confidence: .high)
        draft.fhaEligibility        = detectFHAEligibility(lower)
        draft.sellerFinancingStatus = detectSellerFinancing(lower)

        return draft
    }

    // MARK: - Sanitization

    private func sanitize(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lower = trimmed.lowercased()
            if isHashtagLine(trimmed) { continue }
            if isContactFooterLine(lower) { continue }
            if isCompanySignatureLine(lower) { continue }
            if isCTALine(lower) { continue }
            if isPhoneOnlyLine(trimmed) { continue }
            if isEmailOnlyLine(trimmed) { continue }
            // Strip inline hashtag tokens from lines that survive filtering
            let cleaned = removeInlineHashtags(line)
            // Skip the line if stripping left it empty
            if cleaned.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            result.append(cleaned)
        }
        // Collapse 3+ consecutive blank lines into at most 2
        let joined = result.joined(separator: "\n")
        return joined.replacing(/\n{3,}/, with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isHashtagLine(_ line: String) -> Bool {
        let words = line.split(separator: " ")
        guard !words.isEmpty else { return false }
        let hashtagCount = words.filter { $0.hasPrefix("#") }.count
        return hashtagCount >= 2 || (hashtagCount == 1 && words.count == 1)
    }

    private func isCTALine(_ lower: String) -> Bool {
        let ctaKeywords = [
            "información y citas", "informacion y citas",
            "contáctanos", "contactanos", "contáctenos", "contactenos",
            "agenda tu visita", "agenda una visita", "agenda su visita",
            "escríbenos", "escribenos", "escríbeme", "escribeme",
            "para más información", "para mas informacion",
            "solicita tu visita", "coordina tu visita",
            "agenda aquí", "agenda aqui"
        ]
        return ctaKeywords.contains(where: { lower.contains($0) })
    }

    private func isContactFooterLine(_ lower: String) -> Bool {
        let contactKeywords = [
            "contacto:", "tel:", "teléfono:", "telefono:",
            "whatsapp:", "cel:", "celular:", "llámenos", "llamenos",
            "llámanos", "llamanos", "para más info", "para informes"
        ]
        return contactKeywords.contains(where: { lower.contains($0) })
    }

    private func isCompanySignatureLine(_ lower: String) -> Bool {
        let signatures = ["sunsets real estate", "sunsets properties", "sunsets propiedades",
                          "by sunsets", "©"]
        return signatures.contains(where: { lower.contains($0) })
    }

    private func isPhoneOnlyLine(_ text: String) -> Bool {
        // A line composed only of a phone number (digits, spaces, hyphens, parentheses, +)
        let stripped = text
            .replacing(/^[\s📞☎️]+/, with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !stripped.isEmpty else { return false }
        return stripped.wholeMatch(of: /[\+\(]?[\d\s\-\(\)]{7,}/) != nil
    }

    private func isEmailOnlyLine(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.wholeMatch(of: /[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/) != nil
    }

    private func removeInlineHashtags(_ text: String) -> String {
        text.replacing(/#[A-Za-z\u{00C0}-\u{017E}][A-Za-z\u{00C0}-\u{017E}0-9_]*/,
                       with: "")
            .replacing(/[ \t]{2,}/, with: " ")
            .trimmingCharacters(in: .whitespaces)
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
        // "2 baños y medio" / "1 baño y medio" → N + 0.5
        if let match = lower.firstMatch(of: /(\d+)\s*ba[ñn]os?\s+y\s+medio/),
           let n = Double(match.output.1) {
            return DraftField(value: n + 0.5, confidence: .high)
        }
        // "1/2 baño" / "medio baño" → 0.5
        if lower.contains("1/2 baño") || lower.contains("1/2 bano") || lower.contains("medio baño") {
            // Check if there's also a whole count before
            if let match = lower.firstMatch(of: /(\d+)\s*ba[ñn]os?\s+y\s+(?:1\/2|medio)/),
               let n = Double(match.output.1) {
                return DraftField(value: n + 0.5, confidence: .high)
            }
            return DraftField(value: 0.5, confidence: .high)
        }
        // "2.5 baños" or "1,5 baños"
        if let match = lower.firstMatch(of: /(\d+[.,]\d+)\s*ba[ñn]os?/) {
            let raw = String(match.output.1).replacingOccurrences(of: ",", with: ".")
            if let d = Double(raw), d > 0 {
                return DraftField(value: d, confidence: .high)
            }
        }
        // "3 baños"
        if let match = lower.firstMatch(of: /(\d+)\s*ba[ñn]os?/),
           let d = Double(match.output.1), d > 0 {
            return DraftField(value: d, confidence: .high)
        }
        // English fallback
        if let match = lower.firstMatch(of: /(\d+(?:\.\d+)?)\s*bathrooms?/),
           let d = Double(match.output.1), d > 0 {
            return DraftField(value: d, confidence: .medium)
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
                      "items incluidos:", "incluye adicionalmente:",
                      "se incluyen:", "viene incluido:", "incluidos:",
                      "incluido:", "qué incluye"],
            stopWords: ["no incluye", "excluye", "amenidades", "requisitos",
                        "electrodomésticos", "precio", "informes"])
        if !items.isEmpty {
            // Expand any comma-separated entries captured as a single item
            let expanded = items.flatMap { item -> [String] in
                let parts = item.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                return parts.count > 1 ? parts : [item]
            }
            return DraftField(value: expanded, confidence: .medium)
        }

        // Inline extraction: "Incluye: cortinas, estufa, horno"
        if let match = lower.firstMatch(of: /incluye[:\s]+([^.]+)/) {
            let list = String(match.output.1)
                .components(separatedBy: CharacterSet(charactersIn: ",;"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0.count > 1 }
            if !list.isEmpty { return DraftField(value: list, confidence: .medium) }
        }

        return DraftField(confidence: .missing)
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

        // Strategy 2: "TITLE – Location" or "TITLE - Location" pattern in first 3 lines
        // Covers both en-dash (–) and hyphen (-) separators used in real-estate headings.
        let headingSeparators = [" – ", " - "]
        for line in lines.prefix(3) {
            for sep in headingSeparators {
                let parts = line.components(separatedBy: sep)
                if parts.count >= 2 {
                    // Take the last segment as the location candidate
                    let candidate = parts.last!.trimmingCharacters(in: .whitespaces)
                    let generics = ["renta", "venta", "alquiler", "disponible",
                                    "departamento", "casa", "apartamento"]
                    let clean = candidate.replacing(/#\w+/, with: "").trimmingCharacters(in: .whitespaces)
                    if !clean.isEmpty && !generics.contains(clean.lowercased()) &&
                       clean.count > 3 && clean.count < 80 {
                        return DraftField(value: clean, confidence: .medium,
                                          warning: "Ubicación extraída del título. Verifique.")
                    }
                }
            }
        }

        // Strategy 2.5: standalone location lines in lines 2–5 (e.g. "Santa Catarina Pinula, Guatemala")
        let opWords: Set<String> = ["venta", "renta", "alquiler", "precio", "disponible",
                                    "casa", "apartamento", "terreno", "local", "bodega"]
        for line in lines.dropFirst().prefix(4) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.count >= 5, trimmed.count < 80 else { continue }
            let lowerLine = trimmed.lowercased()
            // Skip lines that start with a property-type or price keyword
            guard !opWords.contains(where: { lowerLine.hasPrefix($0) }) else { continue }
            guard !lowerLine.contains("precio") && !lowerLine.contains("q.") else { continue }
            // Accept lines that look like "City, Country" or "Municipality, City"
            let commaCount = trimmed.filter { $0 == "," }.count
            if commaCount >= 1 {
                let parts = trimmed.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let isGeo = parts.allSatisfy {
                    !$0.isEmpty && $0.count >= 3 && !$0.lowercased().contains("q.")
                }
                if isGeo {
                    return DraftField(value: trimmed, confidence: .medium,
                                      warning: "Ubicación extraída del encabezado. Verifique.")
                }
            }
        }

        // Strategy 3: explicit keyword patterns
        let keywordPatterns: [Regex<(Substring, Substring)>] = [
            /(?:ubicado en|localizado en)\s+([A-Za-záéíóúÁÉÍÓÚüÜñÑ, ]+)/,
            /zona\s+\d+\s+(?:de\s+)?([A-Za-záéíóúÁÉÍÓÚüÜñÑ ]+)/,
            /en\s+(santa\s+catarina\s+[a-záéíóúüñ]+|antigua\s+guatemala|ciudad\s+de\s+guatemala)/
        ]
        for pattern in keywordPatterns {
            if let match = lower.firstMatch(of: pattern) {
                let candidate = String(match.output.1)
                    .trimmingCharacters(in: .whitespaces)
                    .capitalized
                if candidate.count > 3 && !opWords.contains(candidate.lowercased()) {
                    return DraftField(value: candidate, confidence: .low,
                                      warning: "Ubicación inferida. Verifique y corrija si es necesario.")
                }
            }
        }

        return DraftField(confidence: .missing,
                          warning: "No se detectó la ubicación. Ingrese manualmente.")
    }

    // MARK: - Property type detection

    // Heading-first detection prevents room names ("Bodega") from overriding heading type.
    // Priority order: explicit field → first 2 heading lines → first 5 lines → body (no warehouse)
    private func detectStructuredPropertyType(_ fullLower: String, lines: [String]) -> DraftField<PropertyType> {
        // P1: Explicit "Tipo de propiedad:" field anywhere in text
        if let type = detectTypeFromExplicitField(fullLower) {
            return DraftField(value: type, confidence: .high)
        }

        // P2: First 2 lines (title / heading) — any type including warehouse
        let headingLines = Array(lines.prefix(2).map { $0.lowercased() })
        if let type = detectTypeFromLines(headingLines, allowWarehouse: true) {
            return DraftField(value: type, confidence: .high)
        }

        // P3: First 5 lines (opening paragraph) — still high-confidence
        let openingLines = Array(lines.prefix(5).map { $0.lowercased() })
        if let type = detectTypeFromLines(openingLines, allowWarehouse: true) {
            return DraftField(value: type, confidence: .medium)
        }

        // P4: Full body text — warehouse only when heading explicitly says so
        if let type = detectTypeFromBodyNoWarehouse(fullLower) {
            return DraftField(value: type, confidence: .low,
                              warning: "Tipo detectado del texto. Verifique.")
        }

        return DraftField(confidence: .missing)
    }

    private func detectTypeFromExplicitField(_ lower: String) -> PropertyType? {
        if lower.contains("tipo de propiedad: bodega")          { return .warehouse }
        if lower.contains("tipo de propiedad: casa")            { return .house }
        if lower.contains("tipo de propiedad: apartamento")     { return .apartment }
        if lower.contains("tipo de propiedad: departamento")    { return .apartment }
        if lower.contains("tipo de propiedad: terreno")         { return .land }
        if lower.contains("tipo de propiedad: oficina")         { return .office }
        if lower.contains("tipo de propiedad: local comercial") { return .commercialUnit }
        if lower.contains("tipo de propiedad: townhouse")       { return .townhouse }
        if lower.contains("tipo de propiedad: condominio")      { return .condominium }
        return nil
    }

    // Checks an ordered list of lines (already lowercased) for property type keywords.
    // Warehouse only matched when allowWarehouse AND the line contains warehouse-specific phrases.
    private func detectTypeFromLines(_ lines: [String], allowWarehouse: Bool) -> PropertyType? {
        let warehouseTerms = ["bodega en venta", "bodega en renta", "nave industrial",
                              "bodega industrial"]
        let typeMap: [(String, PropertyType)] = [
            ("townhouse",       .townhouse),
            ("town house",      .townhouse),
            ("apartamento",     .apartment),
            ("departamento",    .apartment),
            ("oficina",         .office),
            ("local comercial", .commercialUnit),
            ("terreno",         .land),
            ("casa",            .house),
            ("condominio",      .condominium),
        ]
        for line in lines {
            if allowWarehouse && warehouseTerms.contains(where: { line.contains($0) }) {
                return .warehouse
            }
            for (keyword, type) in typeMap where line.contains(keyword) {
                return type
            }
        }
        return nil
    }

    // Body-text fallback — never classifies as warehouse from body alone,
    // because "bodega" in body text typically denotes a storage room.
    private func detectTypeFromBodyNoWarehouse(_ lower: String) -> PropertyType? {
        let typeMap: [(String, PropertyType)] = [
            ("townhouse",       .townhouse),
            ("town house",      .townhouse),
            ("apartamento",     .apartment),
            ("departamento",    .apartment),
            ("oficina",         .office),
            ("local comercial", .commercialUnit),
            ("terreno",         .land),
            ("casa",            .house),
            ("condominio",      .condominium),
        ]
        for (keyword, type) in typeMap where lower.contains(keyword) {
            return type
        }
        return nil
    }

    // MARK: - Development name extraction

    private func detectDevelopmentName(_ lines: [String]) -> String? {
        // Split on common heading separators first so "Casa en venta | Residenciales Arboretto – Pinula"
        // yields ["Casa en venta", "Residenciales Arboretto", "Pinula"] and we find "Residenciales Arboretto".
        let prefixes = ["residencial", "residenciales", "torre ", "condominio ", "proyecto ",
                        "edificio ", "club ", "villas ", "parque ", "cento"]
        for line in lines.prefix(3) {
            // Split by heading separators into segments
            var segments = [line]
            for sep in [" | ", " – ", " - ", " · "] {
                segments = segments.flatMap { $0.components(separatedBy: sep) }
            }
            segments = segments.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

            for segment in segments {
                let lowerSeg = segment.lowercased()
                for prefix in prefixes where lowerSeg.hasPrefix(prefix) || lowerSeg.contains(" \(prefix)") {
                    let candidate = segment.trimmingCharacters(in: .whitespaces)
                    if candidate.count >= 5 && candidate.count <= 60 {
                        return candidate
                    }
                }
                // Also extract the sub-string starting from the prefix position
                for prefix in prefixes {
                    if let range = lowerSeg.range(of: prefix) {
                        let offset = lowerSeg.distance(from: lowerSeg.startIndex, to: range.lowerBound)
                        let sub = String(segment[segment.index(segment.startIndex, offsetBy: offset)...])
                            .trimmingCharacters(in: .whitespaces)
                        if sub.count >= 5 && sub.count <= 60 {
                            return sub
                        }
                    }
                }
            }
        }
        return nil
    }

    // MARK: - FHA eligibility

    private func detectFHAEligibility(_ lower: String) -> DraftField<FHAEligibility> {
        if lower.contains("no aplica fha") ||
           lower.contains("no es elegible para fha") ||
           lower.contains("sin opción fha") {
            return DraftField(value: .notEligible, confidence: .high)
        }
        if lower.contains("aplica fha") ||
           lower.contains("financiamiento fha disponible") ||
           lower.contains("elegible para fha") {
            return DraftField(value: .eligible, confidence: .high)
        }
        return DraftField(value: .unknown, confidence: .missing)
    }

    // MARK: - Seller financing

    private func detectSellerFinancing(_ lower: String) -> DraftField<SellerFinancingStatus> {
        if lower.contains("sin financiamiento del vendedor") ||
           lower.contains("no hay financiamiento del vendedor") {
            return DraftField(value: .unavailable, confidence: .high)
        }
        if lower.contains("financiamiento del vendedor") ||
           lower.contains("el vendedor financia") {
            return DraftField(value: .available, confidence: .high)
        }
        return DraftField(value: .unknown, confidence: .missing)
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
