import Foundation

// MARK: - Catalog reader error

enum CatalogReaderError: LocalizedError {
    case appGroupUnavailable
    case fileNotFound
    case decodingFailed(Error)
    case unsupportedSchemaVersion(Int)
    case staleCache(Date)

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "El acceso completo no está habilitado. Active 'Permitir acceso completo' en Configuración → Teclados → SunsetsAIKeyboard."
        case .fileNotFound:
            return "No hay un catálogo disponible. Abra Sunsets Properties y toque 'Actualizar catálogo del teclado'."
        case .decodingFailed:
            return "El catálogo está dañado. Abra Sunsets Properties y toque 'Actualizar catálogo del teclado'."
        case .unsupportedSchemaVersion(let v):
            return "El catálogo usa un formato no compatible (versión \(v)). Actualice la aplicación Sunsets Properties."
        case .staleCache(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "es_GT")
            let relative = formatter.localizedString(for: date, relativeTo: Date())
            return "El catálogo fue actualizado \(relative). Abra Sunsets Properties para actualizar."
        }
    }
}

// MARK: - Catalog reader

final class CatalogReader {

    static let staleCacheThreshold: TimeInterval = 24 * 60 * 60  // 24 hours
    private let appGroupID = "group.com.sunsetsrealestate.sunsetsai"

    private var appGroupContainer: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private var catalogFileURL: URL? {
        appGroupContainer?
            .appendingPathComponent("Library/Application Support/keyboard_catalog.json")
    }

    // MARK: - Read snapshot

    func readSnapshot() throws -> KeyboardCatalogSnapshot {
        guard let fileURL = catalogFileURL else {
            throw CatalogReaderError.appGroupUnavailable
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CatalogReaderError.fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw CatalogReaderError.decodingFailed(error)
        }

        let snapshot: KeyboardCatalogSnapshot
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            snapshot = try decoder.decode(KeyboardCatalogSnapshot.self, from: data)
        } catch {
            throw CatalogReaderError.decodingFailed(error)
        }

        guard snapshot.schemaVersion <= KeyboardCatalogSnapshot.currentSchemaVersion else {
            throw CatalogReaderError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }

        return snapshot
    }

    // MARK: - Stale detection

    func isStale(_ snapshot: KeyboardCatalogSnapshot) -> Bool {
        Date().timeIntervalSince(snapshot.generatedAt) > Self.staleCacheThreshold
    }

    // MARK: - App Group defaults

    var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    var catalogUpdatedAt: Date? {
        guard let ts = sharedDefaults?.object(forKey: "catalog_updated_at") as? Double,
              ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }
}
