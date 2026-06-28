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
    case characteristics
    case petPolicy
    case purchaseInfo
    case visit
    case followUp
    case general
    case generalInfo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .price:           return "Precio"
        case .availability:    return "Disponibilidad"
        case .location:        return "Ubicación"
        case .amenities:       return "Amenidades"
        case .requirements:    return "Requisitos"
        case .characteristics: return "Características"
        case .petPolicy:       return "Mascotas"
        case .purchaseInfo:    return "Información de compra"
        case .visit:           return "Agendar visita"
        case .followUp:        return "Seguimiento"
        case .general:         return "General"
        case .generalInfo:     return "Información general"
        }
    }
}
