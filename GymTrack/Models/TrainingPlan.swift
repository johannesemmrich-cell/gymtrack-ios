import Foundation
import SwiftData

@Model
final class TrainingPlan {
    var id: UUID = UUID()
    var name: String = ""
    var note: String? = nil
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \PlanExercise.plan)
    var exercises: [PlanExercise]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
