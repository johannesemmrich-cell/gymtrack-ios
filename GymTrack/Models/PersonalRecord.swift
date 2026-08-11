import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: UUID = UUID()
    var estimatedOneRepMax: Double = 0
    var weight: Double = 0
    var reps: Int = 0
    var achievedAt: Date = Date.now

    var exercise: Exercise? = nil
    var gym: Gym? = nil

    init(
        id: UUID = UUID(),
        estimatedOneRepMax: Double = 0,
        weight: Double = 0,
        reps: Int = 0,
        achievedAt: Date = .now,
        exercise: Exercise? = nil,
        gym: Gym? = nil
    ) {
        self.id = id
        self.estimatedOneRepMax = estimatedOneRepMax
        self.weight = weight
        self.reps = reps
        self.achievedAt = achievedAt
        self.exercise = exercise
        self.gym = gym
    }
}
