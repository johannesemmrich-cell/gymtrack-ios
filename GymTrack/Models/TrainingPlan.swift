import Foundation
import SwiftData

@Model
final class TrainingPlan {
    var id: UUID = UUID()
    var name: String = ""
    var note: String? = nil
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    /// Which gym this plan is meant for, if any — nil means "no specific gym / any gym".
    /// Inverse declared on `Gym.plans`; no delete rule there means nullify, so deleting the
    /// gym leaves this plan intact and simply un-assigned rather than deleting it too.
    var gym: Gym? = nil

    @Relationship(deleteRule: .cascade, inverse: \PlanExercise.plan)
    var exercises: [PlanExercise]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        gym: Gym? = nil
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.gym = gym
    }
}
