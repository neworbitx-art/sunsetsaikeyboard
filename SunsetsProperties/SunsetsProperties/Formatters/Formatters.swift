import Foundation

enum AppFormatters {

    // MARK: - Currency

    static func currency(_ amount: Decimal, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "es_GT")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(code) \(amount)"
    }

    static func number(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_GT")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    // MARK: - Area

    static func area(_ sqm: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_GT")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: sqm as NSNumber) ?? "\(sqm)"
        return "\(value) m²"
    }

    // MARK: - Date

    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "es_GT")
        return f
    }()

    static func date(_ date: Date?) -> String {
        guard let date else { return "—" }
        return mediumDateFormatter.string(from: date)
    }

    // MARK: - Bathrooms

    static func bathrooms(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
