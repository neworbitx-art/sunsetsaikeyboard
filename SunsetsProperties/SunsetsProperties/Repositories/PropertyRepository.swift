import Foundation

protocol PropertyRepository: AnyObject, Sendable {
    func fetchAll() async throws -> [Property]
    func save(_ property: Property) async throws
    func delete(id: String) async throws
    func fetchActiveId() async throws -> String?
    func setActiveId(_ id: String?) async throws
    func fetchEmployee() async throws -> String?
    func setEmployee(_ name: String) async throws
}
