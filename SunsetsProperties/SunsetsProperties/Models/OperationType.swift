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
}
