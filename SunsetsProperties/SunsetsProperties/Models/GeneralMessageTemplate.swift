import Foundation

// MARK: - Category

enum GeneralMessageCategory: String, Codable, CaseIterable, Identifiable {
    case welcome
    case qualification
    case reservationPayment
    case visitCoordination
    case followUp
    case contactInfo
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .welcome:           return "Bienvenida"
        case .qualification:     return "Filtro de cliente"
        case .reservationPayment: return "Pago de reserva"
        case .visitCoordination: return "Coordinación de visita"
        case .followUp:          return "Seguimiento"
        case .contactInfo:       return "Información de contacto"
        case .custom:            return "Personalizado"
        }
    }
}

// MARK: - Model

struct GeneralMessageTemplate: Codable, Identifiable {
    let id: UUID
    var title: String
    var category: GeneralMessageCategory
    var body: String
    var isEnabled: Bool
    var isKeyboardVisible: Bool
    var requiresReviewBeforeInsertion: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    static func new(category: GeneralMessageCategory = .custom) -> GeneralMessageTemplate {
        let now = Date()
        return GeneralMessageTemplate(
            id: UUID(),
            title: "",
            category: category,
            body: "",
            isEnabled: true,
            isKeyboardVisible: true,
            requiresReviewBeforeInsertion: true,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )
    }
}

// MARK: - Keyboard-safe projection (no sensitive data)

struct KeyboardSafeGeneralMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let category: String   // raw value of GeneralMessageCategory
    let body: String
    let sortOrder: Int
    let requiresReviewBeforeInsertion: Bool
}

extension KeyboardSafeGeneralMessage {
    init(projecting template: GeneralMessageTemplate) {
        id = template.id
        title = template.title
        category = template.category.rawValue
        body = template.body
        sortOrder = template.sortOrder
        requiresReviewBeforeInsertion = template.requiresReviewBeforeInsertion
    }
}
