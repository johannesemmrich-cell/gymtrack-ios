import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscleGroupRawValue: String = MuscleGroup.other.rawValue
    var isCustom: Bool = false
    var notes: String? = nil
    var createdAt: Date = Date.now

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRawValue) ?? .other }
        set { muscleGroupRawValue = newValue.rawValue }
    }

    // Inverse sides of one-directional relationships declared on PlanExercise/SetEntry/PersonalRecord.
    // SwiftData+CloudKit requires every relationship to have an explicit inverse.
    @Relationship(inverse: \PlanExercise.exercise)
    var planExercises: [PlanExercise]? = []

    @Relationship(inverse: \SetEntry.exercise)
    var setEntries: [SetEntry]? = []

    @Relationship(inverse: \PersonalRecord.exercise)
    var personalRecords: [PersonalRecord]? = []

    /// An equipment note is meaningless without its Exercise, so it cascade-deletes.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseGymNote.exercise)
    var gymNotes: [ExerciseGymNote]? = []

    /// A reminder is meaningless without its Exercise, so it cascade-deletes.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseGymReminder.exercise)
    var gymReminders: [ExerciseGymReminder]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        muscleGroup: MuscleGroup = .other,
        isCustom: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRawValue = muscleGroup.rawValue
        self.isCustom = isCustom
        self.notes = notes
        self.createdAt = createdAt
    }
}
