import Foundation

/// Progress of a single metric (weight or reps) toward its long-term target. Each metric is
/// tracked fully independently, matching the ticket's "Ziel-Wiederholungen und/oder
/// Ziel-Gewicht" phrasing rather than one combined "X reps at Y kg" target. `current == nil`
/// means no completed working set exists yet for this exercise — kept distinct from an actual 0
/// so the UI can show "noch keine protokollierten Sätze" instead of falsely implying no progress.
struct GoalMetricProgress: Equatable {
    let target: Double
    let current: Double?

    var fraction: Double {
        guard target > 0, let current else { return 0 }
        return min(1, max(0, current / target))
    }

    var remaining: Double {
        guard let current else { return target }
        return max(0, target - current)
    }

    var isAchieved: Bool {
        guard let current else { return false }
        return current >= target
    }
}

/// Derives goal progress from an exercise's own completed set history. Reuses the exact same
/// `SessionStatistics.eligibleSessions` + `isCompleted && .normal` filtering `PersonalRecordFinder`
/// already established (a goal needs a genuine working set, not a warmup/dropset). Deliberately
/// NOT gym-converted, unlike `PersonalRecordFinder` — this is a simple personal target, not a
/// gym-spanning comparison; `WorkoutRepetition` already set the precedent that not every
/// weight-comparing feature needs to chain through `GymConversion`.
enum GoalProgress {
    static func weightProgress(for exercise: Exercise, in sessions: [WorkoutSession], target: Double) -> GoalMetricProgress {
        let best = relevantSets(for: exercise, in: sessions).map(\.weight).max()
        return GoalMetricProgress(target: target, current: best)
    }

    static func repsProgress(for exercise: Exercise, in sessions: [WorkoutSession], target: Int) -> GoalMetricProgress {
        let best = relevantSets(for: exercise, in: sessions).map(\.reps).max()
        return GoalMetricProgress(target: Double(target), current: best.map(Double.init))
    }

    private static func relevantSets(for exercise: Exercise, in sessions: [WorkoutSession]) -> [SetEntry] {
        let exerciseID = exercise.id
        return SessionStatistics.eligibleSessions(sessions).flatMap { session in
            (session.sets ?? []).filter {
                $0.exercise?.id == exerciseID && $0.isCompleted && $0.setType == .normal
            }
        }
    }
}
