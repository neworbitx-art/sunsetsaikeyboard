import SwiftUI

@main
struct SunsetsPropertiesApp: App {
    private let repository: LocalPropertyRepository

    init() {
        let repo = LocalPropertyRepository()
        self.repository = repo
        // Seed on first launch; subsequent launches are a no-op
        Task {
            try? await repo.seedIfNeeded(SeedData.properties)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(repository: repository)
        }
    }
}
