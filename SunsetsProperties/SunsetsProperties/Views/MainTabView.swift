import SwiftUI

struct MainTabView: View {
    private let repository: any PropertyRepository
    private let cacheService: CatalogCacheService
    private let maintenanceService: StorageMaintenanceService
    private let menuPreferences: KeyboardMenuPreferencesService
    private let catalogVM: CatalogViewModel
    private let activeVM: ActivePropertyViewModel
    private let messagesVM: GeneralMessagesViewModel

    init(
        repository: any PropertyRepository,
        cacheService: CatalogCacheService,
        maintenanceService: StorageMaintenanceService,
        messageRepository: any GeneralMessageRepository,
        menuPreferences: KeyboardMenuPreferencesService
    ) {
        self.repository = repository
        self.cacheService = cacheService
        self.maintenanceService = maintenanceService
        self.menuPreferences = menuPreferences
        self.catalogVM = CatalogViewModel(repository: repository, cacheService: cacheService)
        self.activeVM = ActivePropertyViewModel(repository: repository, cacheService: cacheService)
        self.messagesVM = GeneralMessagesViewModel(repository: messageRepository,
                                                   cacheService: cacheService,
                                                   propertyRepository: repository)
    }

    var body: some View {
        TabView {
            CatalogView(viewModel: catalogVM, repository: repository)
                .tabItem {
                    Label("Propiedades", systemImage: "building.2")
                }

            ActivePropertyView(viewModel: activeVM)
                .tabItem {
                    Label("Propiedad activa", systemImage: "star.circle")
                }

            GeneralMessagesView(vm: messagesVM)
                .tabItem {
                    Label("Mensajes", systemImage: "text.bubble")
                }

            SettingsView(
                repository: repository,
                cacheService: cacheService,
                maintenanceService: maintenanceService,
                menuPreferences: menuPreferences
            )
            .tabItem {
                Label("Configuración", systemImage: "gearshape")
            }
        }
    }
}
