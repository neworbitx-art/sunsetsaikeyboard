import Foundation

final class LocalPropertyRepository: PropertyRepository {

    /// Recoverable errors surfaced when the on-disk catalog cannot be read or safely backed up.
    /// In every case the existing `catalog.json` is left untouched — never overwritten.
    enum CatalogError: LocalizedError {
        case unreadableCatalog(underlying: Error)
        case backupFailed(underlying: Error)
        case backupValidationFailed

        var errorDescription: String? {
            switch self {
            case .unreadableCatalog:
                return "El catálogo local existe pero no se pudo leer. Se conservó sin cambios."
            case .backupFailed, .backupValidationFailed:
                return "No se pudo crear un respaldo válido del catálogo. No se realizó ningún cambio."
            }
        }
    }

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let defaults: UserDefaults

    // UserDefaults keys
    private let activeIdKey  = "activePropertyId"
    private let employeeKey  = "currentEmployee"
    private let lastCodeKey  = "lastIssuedInternalCodeNumber"
    private let preparedKey  = "catalogPrepared_v2"

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

    // MARK: - File locations

    /// The single backup slot. Exactly one validated backup is kept at a time, and it is
    /// never auto-restored — recovery from it is an explicit, manual decision.
    private var backupURL: URL {
        fileURL.deletingPathExtension().appendingPathExtension("backup.json")
    }

    // MARK: - Properties

    func fetchAll() async throws -> [Property] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }
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

    /// Returns the stored active id only when a property with that id still exists.
    /// A dangling pointer (the property was deleted) is cleared and `nil` is returned.
    /// If the catalog itself cannot be read, the stored id is left untouched and the error
    /// propagates — a transient read failure must not destroy a valid pointer.
    func fetchActiveId() async throws -> String? {
        guard let id = defaults.string(forKey: activeIdKey) else { return nil }
        let all = try await fetchAll()
        if all.contains(where: { $0.id == id }) { return id }
        defaults.removeObject(forKey: activeIdKey)
        return nil
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

    // MARK: - Catalog preparation
    //
    // Replaces the former demo-seeding + migration logic. Production NEVER seeds demo
    // properties. Behaviour:
    //   • catalog.json missing               → create an empty catalog.
    //   • already prepared                   → leave the file untouched.
    //   • present but undecodable            → preserve unchanged, throw a recoverable error.
    //   • present and decodable (first run)  → take one validated backup, then normalise in place.

    func prepareCatalog() async throws {
        // 1. Missing file → create an empty catalog. Never seed demo data.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            try writeEmptyCatalog()
            defaults.set(true, forKey: preparedKey)
            return
        }

        // 2. Already prepared → never touch an existing catalog again.
        guard !defaults.bool(forKey: preparedKey) else { return }

        // 3. Validate that the existing file decodes. If not, preserve it and report.
        let existing: [Property]
        do {
            let data = try Data(contentsOf: fileURL)
            existing = data.isEmpty ? [] : try decoder.decode([Property].self, from: data)
        } catch {
            // Existing-but-unreadable catalog: never overwrite, surface a recoverable error.
            throw CatalogError.unreadableCatalog(underlying: error)
        }

        // 4. Replacement (migration normalisation): one validated backup first.
        try makeValidatedBackup()

        let normalised = try encoder.encode(existing)
        try normalised.write(to: fileURL, options: .atomic)
        seedCodeCounterIfNeeded(from: existing)
        defaults.set(true, forKey: preparedKey)
    }

    // MARK: - Helpers

    private func writeEmptyCatalog() throws {
        let data = try encoder.encode([Property]())
        try data.write(to: fileURL, options: .atomic)
    }

    /// Copies the current catalog into the single backup slot atomically, after validating
    /// that the source decodes and that the written copy is byte-identical to the source.
    /// The backup is never auto-restored.
    private func makeValidatedBackup() throws {
        let sourceData: Data
        do {
            sourceData = try Data(contentsOf: fileURL)
            _ = sourceData.isEmpty ? [] : try decoder.decode([Property].self, from: sourceData)
        } catch {
            throw CatalogError.unreadableCatalog(underlying: error)
        }

        let tmp = fileURL.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".backup.tmp")
        do {
            try sourceData.write(to: tmp, options: .atomic)
            let written = try Data(contentsOf: tmp)
            guard written == sourceData else { throw CatalogError.backupValidationFailed }
            if FileManager.default.fileExists(atPath: backupURL.path) {
                _ = try FileManager.default.replaceItemAt(backupURL, withItemAt: tmp)
            } else {
                try FileManager.default.moveItem(at: tmp, to: backupURL)
            }
        } catch let catalogError as CatalogError {
            try? FileManager.default.removeItem(at: tmp)
            throw catalogError
        } catch {
            try? FileManager.default.removeItem(at: tmp)
            throw CatalogError.backupFailed(underlying: error)
        }
    }

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
