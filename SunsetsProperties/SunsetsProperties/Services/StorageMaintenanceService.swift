import Foundation

// MARK: - Storage Maintenance Service

final class StorageMaintenanceService {

    private let repository: LocalPropertyRepository
    private let cacheService: CatalogCacheService
    private let messageRepository: LocalGeneralMessageRepository

    init(repository: LocalPropertyRepository, cacheService: CatalogCacheService,
         messageRepository: LocalGeneralMessageRepository = LocalGeneralMessageRepository()) {
        self.repository = repository
        self.cacheService = cacheService
        self.messageRepository = messageRepository
    }

    // MARK: - Size reporting

    var mainCatalogSizeBytes: Int {
        fileSizeBytes(at: LocalPropertyRepository.defaultFileURL())
    }

    var backupSizeBytes: Int {
        let backup = LocalPropertyRepository.defaultFileURL()
            .deletingPathExtension()
            .appendingPathExtension("backup.json")
        return fileSizeBytes(at: backup)
    }

    var formattedMainCatalogSize: String { formatBytes(mainCatalogSizeBytes) }
    var formattedBackupSize: String { formatBytes(backupSizeBytes) }

    // MARK: - Maintenance

    func removeStaleTempFiles() {
        let dir = LocalPropertyRepository.defaultFileURL().deletingLastPathComponent()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.isRegularFileKey]) else { return }

        for url in contents where url.pathExtension == "tmp" {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func pruneBackups() {
        let catalog = LocalPropertyRepository.defaultFileURL()
        let backup = catalog.deletingPathExtension().appendingPathExtension("backup.json")
        guard FileManager.default.fileExists(atPath: backup.path) else { return }

        // Keep only one backup — the current one. Remove extras if named differently.
        let dir = catalog.deletingLastPathComponent()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil) else { return }

        let extras = contents.filter {
            $0.lastPathComponent.hasPrefix("catalog") &&
            $0.pathExtension == "json" &&
            $0.lastPathComponent != "catalog.json" &&
            $0 != backup
        }
        for url in extras { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - Destructive: clear all local data

    func clearAllLocalData() async throws {
        // Remove main catalog
        let catalogURL = LocalPropertyRepository.defaultFileURL()
        try? FileManager.default.removeItem(at: catalogURL)

        // Remove migration backup
        let backupURL = catalogURL.deletingPathExtension().appendingPathExtension("backup.json")
        try? FileManager.default.removeItem(at: backupURL)

        // Remove stale temp files
        removeStaleTempFiles()

        // Reset all UserDefaults keys for the main app
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "activePropertyId")
        defaults.removeObject(forKey: "currentEmployee")
        defaults.removeObject(forKey: "catalogSeeded")
        defaults.removeObject(forKey: "lastIssuedInternalCodeNumber")
        defaults.removeObject(forKey: "catalogMigrated_1_1")

        // Reset App Group keys and cache
        let appGroupID = "group.com.zircondata.sunsetsai"
        if let groupDefaults = UserDefaults(suiteName: appGroupID) {
            groupDefaults.removeObject(forKey: "active_property_id")
            groupDefaults.removeObject(forKey: "keyboard_selected_property_id")
            groupDefaults.removeObject(forKey: "recent_property_ids")
            groupDefaults.removeObject(forKey: "current_employee")
            groupDefaults.removeObject(forKey: "catalog_version")
            groupDefaults.removeObject(forKey: "catalog_updated_at")
        }

        // Remove general messages store
        try? FileManager.default.removeItem(at: LocalGeneralMessageRepository.defaultFileURL())

        // Clear keyboard cache file
        cacheService.clearCache()
    }

    // MARK: - Restore demo data

    func restoreDemoData() async throws {
        try await repository.seedIfNeeded(SeedData.properties)
    }

    // MARK: - Helpers

    private func fileSizeBytes(at url: URL) -> Int {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes == 0 { return "0 B" }
        let kb = Double(bytes) / 1024
        if kb < 1 { return "\(bytes) B" }
        let mb = kb / 1024
        if mb < 1 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", mb)
    }
}
