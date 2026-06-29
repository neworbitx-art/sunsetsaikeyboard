import Foundation

// MARK: - Protocol

protocol GeneralMessageRepository: AnyObject, Sendable {
    func fetchAll() async throws -> [GeneralMessageTemplate]
    func save(_ template: GeneralMessageTemplate) async throws
    func delete(id: UUID) async throws
    func reorder(_ ids: [UUID]) async throws
}

// MARK: - Local implementation

final class LocalGeneralMessageRepository: GeneralMessageRepository {

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
    }

    static func defaultFileURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("SunsetsProperties", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("general_messages.json")
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func fetchAll() async throws -> [GeneralMessageTemplate] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([GeneralMessageTemplate].self, from: data)
    }

    func save(_ template: GeneralMessageTemplate) async throws {
        var all = try await fetchAll()
        if let idx = all.firstIndex(where: { $0.id == template.id }) {
            all[idx] = template
        } else {
            var t = template
            t.sortOrder = all.count
            all.append(t)
        }
        try write(all)
    }

    func delete(id: UUID) async throws {
        var all = try await fetchAll()
        all.removeAll { $0.id == id }
        // Re-assign sort orders after deletion
        for i in all.indices { all[i].sortOrder = i }
        try write(all)
    }

    func reorder(_ ids: [UUID]) async throws {
        var all = try await fetchAll()
        let indexed = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var reordered: [GeneralMessageTemplate] = []
        for (pos, id) in ids.enumerated() {
            if var t = indexed[id] {
                t.sortOrder = pos
                reordered.append(t)
            }
        }
        // Append any items not in the provided order list
        let reorderedIDs = Set(ids)
        for var t in all where !reorderedIDs.contains(t.id) {
            t.sortOrder = reordered.count
            reordered.append(t)
        }
        all = reordered
        try write(all)
    }

    private func write(_ templates: [GeneralMessageTemplate]) throws {
        let data = try encoder.encode(templates)
        let tmp = fileURL.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tmp, options: .atomic)
        _ = try? FileManager.default.replaceItemAt(fileURL, withItemAt: tmp)
    }
}
