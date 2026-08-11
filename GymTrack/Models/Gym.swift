import Foundation
import SwiftData

@Model
final class Gym {
    var id: UUID = UUID()
    var name: String = ""
    var note: String? = nil
    var isActive: Bool = false
    var createdAt: Date = Date.now

    // Inverse sides of one-directional relationships declared on SetEntry/WorkoutSession/PersonalRecord.
    // SwiftData+CloudKit requires every relationship to have an explicit inverse.
    @Relationship(inverse: \SetEntry.gym)
    var setEntries: [SetEntry]? = []

    @Relationship(inverse: \WorkoutSession.gym)
    var sessions: [WorkoutSession]? = []

    @Relationship(inverse: \PersonalRecord.gym)
    var personalRecords: [PersonalRecord]? = []

    /// An equipment note is meaningless without its Gym, so it cascade-deletes.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseGymNote.gym)
    var exerciseNotes: [ExerciseGymNote]? = []

    /// A reminder is meaningless without its Gym, so it cascade-deletes.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseGymReminder.gym)
    var exerciseReminders: [ExerciseGymReminder]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        note: String? = nil,
        isActive: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
