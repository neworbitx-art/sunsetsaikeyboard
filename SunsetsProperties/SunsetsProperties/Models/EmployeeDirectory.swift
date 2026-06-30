import Foundation

/// The internal employee roster used by the mocked employee selector.
///
/// This is production configuration — not demo data — so it is always compiled into the app.
/// Real authentication replaces it in a later milestone.
enum EmployeeDirectory {
    static let all: [String] = ["Cristian", "Yessy"]
}
