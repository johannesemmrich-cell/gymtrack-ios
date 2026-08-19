import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        Gym.self,
        Exercise.self,
        TrainingPlan.self,
        PlanExercise.self,
        WorkoutSession.self,
        SetEntry.self,
        PersonalRecord.self,
        ExerciseGymNote.self,
        ExerciseGymReminder.self,
        FeedbackEntry.self,
        DevTodoItem.self,
        ExerciseGoal.self
    ])

    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
