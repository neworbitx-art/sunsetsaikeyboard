import Foundation

final class LocalPropertyRepository: PropertyRepository {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let activeIdKey = "activePropertyId"
    private let employeeKey = "currentEmployee"
    private let seededKey = "catalogSeeded"
    private let defaults: UserDefaults

    init(
        fileURL: URL = LocalPropertyRepository.defaultFileURL(),
        defaults: UserDefaults = .standard
    ) {
        self.fileURL = fileURL
        self.defaults = defaults

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Properties

    func fetchAll() async throws -> [Property] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([Property].self, from: data)
    }

    func save(_ property: Property) async throws {
        var all = try await fetchAll()
        if let idx = all.firstIndex(where: { $0.id == property.id }) {
            all[idx] = property
        } else {
            all.append(property)
        }
        let data = try encoder.encode(all)
        try data.write(to: fileURL, options: .atomic)
    }

    func delete(id: String) async throws {
        var all = try await fetchAll()
        all.removeAll { $0.id == id }
        let data = try encoder.encode(all)
        try data.write(to: fileURL, options: .atomic)
        // Clear active ID if the deleted property was active
        if defaults.string(forKey: activeIdKey) == id {
            defaults.removeObject(forKey: activeIdKey)
        }
    }

    // MARK: - Active property

    func fetchActiveId() async throws -> String? {
        defaults.string(forKey: activeIdKey)
    }

    func setActiveId(_ id: String?) async throws {
        if let id {
            defaults.set(id, forKey: activeIdKey)
        } else {
            defaults.removeObject(forKey: activeIdKey)
        }
    }

    // MARK: - Employee

    func fetchEmployee() async throws -> String? {
        defaults.string(forKey: employeeKey)
    }

    func setEmployee(_ name: String) async throws {
        defaults.set(name, forKey: employeeKey)
    }

    // MARK: - Seeding

    var isSeeded: Bool {
        get { defaults.bool(forKey: seededKey) }
        set { defaults.set(newValue, forKey: seededKey) }
    }

    func seedIfNeeded(_ properties: [Property]) async throws {
        guard !isSeeded else { return }
        let data = try encoder.encode(properties)
        try data.write(to: fileURL, options: .atomic)
        isSeeded = true
    }

    // MARK: - Helpers

    static func defaultFileURL() -> URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SunsetsProperties", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("catalog.json")
    }
}
