import Foundation

final class LocalPropertyRepository: PropertyRepository {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let defaults: UserDefaults

    // UserDefaults keys
    private let activeIdKey      = "activePropertyId"
    private let employeeKey      = "currentEmployee"
    private let seededKey        = "catalogSeeded"
    private let lastCodeKey      = "lastIssuedInternalCodeNumber"
    private let migratedKey      = "catalogMigrated_1_1"

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
        let isNew = !all.contains { $0.id == property.id }
        if let idx = all.firstIndex(where: { $0.id == property.id }) {
            all[idx] = property
        } else {
            all.append(property)
        }
        let data = try encoder.encode(all)
        // Write first; if this throws the counter is not advanced.
        try data.write(to: fileURL, options: .atomic)
        // Advance the counter to cover the saved code (new properties only).
        if isNew, let codeNum = InternalCodeService.extractNumber(from: property.internalCode) {
            let current = defaults.integer(forKey: lastCodeKey)
            if codeNum > current {
                defaults.set(codeNum, forKey: lastCodeKey)
            }
        }
    }

    func delete(id: String) async throws {
        var all = try await fetchAll()
        all.removeAll { $0.id == id }
        let data = try encoder.encode(all)
        try data.write(to: fileURL, options: .atomic)
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

    // MARK: - Internal codes (Milestone 1.1)

    func peekNextInternalCode() async throws -> String {
        // Reads the next available code without advancing the counter.
        // Counter advances only when save() successfully writes a new property.
        let last = defaults.integer(forKey: lastCodeKey)
        return InternalCodeService.format(number: last + 1)
    }

    func isInternalCodeUnique(_ code: String, excludingId: String?) async throws -> Bool {
        let all = try await fetchAll()
        let normalised = code.trimmingCharacters(in: .whitespaces).uppercased()
        return !all.contains { p in
            p.internalCode.uppercased() == normalised && p.id != excludingId
        }
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
        // Seed the code counter from the highest existing seed code
        seedCodeCounterIfNeeded(from: properties)
    }

    // MARK: - Migration (Milestone 1.1)

    func migrateIfNeeded() async throws {
        guard !defaults.bool(forKey: migratedKey) else { return }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            defaults.set(true, forKey: migratedKey)
            return
        }

        // Back up the existing JSON before migrating
        let backupURL = fileURL.deletingPathExtension().appendingPathExtension("backup.json")
        try? FileManager.default.copyItem(at: fileURL, to: backupURL)

        // Load all properties (new custom decoder handles missing fields with defaults)
        let properties = try await fetchAll()

        // Re-encode with new fields; this ensures all new optional fields are present
        let data = try encoder.encode(properties)
        try data.write(to: fileURL, options: .atomic)

        // Seed the code counter from existing catalog if counter is not set
        seedCodeCounterIfNeeded(from: properties)

        defaults.set(true, forKey: migratedKey)
    }

    // MARK: - Helpers

    private func seedCodeCounterIfNeeded(from properties: [Property]) {
        let currentCounter = defaults.integer(forKey: lastCodeKey)
        guard currentCounter == 0 else { return }
        let maxNumber = properties
            .compactMap { InternalCodeService.extractNumber(from: $0.internalCode) }
            .max() ?? 0
        if maxNumber > 0 {
            defaults.set(maxNumber, forKey: lastCodeKey)
        }
    }

    static func defaultFileURL() -> URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SunsetsProperties", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("catalog.json")
    }
}
