import XCTest
import SwiftData
@testable import GymTrack

@MainActor
final class ExerciseGoalStoreTests: XCTestCase {

    private func makeContext() -> ModelContext {
        ModelContext(PersistenceController.makeInMemoryContainer())
    }

    func testCreatesGoalWhenNoneExists() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        context.insert(exercise)
        try context.save()

        let goal = ExerciseGoalStore.findOrCreate(exercise: exercise, in: context)
        XCTAssertEqual(goal.exercise?.id, exercise.id)
        XCTAssertNil(goal.targetWeight)
        XCTAssertNil(goal.targetReps)
    }

    func testReturnsSameGoalOnSecondCallInsteadOfDuplicating() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        context.insert(exercise)
        try context.save()

        let first = ExerciseGoalStore.findOrCreate(exercise: exercise, in: context)
        first.targetWeight = 100
        try context.save()

        let second = ExerciseGoalStore.findOrCreate(exercise: exercise, in: context)
        XCTAssertEqual(second.targetWeight, 100)

        let all = try context.fetch(FetchDescriptor<ExerciseGoal>())
        XCTAssertEqual(all.count, 1, "Must not create a duplicate goal for the same exercise")
    }

    func testScopedPerExerciseDoesNotReturnAnotherExercisesGoal() throws {
        let context = makeContext()
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        context.insert(bench)
        context.insert(squats)
        try context.save()

        let benchGoal = ExerciseGoalStore.findOrCreate(exercise: bench, in: context)
        benchGoal.targetWeight = 100
        try context.save()

        let squatsGoal = ExerciseGoalStore.findOrCreate(exercise: squats, in: context)
        XCTAssertNotEqual(squatsGoal.id, benchGoal.id)
        XCTAssertNil(squatsGoal.targetWeight)
    }
}
