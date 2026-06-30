import Testing
import Foundation
@testable import SunsetsProperties

/// Regression coverage for the catalog data-loss repair.
///
/// Serialized because every case touches the filesystem; serial execution keeps the
/// scenarios independent and deterministic.
@Suite("Catalog Persistence", .serialized)
struct CatalogPersistenceTests {

    /// Each fixture pairs a unique on-disk catalog file with a unique UserDefaults suite —
    /// mirroring the real repository's split between data (Application Support) and flags
    /// (UserDefaults), the exact divergence that caused the original data loss.
    struct Fixture {
        let repo: LocalPropertyRepository
        let fileURL: URL
        let backupURL: URL
        let defaults: UserDefaults
    }

    func makeFixture() -> Fixture {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("catalog_persistence_\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("catalog.json")
        let backupURL = dir.appendingPathComponent("catalog.backup.json")
        let defaults = UserDefaults(suiteName: "test.catalog.\(UUID().uuidString)")!
        let repo = LocalPropertyRepository(fileURL: fileURL, defaults: defaults)
        return Fixture(repo: repo, fileURL: fileURL, backupURL: backupURL, defaults: defaults)
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

    /// The demo internal codes that production must never reintroduce (SUN-001…SUN-006).
    private var demoCodes: Set<String> { Set(SeedData.properties.map(\.internalCode)) }

    // 1. Fresh install: no catalog file → empty catalog, never demo data.
    @Test func freshInstallCreatesEmptyCatalogWithoutDemoData() async throws {
        let f = makeFixture()
        #expect(!FileManager.default.fileExists(atPath: f.fileURL.path))

        try await f.repo.prepareCatalog()

        #expect(FileManager.default.fileExists(atPath: f.fileURL.path))
        let all = try await f.repo.fetchAll()
        #expect(all.isEmpty)
        // Nothing to back up on a fresh install.
        #expect(!FileManager.default.fileExists(atPath: f.backupURL.path))
    }

    // 2. Relaunch: prepare is idempotent and never rewrites or reintroduces data.
    @Test func relaunchKeepsCatalogUnchanged() async throws {
        let f = makeFixture()
        try await f.repo.prepareCatalog()
        try await f.repo.save(makeSampleProperty(id: "real-1", code: "SUN-100"))
        let before = try Data(contentsOf: f.fileURL)

        // Simulate subsequent cold launches.
        try await f.repo.prepareCatalog()
        try await f.repo.prepareCatalog()

        let after = try Data(contentsOf: f.fileURL)
        #expect(before == after)
        let all = try await f.repo.fetchAll()
        #expect(all.map(\.internalCode) == ["SUN-100"])
    }

    // 3. Update install: existing pre-migration catalog → preserved, normalised, one backup taken.
    @Test func updateInstallMigratesAndPreservesData() async throws {
        let f = makeFixture()
        // Existing real catalog written directly, with the prepared flag unset (older build).
        let existing = [
            makeSampleProperty(id: "u1", code: "SUN-010"),
            makeSampleProperty(id: "u2", code: "SUN-011", favorite: true),
        ]
        try encoder.encode(existing).write(to: f.fileURL, options: .atomic)

        try await f.repo.prepareCatalog()

        let all = try await f.repo.fetchAll()
        #expect(Set(all.map(\.id)) == ["u1", "u2"])
        #expect(all.first { $0.id == "u2" }?.isFavorite == true)
        // Exactly one validated backup of the pre-migration catalog exists.
        #expect(FileManager.default.fileExists(atPath: f.backupURL.path))
        let backup = try decoder.decode([Property].self, from: Data(contentsOf: f.backupURL))
        #expect(Set(backup.map(\.id)) == ["u1", "u2"])
    }

    // 4. Corrupt catalog: non-JSON bytes → preserved unchanged, recoverable error, no overwrite.
    @Test func corruptCatalogIsPreservedAndReported() async throws {
        let f = makeFixture()
        let garbage = Data("}{ not json at all".utf8)
        try garbage.write(to: f.fileURL, options: .atomic)

        await #expect(throws: LocalPropertyRepository.CatalogError.self) {
            try await f.repo.prepareCatalog()
        }

        // File left byte-for-byte unchanged; no backup of garbage written.
        #expect(try Data(contentsOf: f.fileURL) == garbage)
        #expect(!FileManager.default.fileExists(atPath: f.backupURL.path))
    }

    // 5. Migration failure: valid JSON but schema-invalid records → preserved, error, no overwrite.
    @Test func migrationFailureLeavesCatalogIntact() async throws {
        let f = makeFixture()
        // Valid JSON array, but the object is missing required Property fields → decode throws.
        let schemaInvalid = Data("""
        [ { "id": "x", "internalCode": "SUN-077" } ]
        """.utf8)
        try schemaInvalid.write(to: f.fileURL, options: .atomic)

        await #expect(throws: LocalPropertyRepository.CatalogError.self) {
            try await f.repo.prepareCatalog()
        }

        #expect(try Data(contentsOf: f.fileURL) == schemaInvalid)
        #expect(!FileManager.default.fileExists(atPath: f.backupURL.path))
    }

    // 6. No demo reseed even when the prepared flag is lost while real data survives —
    //    the exact original data-loss scenario.
    @Test func lostFlagNeverReseedsDemoData() async throws {
        let f = makeFixture()
        try await f.repo.prepareCatalog()
        try await f.repo.save(makeSampleProperty(id: "keep-1", code: "SUN-200"))

        // Simulate the UserDefaults/file divergence: flag gone, catalog file intact.
        f.defaults.removeObject(forKey: "catalogPrepared_v2")

        try await f.repo.prepareCatalog()

        let all = try await f.repo.fetchAll()
        #expect(all.map(\.internalCode) == ["SUN-200"])
        #expect(Set(all.map(\.internalCode)).isDisjoint(with: demoCodes))
    }

    // 7. Favorites persist from the single isFavorite source and drive the Favorites filter.
    @Test func favoritesPersistFromSingleSourceAndFilterMatches() async throws {
        let f = makeFixture()
        try await f.repo.prepareCatalog()
        let vm = CatalogViewModel(repository: f.repo)

        try await f.repo.save(makeSampleProperty(id: "fav", code: "SUN-301", favorite: false))
        try await f.repo.save(makeSampleProperty(id: "plain", code: "SUN-302", favorite: false))
        await vm.load()

        // Toggle through the view model — the only mutation path for favorites.
        let target = try #require(vm.properties.first { $0.id == "fav" })
        await vm.toggleFavorite(target)

        // Persisted to the catalog file (single source of truth).
        let reread = try await f.repo.fetchAll()
        #expect(reread.first { $0.id == "fav" }?.isFavorite == true)
        #expect(reread.first { $0.id == "plain" }?.isFavorite == false)

        // Favorites filter matches exactly the isFavorite source.
        vm.selectedFilter = .favorites
        #expect(vm.filteredProperties.map(\.id) == ["fav"])
    }

    // 8. Active property pointer is kept only when the referenced UUID exists.
    @Test func activePropertyKeptOnlyWhenItExists() async throws {
        let f = makeFixture()
        try await f.repo.prepareCatalog()
        try await f.repo.save(makeSampleProperty(id: "active-1", code: "SUN-401"))

        try await f.repo.setActiveId("active-1")
        #expect(try await f.repo.fetchActiveId() == "active-1")

        // A pointer to a non-existent UUID is not honoured and is cleared.
        try await f.repo.setActiveId("ghost")
        #expect(try await f.repo.fetchActiveId() == nil)
        #expect(f.defaults.string(forKey: "activePropertyId") == nil)

        // Deleting the active property clears the pointer.
        try await f.repo.setActiveId("active-1")
        try await f.repo.delete(id: "active-1")
        #expect(try await f.repo.fetchActiveId() == nil)
    }
}
