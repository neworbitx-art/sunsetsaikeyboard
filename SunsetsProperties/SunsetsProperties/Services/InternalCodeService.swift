import Foundation

// Pure formatting and parsing logic for SUN-### internal codes.
// Persistence of the counter lives in LocalPropertyRepository.
enum InternalCodeService {

    static func format(number: Int) -> String {
        String(format: "SUN-%03d", number)
    }

    static func extractNumber(from code: String) -> Int? {
        guard code.hasPrefix("SUN-") else { return nil }
        return Int(code.dropFirst(4))
    }

    // Only used for uniqueness checking / display; do NOT use for generation
    // (generation must use the persisted counter in the repository).
    static func maxNumber(in codes: [String]) -> Int {
        codes.compactMap { extractNumber(from: $0) }.max() ?? 0
    }
}
