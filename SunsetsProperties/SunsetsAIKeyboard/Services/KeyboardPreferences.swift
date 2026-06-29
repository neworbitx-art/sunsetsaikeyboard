import Foundation

// MARK: - Keyboard preferences (App Group UserDefaults)

final class KeyboardPreferences {

    private let appGroupID = "group.com.zircondata.sunsetsai"
    private let maxRecentCount = 5

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys

    private let keyboardSelectedKey = "keyboard_selected_property_id"
    private let recentIDsKey = "recent_property_ids"
    private let activePropertyKey = "active_property_id"
    private let employeeKey = "current_employee"

    // MARK: - Keyboard-selected property

    var keyboardSelectedPropertyID: String? {
        get { defaults?.string(forKey: keyboardSelectedKey) }
        set {
            if let id = newValue {
                defaults?.set(id, forKey: keyboardSelectedKey)
            } else {
                defaults?.removeObject(forKey: keyboardSelectedKey)
            }
        }
    }

    // MARK: - Active property (written by main app, read by keyboard)

    var mainActivePropertyID: String? {
        defaults?.string(forKey: activePropertyKey)
    }

    // MARK: - Recent IDs (FIFO, max 5)

    var recentPropertyIDs: [String] {
        defaults?.stringArray(forKey: recentIDsKey) ?? []
    }

    func recordRecentSelection(_ id: String) {
        var ids = recentPropertyIDs.filter { $0 != id }
        ids.insert(id, at: 0)
        if ids.count > maxRecentCount { ids = Array(ids.prefix(maxRecentCount)) }
        defaults?.set(ids, forKey: recentIDsKey)
    }

    // MARK: - Employee

    var employeeName: String? {
        defaults?.string(forKey: employeeKey)
    }

    // MARK: - Resolve selected property

    func resolveSelectedPropertyID() -> String? {
        keyboardSelectedPropertyID ?? mainActivePropertyID
    }
}
