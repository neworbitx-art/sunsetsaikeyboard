import Foundation

enum PetPolicy: String, Codable, CaseIterable, Identifiable {
    case allowed
    case notAllowed
    case allowedWithDeposit
    case caseByCase

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allowed:            return "Se aceptan mascotas"
        case .notAllowed:         return "No se aceptan mascotas"
        case .allowedWithDeposit: return "Se aceptan mascotas con depósito"
        case .caseByCase:         return "Caso por caso"
        }
    }
}
