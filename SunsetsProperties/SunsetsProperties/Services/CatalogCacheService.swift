import Foundation
import Observation

// MARK: - Cache Service

@Observable
final class CatalogCacheService {

    // MARK: - Published status (for SettingsView diagnostics)
    private(set) var lastPublishedAt: Date?
    private(set) var catalogVersion: Int = 0
    private(set) var totalPropertyCount: Int = 0       // all in repository
    private(set) var publishedPropertyCount: Int = 0   // passed cache filter
    private(set) var excludedPropertyCount: Int = 0    // failed cache filter (empty id/code)
    private(set) var totalMessageCount: Int = 0        // all in message repository
    private(set) var publishedMessageCount: Int = 0    // isEnabled && isKeyboardVisible
    private(set) var publishedInternalCodes: [String] = []
    private(set) var approximateCacheSizeBytes: Int = 0
    private(set) var appGroupAvailable: Bool = false
    private(set) var lastError: String?

    // Stored message repository — set on first publish that provides one, used by all
    // subsequent publish calls that don't explicitly provide one.
    private var _messageRepository: (any GeneralMessageRepository)?

    private let appGroupID = "group.com.sunsetsrealestate.sunsetsai"
    private let catalogFileName = "keyboard_catalog.json"
    private let versionKey = "catalog_version"
    private let updatedAtKey = "catalog_updated_at"
    private let activePropertyIDKey = "active_property_id"

    // Override for unit tests: bypasses App Group and shared UserDefaults.
    private let _testSnapshotURL: URL?
    private var _testVersion: Int = 0
    private let _menuPreferences: KeyboardMenuPreferencesService?

    init(snapshotURL: URL? = nil, menuPreferences: KeyboardMenuPreferencesService? = nil) {
        _testSnapshotURL = snapshotURL
        _menuPreferences = menuPreferences
    }

    private var appGroupContainer: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private var catalogFileURL: URL? {
        if let url = _testSnapshotURL { return url }
        guard let base = appGroupContainer else { return nil }
        let dir = base.appendingPathComponent("Library/Application Support", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(catalogFileName)
    }

    private var sharedDefaults: UserDefaults? {
        _testSnapshotURL != nil ? nil : UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Publish

    func publish(
        repository: any PropertyRepository,
        messageRepository: (any GeneralMessageRepository)? = nil
    ) async {
        // Persist the provided message repository for future publish calls that omit it.
        // This ensures CatalogViewModel, ActivePropertyViewModel, and SettingsView all
        // keep general messages in the snapshot even when they only pass the property repo.
        if let msgRepo = messageRepository {
            _messageRepository = msgRepo
        }
        let effectiveMsgRepo = messageRepository ?? _messageRepository

        do {
            let all = try await repository.fetchAll()
            let activeID = try await repository.fetchActiveId()

            let currentVersion = sharedDefaults?.integer(forKey: versionKey) ?? _testVersion
            let nextVersion = currentVersion + 1

            let active = activeID.flatMap { id in all.first { $0.id == id } }
            let valid = all.filter { $0.isValidForCache }
            let excluded = all.count - valid.count
            let projected = valid.map { KeyboardSafeProperty(projecting: $0) }

            var allMessages: [GeneralMessageTemplate] = []
            var publishedMessages: [KeyboardSafeGeneralMessage] = []
            if let msgRepo = effectiveMsgRepo {
                allMessages = try await msgRepo.fetchAll()
                let visible = allMessages
                    .filter { $0.isEnabled && $0.isKeyboardVisible }
                    .sorted { $0.sortOrder < $1.sortOrder }
                publishedMessages = visible.map { KeyboardSafeGeneralMessage(projecting: $0) }
            }

            guard let fileURL = catalogFileURL else {
                throw CacheError.appGroupUnavailable
            }

            let menuActions = _menuPreferences?.actions ?? KeyboardMenuPreferencesService.defaultActions

            let snapshot = KeyboardCatalogSnapshot(
                schemaVersion: KeyboardCatalogSnapshot.currentSchemaVersion,
                catalogVersion: nextVersion,
                generatedAt: Date(),
                activePropertyID: active?.id,
                properties: projected,
                generalMessages: publishedMessages,
                menuActions: menuActions
            )

            let encoder = makeEncoder()
            let data = try encoder.encode(snapshot)
            try atomicWrite(data: data, to: fileURL)

            sharedDefaults?.set(nextVersion, forKey: versionKey)
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
            if _testSnapshotURL != nil { _testVersion = nextVersion }

            let codes = projected.map { $0.internalCode }

            await MainActor.run {
                catalogVersion = nextVersion
                totalPropertyCount = all.count
                publishedPropertyCount = projected.count
                excludedPropertyCount = excluded
                totalMessageCount = allMessages.count
                publishedMessageCount = publishedMessages.count
                publishedInternalCodes = codes
                approximateCacheSizeBytes = data.count
                appGroupAvailable = true
                lastPublishedAt = Date()
                lastError = excluded > 0
                    ? "\(excluded) propiedad(es) excluida(s) del catálogo (sin UUID o código interno)."
                    : nil
            }
        } catch {
            await MainActor.run {
                appGroupAvailable = !(error is CacheError)
                lastError = "Error al publicar el catálogo: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Clear cache

    func clearCache() {
        guard let fileURL = catalogFileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
        sharedDefaults?.removeObject(forKey: versionKey)
        sharedDefaults?.removeObject(forKey: updatedAtKey)
        sharedDefaults?.removeObject(forKey: activePropertyIDKey)
        _testVersion = 0
        lastPublishedAt = nil
        catalogVersion = 0
        totalPropertyCount = 0
        publishedPropertyCount = 0
        excludedPropertyCount = 0
        totalMessageCount = 0
        publishedMessageCount = 0
        publishedInternalCodes = []
        approximateCacheSizeBytes = 0
        appGroupAvailable = false
        lastError = nil
    }

    // MARK: - Status

    var formattedCacheSize: String {
        let kb = Double(approximateCacheSizeBytes) / 1024
        if kb < 1 { return "\(approximateCacheSizeBytes) B" }
        return String(format: "%.1f KB", kb)
    }

    // MARK: - Helpers

    private func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }

    private func atomicWrite(data: Data, to url: URL) throws {
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try? FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }
}

// MARK: - Errors

private enum CacheError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "El contenedor compartido del App Group no está disponible. Verifique los permisos de acceso."
        }
    }
}
