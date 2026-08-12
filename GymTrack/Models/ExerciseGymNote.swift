import Foundation
import SwiftData

/// Permanent, auto-recalled equipment note for one (Exercise, Gym) pair — e.g. seat position or grip.
/// Meaningless without both anchors, so it cascade-deletes with either one.
@Model
final class ExerciseGymNote {
    var id: UUID = UUID()
    var note: String = ""
    var updatedAt: Date = Date.now
    /// Per-exercise override of the gym's `weightConversionFactor`. `nil` means "no override,
    /// use the gym's global factor". See `GymConversion`.
    var conversionFactor: Double? = nil

    var exercise: Exercise? = nil
    var gym: Gym? = nil

    init(
        id: UUID = UUID(),
        note: String = "",
        updatedAt: Date = .now,
        conversionFactor: Double? = nil,
        exercise: Exercise? = nil,
        gym: Gym? = nil
    ) {
        self.id = id
        self.note = note
        self.updatedAt = updatedAt
        self.conversionFactor = conversionFactor
        self.exercise = exercise
        self.gym = gym
    }
}
