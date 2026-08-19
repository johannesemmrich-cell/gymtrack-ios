import Foundation
import SwiftData

/// Find-or-create for the single long-term goal per exercise.
/// SwiftData/CloudKit can't enforce uniqueness at the model layer, so this is
/// the single place that must be used to avoid creating duplicate goals.
enum ExerciseGoalStore {
    static func findOrCreate(exercise: Exercise, in context: ModelContext) -> ExerciseGoal {
        let exerciseID = exercise.id
        let all = (try? context.fetch(FetchDescriptor<ExerciseGoal>())) ?? []
        if let existing = all.first(where: { $0.exercise?.id == exerciseID }) {
            return existing
        }
        let goal = ExerciseGoal(exercise: exercise)
        context.insert(goal)
        return goal
    }
}
