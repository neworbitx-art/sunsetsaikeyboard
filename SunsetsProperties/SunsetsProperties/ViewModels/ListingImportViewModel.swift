import Foundation

enum ListingImportState: Equatable {
    case idle
    case parsing
    case ready(PropertyDraft)
    case failed(String)

    // Equate by case only; the associated PropertyDraft content is not compared
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):       return true
        case (.parsing, .parsing): return true
        case (.ready, .ready):     return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

@Observable final class ListingImportViewModel {

    var rawText: String = ""
    var importState: ListingImportState = .idle

    private let parser: any ListingImportService
    private let repository: any PropertyRepository

    init(repository: any PropertyRepository, parser: any ListingImportService = LocalListingParser()) {
        self.repository = repository
        self.parser = parser
    }

    var canParse: Bool {
        !rawText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var draft: PropertyDraft? {
        if case .ready(let d) = importState { return d }
        return nil
    }

    func parse() async {
        importState = .parsing
        do {
            let result = try await parser.parse(rawText)
            importState = .ready(result)
        } catch {
            importState = .failed(error.localizedDescription)
        }
    }

    func reset() {
        rawText = ""
        importState = .idle
    }

    // Builds a PropertyEditorViewModel pre-filled from the current draft.
    // The caller is responsible for calling prepareForNew() on the returned VM.
    func makeEditorViewModel() -> PropertyEditorViewModel {
        let vm = PropertyEditorViewModel(repository: repository)
        if let d = draft { vm.load(from: d) }
        return vm
    }
}
