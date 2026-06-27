import Foundation

enum FinancingTextService {

    static func text(for property: Property) -> String? {
        guard property.operationType == .sale || property.operationType == .rentOrSale else {
            return nil
        }
        guard property.sellerFinancingStatus == .unavailable else {
            return nil
        }
        var parts: [String] = [
            "El precio incluye financiamiento bancario disponible. El banco financia entre el 70% y el 80% del valor del inmueble, y el comprador aporta entre el 20% y el 30% de enganche."
        ]
        if property.fhaEligibility == .eligible {
            parts.append("Esta propiedad es elegible para financiamiento FHA. El programa FHA permite un enganche de tan solo el 5%.")
        }
        return parts.joined(separator: "\n\n")
    }

    static func fhaWarning(for property: Property) -> String? {
        guard (property.operationType == .sale || property.operationType == .rentOrSale),
              property.sellerFinancingStatus == .unavailable,
              property.fhaEligibility == .unknown else {
            return nil
        }
        return "Elegibilidad FHA no confirmada."
    }
}
