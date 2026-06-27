import Foundation

enum FHAEligibility: String, Codable, CaseIterable, Identifiable {
    case eligible
    case notEligible
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .eligible:    return "Aplica FHA"
        case .notEligible: return "No aplica FHA"
        case .unknown:     return "No confirmado"
        }
    }
}
