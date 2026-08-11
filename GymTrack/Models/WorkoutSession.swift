import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startedAt: Date = Date.now
    var endedAt: Date? = nil
    var planName: String? = nil
    var gym: Gym? = nil

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.session)
    var sets: [SetEntry]? = []

    var isCompleted: Bool { endedAt != nil }

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        endedAt: Date? = nil,
        planName: String? = nil,
        gym: Gym? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.planName = planName
        self.gym = gym
    }
}
