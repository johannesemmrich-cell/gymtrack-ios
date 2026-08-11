import Foundation
import SwiftData

/// Permanent, auto-recalled equipment note for one (Exercise, Gym) pair — e.g. seat position or grip.
/// Meaningless without both anchors, so it cascade-deletes with either one.
@Model
final class ExerciseGymNote {
    var id: UUID = UUID()
    var note: String = ""
    var updatedAt: Date = Date.now

    var exercise: Exercise? = nil
    var gym: Gym? = nil

    init(
        id: UUID = UUID(),
        note: String = "",
        updatedAt: Date = .now,
        exercise: Exercise? = nil,
        gym: Gym? = nil
    ) {
        self.id = id
        self.note = note
        self.updatedAt = updatedAt
        self.exercise = exercise
        self.gym = gym
    }
}
