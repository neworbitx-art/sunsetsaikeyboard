import Foundation
import Observation

enum CatalogFilter: String, CaseIterable, Identifiable {
    case all
    case available
    case reserved
    case rented
    case sold
    case inactive
    case rent
    case sale
    case favorites

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:       return "Todas"
        case .available: return "Disponibles"
        case .reserved:  return "Reservadas"
        case .rented:    return "Rentadas"
        case .sold:      return "Vendidas"
        case .inactive:  return "Inactivas"
        case .rent:      return "Renta"
        case .sale:      return "Venta"
        case .favorites: return "Favoritas"
        }
    }
}

@Observable
final class CatalogViewModel {

    var properties: [Property] = []
    var searchText: String = ""
    var selectedFilter: CatalogFilter = .all
    var isLoading: Bool = false
    var errorMessage: String?

    private let repository: any PropertyRepository
    private let cacheService: CatalogCacheService

    init(repository: any PropertyRepository, cacheService: CatalogCacheService = CatalogCacheService()) {
        self.repository = repository
        self.cacheService = cacheService
    }

    var filteredProperties: [Property] {
        var result = properties

        switch selectedFilter {
        case .all:       break
        case .available: result = result.filter { $0.status == .available }
        case .reserved:  result = result.filter { $0.status == .reserved }
        case .rented:    result = result.filter { $0.status == .rented }
        case .sold:      result = result.filter { $0.status == .sold }
        case .inactive:  result = result.filter { $0.status == .inactive }
        case .rent:      result = result.filter { $0.operationType == .rent || $0.operationType == .rentOrSale }
        case .sale:      result = result.filter { $0.operationType == .sale || $0.operationType == .rentOrSale }
        case .favorites: result = result.filter { $0.isFavorite }
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            result = result.filter {
                $0.displayTitle.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(query) ||
                $0.internalCode.lowercased().contains(query) ||
                $0.locationSummary.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(query)
            }
        }

        return result.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
            return $0.displayTitle.localizedCompare($1.displayTitle) == .orderedAscending
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            properties = try await repository.fetchAll()
        } catch {
            errorMessage = "No se pudieron cargar las propiedades."
        }
    }

    func save(_ property: Property) async {
        do {
            var updated = property
            updated.updatedAt = Date()
            try await repository.save(updated)
            await load()
            await cacheService.publish(repository: repository)
        } catch {
            errorMessage = "No se pudo guardar la propiedad."
        }
    }

    func delete(_ property: Property) async {
        do {
            try await repository.delete(id: property.id)
            await load()
            await cacheService.publish(repository: repository)
        } catch {
            errorMessage = "No se pudo eliminar la propiedad."
        }
    }

    func toggleFavorite(_ property: Property) async {
        var updated = property
        updated.isFavorite.toggle()
        await save(updated)
    }
}
