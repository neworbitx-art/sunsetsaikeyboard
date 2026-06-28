import Foundation

enum OperationType: String, Codable, CaseIterable, Identifiable {
    case rent
    case sale
    case rentOrSale

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rent:      return "Renta"
        case .sale:      return "Venta"
        case .rentOrSale: return "Renta o Venta"
        }
    }

    // Lowercase word used in generated customer-facing titles ("en venta", "en renta")
    var titleWord: String {
        switch self {
        case .rent:      return "renta"
        case .sale:      return "venta"
        case .rentOrSale: return "renta o venta"
        }
    }
}
