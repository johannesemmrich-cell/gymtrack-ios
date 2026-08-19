import Foundation
import SwiftData

/// A user-set long-term target for one exercise — target weight, target reps, or both. One goal
/// per exercise; editing overwrites the existing goal rather than keeping a history (mirrors
/// `ExerciseGymNote`'s single-current-value pattern, not an achievement log like `PersonalRecord`).
@Model
final class ExerciseGoal {
    var id: UUID = UUID()
    var targetWeight: Double? = nil
    var targetReps: Int? = nil
    var updatedAt: Date = Date.now

    var exercise: Exercise? = nil

    init(
        id: UUID = UUID(),
        targetWeight: Double? = nil,
        targetReps: Int? = nil,
        updatedAt: Date = .now,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.updatedAt = updatedAt
        self.exercise = exercise
    }
}
