import Foundation
import Observation
import SwiftUI

@Observable
final class GeneralMessagesViewModel {

    private(set) var templates: [GeneralMessageTemplate] = []
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    private let repository: any GeneralMessageRepository
    private let cacheService: CatalogCacheService
    private let propertyRepository: any PropertyRepository

    init(repository: any GeneralMessageRepository,
         cacheService: CatalogCacheService,
         propertyRepository: any PropertyRepository) {
        self.repository = repository
        self.cacheService = cacheService
        self.propertyRepository = propertyRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            templates = (try await repository.fetchAll()).sorted { $0.sortOrder < $1.sortOrder }
            error = nil
        } catch {
            self.error = "Error al cargar mensajes: \(error.localizedDescription)"
        }
    }

    // MARK: - Save

    func save(_ template: GeneralMessageTemplate) async {
        do {
            var updated = template
            updated.updatedAt = Date()
            try await repository.save(updated)
            templates = (try await repository.fetchAll()).sorted { $0.sortOrder < $1.sortOrder }
            await syncCache()
        } catch {
            self.error = "Error al guardar: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            templates = (try await repository.fetchAll()).sorted { $0.sortOrder < $1.sortOrder }
            await syncCache()
        } catch {
            self.error = "Error al eliminar: \(error.localizedDescription)"
        }
    }

    // MARK: - Reorder (drag and drop)

    func reorder(from source: IndexSet, to destination: Int) async {
        var reordered = templates
        reordered.move(fromOffsets: source, toOffset: destination)
        let ids = reordered.map { $0.id }
        do {
            try await repository.reorder(ids)
            templates = (try await repository.fetchAll()).sorted { $0.sortOrder < $1.sortOrder }
            await syncCache()
        } catch {
            self.error = "Error al reordenar: \(error.localizedDescription)"
        }
    }

    // MARK: - Cache sync

    private func syncCache() async {
        await cacheService.publish(repository: propertyRepository,
                                   messageRepository: repository)
    }
}
