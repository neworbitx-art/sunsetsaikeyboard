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
            // Ensure a valid catalog exists. Production never seeds demo data: a missing
            // catalog is created empty, and an existing-but-unreadable catalog is preserved
            // untouched (the load error surfaces in the catalog UI).
            try? await repo.prepareCatalog()
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
