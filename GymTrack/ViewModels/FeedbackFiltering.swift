import Foundation

/// Combines the priority and resolved-state filters shown as chips/segments in
/// `DeveloperModeView` — kept out of the view so the filter combination is unit-testable.
enum FeedbackFiltering {
    static func filter(_ entries: [FeedbackEntry], priority: FeedbackPriority?, onlyOpen: Bool) -> [FeedbackEntry] {
        entries.filter { entry in
            (priority == nil || entry.priority == priority) &&
            (onlyOpen ? !entry.isResolved : entry.isResolved)
        }
    }
}
