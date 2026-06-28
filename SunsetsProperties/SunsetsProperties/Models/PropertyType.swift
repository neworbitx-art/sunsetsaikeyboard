import Foundation

enum PropertyType: String, Codable, CaseIterable, Identifiable {
    case house
    case apartment
    case townhouse
    case land
    case office
    case commercialUnit
    case warehouse
    case condominium
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .house:          return "Casa"
        case .apartment:      return "Apartamento"
        case .townhouse:      return "Townhouse"
        case .land:           return "Terreno"
        case .office:         return "Oficina"
        case .commercialUnit: return "Local comercial"
        case .warehouse:      return "Bodega"
        case .condominium:    return "Condominio"
        case .other:          return "Otro"
        }
    }

    // Infer from existing free-text title. Returns nil when not deterministic.
    static func infer(from title: String) -> PropertyType? {
        let lower = title.lowercased()
        if lower.contains("townhouse") || lower.contains("town house") { return .townhouse }
        if lower.contains("apartamento") || lower.contains("departamento") { return .apartment }
        if lower.contains("terreno") { return .land }
        if lower.contains("oficina") { return .office }
        if lower.contains("local comercial") { return .commercialUnit }
        if lower.contains("bodega") { return .warehouse }
        if lower.contains("condominio") { return .condominium }
        if lower.contains("casa") { return .house }
        return nil
    }
}
