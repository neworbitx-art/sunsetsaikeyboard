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

    // Incremented by every resetDraft() call. A parse task that started
    // before the last reset will see a mismatch and discard its result,
    // preventing stale .ready state from overwriting a clean .idle.
    private var analysisGeneration: Int = 0

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
        guard importState != .parsing else { return }
        let generation = analysisGeneration
        importState = .parsing
        do {
            let result = try await parser.parse(rawText)
            guard analysisGeneration == generation else { return }
            importState = .ready(result)
        } catch {
            guard analysisGeneration == generation else { return }
            importState = .failed(error.localizedDescription)
        }
    }

    /// Clears the presented draft and resets to idle so Analyze can be triggered
    /// again with the same pasted text. Called by ListingImportView's sheet
    /// onDismiss handler (fires on both Discard and Cancel).
    /// rawText is intentionally preserved so the user does not need to re-paste.
    func resetDraft() {
        analysisGeneration += 1
        importState = .idle
    }

    func reset() {
        rawText = ""
        analysisGeneration += 1
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
