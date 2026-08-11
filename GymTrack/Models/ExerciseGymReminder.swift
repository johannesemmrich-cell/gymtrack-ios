import Foundation
import SwiftData

/// One-shot reminder for one (Exercise, Gym) pair — meant to be shown once at the next
/// training session for that combination, then marked consumed (or deleted) by the UI layer.
/// Meaningless without both anchors, so it cascade-deletes with either one.
@Model
final class ExerciseGymReminder {
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date.now
    var isConsumed: Bool = false

    var exercise: Exercise? = nil
    var gym: Gym? = nil

    init(
        id: UUID = UUID(),
        text: String = "",
        createdAt: Date = .now,
        isConsumed: Bool = false,
        exercise: Exercise? = nil,
        gym: Gym? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isConsumed = isConsumed
        self.exercise = exercise
        self.gym = gym
    }
}
