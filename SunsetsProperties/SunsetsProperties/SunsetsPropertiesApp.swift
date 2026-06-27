import SwiftUI

@main
struct SunsetsPropertiesApp: App {
    private let repository: LocalPropertyRepository

    init() {
        let repo = LocalPropertyRepository()
        self.repository = repo
        Task {
            // Migrate first (backs up JSON and adds new fields with defaults)
            try? await repo.migrateIfNeeded()
            // Seed on first launch; subsequent launches are a no-op
            try? await repo.seedIfNeeded(SeedData.properties)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(repository: repository)
        }
    }
}
