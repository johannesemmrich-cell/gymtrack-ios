import Foundation

/// Suggests target sets/reps/weight for adding an exercise to a plan, based on
/// how it was last configured across all existing plans, falling back to 3x10.
enum PlanExerciseDefaults {
    static let fallbackSets = 3
    static let fallbackReps = 10

    static func suggest(
        for exercise: Exercise,
        from allPlanExercises: [PlanExercise]
    ) -> (sets: Int, reps: Int, weight: Double?) {
        let exerciseID = exercise.id
        let candidates = allPlanExercises.filter { $0.exercise?.id == exerciseID }
        guard let mostRecent = candidates.max(by: { first, second in
            first.updatedAt < second.updatedAt
        }) else {
            return (fallbackSets, fallbackReps, nil)
        }
        return (mostRecent.targetSets, mostRecent.targetReps, mostRecent.targetWeight)
    }
}
