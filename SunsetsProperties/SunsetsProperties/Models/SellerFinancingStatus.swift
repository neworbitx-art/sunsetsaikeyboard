import Foundation

enum SellerFinancingStatus: String, Codable, CaseIterable, Identifiable {
    case unavailable
    case available
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unavailable: return "Sin financiamiento del vendedor"
        case .available:   return "Con financiamiento del vendedor"
        case .unknown:     return "No confirmado"
        }
    }
}
