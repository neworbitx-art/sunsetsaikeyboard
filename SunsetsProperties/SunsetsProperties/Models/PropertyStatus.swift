import Foundation

enum PropertyStatus: String, Codable, CaseIterable, Identifiable {
    case available
    case reserved
    case rented
    case sold
    case inactive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .available: return "Disponible"
        case .reserved:  return "Reservada"
        case .rented:    return "Rentada"
        case .sold:      return "Vendida"
        case .inactive:  return "Inactiva"
        }
    }

    var isWarning: Bool { self != .available }
}
