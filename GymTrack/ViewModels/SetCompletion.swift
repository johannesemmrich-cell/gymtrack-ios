import Foundation

/// The auto-completion rule applied inline while logging a set: as soon as both a real
/// weight and rep count are present, the set counts as done — no separate manual step needed
/// for the common case. Deliberately ignores `suggestedWeight`/`suggestedReps` (ghost hints
/// never count as "entered"). Manual override for edge cases (e.g. a 0 kg bodyweight set)
/// stays available via the existing swipe-to-toggle action.
enum SetCompletion {
    static func isComplete(weight: Double, reps: Int) -> Bool {
        weight > 0 && reps > 0
    }
}
