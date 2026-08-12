import Foundation

/// Identifies sets a user never marked done, so ending a workout can offer to remove
/// them in one tap rather than leaving them to silently skew future statistics.
enum WorkoutCompletion {
    static func incompleteSets(in session: WorkoutSession) -> [SetEntry] {
        (session.sets ?? []).filter { !$0.isCompleted }
    }
}
