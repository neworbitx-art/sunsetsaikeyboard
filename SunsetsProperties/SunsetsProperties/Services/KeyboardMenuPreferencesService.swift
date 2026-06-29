import Foundation
import Observation

// MARK: - Service

@Observable
final class KeyboardMenuPreferencesService {

    var actions: [KeyboardMenuAction]

    private let fileURL: URL

    // Ordered list of all actions with system-defined defaults.
    // isEnabled is the only user-controlled field; rentOnly/saleOnly are system-defined.
    static let defaultActions: [KeyboardMenuAction] = [
        KeyboardMenuAction(id: "welcome",         label: "Bienvenida",            isEnabled: true,  rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "generalInfo",     label: "Información general",   isEnabled: true,  rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "location",        label: "Ubicación",             isEnabled: true,  rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "requirements",    label: "Requisitos",            isEnabled: true,  rentOnly: true,  saleOnly: false),
        KeyboardMenuAction(id: "qualification",   label: "Filtro de cliente",     isEnabled: true,  rentOnly: true,  saleOnly: false),
        KeyboardMenuAction(id: "purchaseInfo",    label: "Información de compra", isEnabled: true,  rentOnly: false, saleOnly: true),
        KeyboardMenuAction(id: "availability",    label: "Disponibilidad",        isEnabled: false, rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "price",           label: "Precio",                isEnabled: false, rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "characteristics", label: "Características",       isEnabled: false, rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "amenities",       label: "Amenidades",            isEnabled: false, rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "petPolicy",       label: "Mascotas",              isEnabled: false, rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "visit",           label: "Agendar visita",        isEnabled: false, rentOnly: false, saleOnly: false),
        KeyboardMenuAction(id: "followUp",        label: "Seguimiento",           isEnabled: false, rentOnly: false, saleOnly: false),
    ]

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = appSupport.appendingPathComponent("keyboard_menu_preferences.json")
        fileURL = url
        actions = Self.load(from: url)
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(actions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // Merges persisted isEnabled values into the canonical default list.
    // rentOnly/saleOnly always reflect system defaults, not any saved value.
    private static func load(from url: URL) -> [KeyboardMenuAction] {
        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([KeyboardMenuAction].self, from: data) else {
            return defaultActions
        }
        return defaultActions.map { def in
            if let s = saved.first(where: { $0.id == def.id }) {
                return KeyboardMenuAction(id: def.id, label: def.label,
                                         isEnabled: s.isEnabled,
                                         rentOnly: def.rentOnly,
                                         saleOnly: def.saleOnly)
            }
            return def
        }
    }
}
