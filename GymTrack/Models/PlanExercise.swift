import Foundation
import SwiftData

@Model
final class PlanExercise {
    var id: UUID = UUID()
    var order: Int = 0
    var targetSets: Int = 3
    var targetReps: Int = 10
    var targetWeight: Double? = nil
    /// Free-text note scoped to this exercise within this plan (e.g. "Flachbank statt Schrägbank").
    var note: String? = nil
    /// Bumped whenever sets/reps/weight/note are tuned; used to find the most recently
    /// tuned entry for an exercise across plans, independent of unrelated edits to the
    /// parent plan (renaming it, touching a different exercise in it, etc.).
    var updatedAt: Date = Date.now
    /// Shared by every `PlanExercise` logged as one superset — `nil` means it's standalone.
    /// Propagated to each `SetEntry` built from it (see `WorkoutSessionBuilder`) so the same
    /// grouping carries through into an active workout.
    var supersetGroupID: UUID? = nil

    var plan: TrainingPlan? = nil
    var exercise: Exercise? = nil

    init(
        id: UUID = UUID(),
        order: Int = 0,
        targetSets: Int = 3,
        targetReps: Int = 10,
        targetWeight: Double? = nil,
        note: String? = nil,
        updatedAt: Date = .now,
        supersetGroupID: UUID? = nil,
        plan: TrainingPlan? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.note = note
        self.updatedAt = updatedAt
        self.supersetGroupID = supersetGroupID
        self.plan = plan
        self.exercise = exercise
    }
}
