import Foundation

/// Shared `UserDefaults` key so every `@AppStorage` call site (unlock sheet, dev-mode view,
/// feedback overlay on each tab) observes the exact same flag.
enum DeveloperModeStorage {
    static let key = "isDeveloperModeActive"
}
