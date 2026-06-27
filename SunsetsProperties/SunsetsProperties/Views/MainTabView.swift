import SwiftUI

struct MainTabView: View {
    private let repository: any PropertyRepository
    private let catalogVM: CatalogViewModel
    private let activeVM: ActivePropertyViewModel

    init(repository: any PropertyRepository) {
        self.repository = repository
        self.catalogVM = CatalogViewModel(repository: repository)
        self.activeVM = ActivePropertyViewModel(repository: repository)
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

            SettingsView(repository: repository)
                .tabItem {
                    Label("Configuración", systemImage: "gearshape")
                }
        }
    }
}
