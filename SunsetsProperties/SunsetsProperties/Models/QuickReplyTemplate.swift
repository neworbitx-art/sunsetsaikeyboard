import Foundation

struct QuickReplyTemplate: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var label: String
    var bodyTemplate: String
    var category: TemplateCategory
}

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case price
    case availability
    case location
    case amenities
    case requirements
    case petPolicy
    case visit
    case general

    var id: String { rawValue }

    var label: String {
        switch self {
        case .price:        return "Precio"
        case .availability: return "Disponibilidad"
        case .location:     return "Ubicación"
        case .amenities:    return "Amenidades"
        case .requirements: return "Requisitos"
        case .petPolicy:    return "Mascotas"
        case .visit:        return "Visita"
        case .general:      return "General"
        }
    }
}
