import Foundation

protocol PropertyRepository: AnyObject, Sendable {
    func fetchAll() async throws -> [Property]
    func save(_ property: Property) async throws
    func delete(id: String) async throws
    func fetchActiveId() async throws -> String?
    func setActiveId(_ id: String?) async throws
    func fetchEmployee() async throws -> String?
    func setEmployee(_ name: String) async throws

    // Milestone 1.1: internal code management
    // Returns the next available code WITHOUT consuming it (counter unchanged).
    // The counter advances only when save() succeeds with a new property.
    func peekNextInternalCode() async throws -> String
    func isInternalCodeUnique(_ code: String, excludingId: String?) async throws -> Bool
}
