import SwiftUI

@main
struct SunsetsPropertiesApp: App {
    private let repository: LocalPropertyRepository
    private let messageRepository: LocalGeneralMessageRepository
    private let cacheService: CatalogCacheService
    private let maintenanceService: StorageMaintenanceService
    private let menuPreferences: KeyboardMenuPreferencesService

    init() {
        let repo = LocalPropertyRepository()
        let msgRepo = LocalGeneralMessageRepository()
        let menuPrefs = KeyboardMenuPreferencesService()
        let cache = CatalogCacheService(menuPreferences: menuPrefs)
        self.repository = repo
        self.messageRepository = msgRepo
        self.menuPreferences = menuPrefs
        self.cacheService = cache
        self.maintenanceService = StorageMaintenanceService(
            repository: repo,
            cacheService: cache,
            messageRepository: msgRepo
        )
        Task {
            try? await repo.migrateIfNeeded()
            try? await repo.seedIfNeeded(SeedData.properties)
            await cache.publish(repository: repo, messageRepository: msgRepo)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                repository: repository,
                cacheService: cacheService,
                maintenanceService: maintenanceService,
                messageRepository: messageRepository,
                menuPreferences: menuPreferences
            )
        }
    }
}
