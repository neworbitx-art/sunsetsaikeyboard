import Foundation

enum PetPolicy: String, Codable, CaseIterable, Identifiable {
    case allowed
    case notAllowed
    case subjectToCaseAnalysis

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allowed:               return "Se acepta mascota"
        case .notAllowed:            return "No se aceptan mascotas"
        case .subjectToCaseAnalysis: return "Sujeto a análisis de caso"
        }
    }
}
