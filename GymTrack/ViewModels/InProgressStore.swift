import Foundation

/// Tracks which dev-mode to-dos are currently being actively tested on this device —
/// separate from `DevTodoItem.isCompleted` (SwiftData/CloudKit) since "currently testing"
/// is transient, device-local state that has no business syncing across devices.
enum InProgressStore {
    private static let key = "devTodoInProgressIDs"

    static func isInProgress(_ id: UUID, defaults: UserDefaults = .standard) -> Bool {
        storedIDs(defaults: defaults).contains(id.uuidString)
    }

    /// All in-progress IDs as `UUID`s, for views that need to observe the whole set reactively
    /// (raw `UserDefaults` reads elsewhere are not observed by SwiftUI) rather than asking about
    /// one ID at a time.
    static func allIDs(defaults: UserDefaults = .standard) -> Set<UUID> {
        Set(storedIDs(defaults: defaults).compactMap(UUID.init))
    }

    static func setInProgress(_ id: UUID, _ value: Bool, defaults: UserDefaults = .standard) {
        var ids = storedIDs(defaults: defaults)
        if value {
            ids.insert(id.uuidString)
        } else {
            ids.remove(id.uuidString)
        }
        defaults.set(Array(ids), forKey: key)
    }

    private static func storedIDs(defaults: UserDefaults) -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }
}
