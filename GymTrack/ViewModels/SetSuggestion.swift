import Foundation

/// Suggests the weight/reps to prefill for the next set of an exercise at a gym,
/// based on the most recent completed working set logged there.
enum SetSuggestion {
    static func suggest(
        for exercise: Exercise,
        gym: Gym,
        from allSetEntries: [SetEntry]
    ) -> (weight: Double, reps: Int)? {
        let exerciseID = exercise.id
        let gymID = gym.id
        let candidates = allSetEntries.filter {
            $0.exercise?.id == exerciseID
                && $0.gym?.id == gymID
                && $0.isCompleted
                && $0.setType == .normal
        }
        guard let mostRecent = candidates.max(by: { first, second in
            let firstDate: Date = first.session?.startedAt ?? .distantPast
            let secondDate: Date = second.session?.startedAt ?? .distantPast
            if firstDate != secondDate {
                return firstDate < secondDate
            }
            return first.order < second.order
        }) else {
            return nil
        }
        return (mostRecent.weight, mostRecent.reps)
    }
}
