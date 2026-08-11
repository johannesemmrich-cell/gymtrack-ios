import Foundation
import SwiftData

/// Find-or-create for the permanent per-(Exercise, Gym) equipment note.
/// SwiftData/CloudKit can't enforce uniqueness at the model layer, so this is
/// the single place that must be used to avoid creating duplicate notes.
enum ExerciseGymNoteStore {
    static func findOrCreate(exercise: Exercise, gym: Gym, in context: ModelContext) -> ExerciseGymNote {
        let exerciseID = exercise.id
        let gymID = gym.id
        let all = (try? context.fetch(FetchDescriptor<ExerciseGymNote>())) ?? []
        if let existing = all.first(where: { $0.exercise?.id == exerciseID && $0.gym?.id == gymID }) {
            return existing
        }
        let note = ExerciseGymNote(exercise: exercise, gym: gym)
        context.insert(note)
        return note
    }
}
