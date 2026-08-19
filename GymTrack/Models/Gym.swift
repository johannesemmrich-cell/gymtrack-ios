import Foundation
import SwiftData

@Model
final class Gym {
    var id: UUID = UUID()
    var name: String = ""
    var note: String? = nil
    var isActive: Bool = false
    var createdAt: Date = Date.now
    /// Multiplier to make this gym's logged weights comparable to other gyms (e.g. a machine
    /// calibrated differently). 1.0 means "no conversion". See `GymConversion`.
    var weightConversionFactor: Double = 1.0

    // Inverse sides of one-directional relationships declared on SetEntry/WorkoutSession/PersonalRecord.
    // SwiftData+CloudKit requires every relationship to have an explicit inverse.
    @Relationship(inverse: \SetEntry.gym)
    var setEntries: [SetEntry]? = []

    @Relationship(inverse: \WorkoutSession.gym)
    var sessions: [WorkoutSession]? = []

    /// No delete rule specified — defaults to nullify, matching every other inverse here. A
    /// plan tied to this gym (see `TrainingPlan.gym`) is still a perfectly usable plan after
    /// the gym is deleted; it just goes back to "no specific gym" instead of being deleted too.
    @Relationship(inverse: \TrainingPlan.gym)
    var plans: [TrainingPlan]? = []

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
        createdAt: Date = .now,
        weightConversionFactor: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.isActive = isActive
        self.createdAt = createdAt
        self.weightConversionFactor = weightConversionFactor
    }
}
