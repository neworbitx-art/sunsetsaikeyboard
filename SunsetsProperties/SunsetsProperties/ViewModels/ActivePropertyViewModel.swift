import Foundation
import Observation

@Observable
final class ActivePropertyViewModel {

    var activeProperty: Property?
    var allProperties: [Property] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let repository: any PropertyRepository
    private let cacheService: CatalogCacheService

    init(repository: any PropertyRepository, cacheService: CatalogCacheService = CatalogCacheService()) {
        self.repository = repository
        self.cacheService = cacheService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            allProperties = try await repository.fetchAll()
            if let activeId = try await repository.fetchActiveId() {
                activeProperty = allProperties.first { $0.id == activeId }
            } else {
                activeProperty = nil
            }
        } catch {
            errorMessage = "No se pudo cargar la propiedad activa."
        }
    }

    func setActive(_ property: Property) async {
        do {
            try await repository.setActiveId(property.id)
            activeProperty = property
            await cacheService.publish(repository: repository)
        } catch {
            errorMessage = "No se pudo establecer la propiedad activa."
        }
    }

    func clearActive() async {
        do {
            try await repository.setActiveId(nil)
            activeProperty = nil
            await cacheService.publish(repository: repository)
        } catch {
            errorMessage = "No se pudo limpiar la propiedad activa."
        }
    }
}
