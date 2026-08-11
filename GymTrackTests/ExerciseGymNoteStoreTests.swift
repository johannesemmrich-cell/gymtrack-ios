import XCTest
import SwiftData
@testable import GymTrack

@MainActor
final class ExerciseGymNoteStoreTests: XCTestCase {

    private func makeContext() -> ModelContext {
        ModelContext(PersistenceController.makeInMemoryContainer())
    }

    func testCreatesNoteWhenNoneExists() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gym = Gym(name: "Frankfurt")
        context.insert(exercise)
        context.insert(gym)
        try context.save()

        let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gym, in: context)
        XCTAssertEqual(note.exercise?.id, exercise.id)
        XCTAssertEqual(note.gym?.id, gym.id)
        XCTAssertEqual(note.note, "")
    }

    func testReturnsSameNoteOnSecondCallInsteadOfDuplicating() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gym = Gym(name: "Frankfurt")
        context.insert(exercise)
        context.insert(gym)
        try context.save()

        let first = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gym, in: context)
        first.note = "Sitz Stufe 4"
        try context.save()

        let second = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gym, in: context)
        XCTAssertEqual(second.note, "Sitz Stufe 4")

        let all = try context.fetch(FetchDescriptor<ExerciseGymNote>())
        XCTAssertEqual(all.count, 1, "Must not create a duplicate note for the same (exercise, gym) pair")
    }

    func testScopedPerGymDoesNotReturnAnotherGymsNote() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gymA = Gym(name: "Heimat-Gym")
        let gymB = Gym(name: "Frankfurt")
        context.insert(exercise)
        context.insert(gymA)
        context.insert(gymB)
        try context.save()

        let noteA = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gymA, in: context)
        noteA.note = "Sitz Stufe 2"
        try context.save()

        let noteB = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gymB, in: context)
        XCTAssertNotEqual(noteB.id, noteA.id)
        XCTAssertEqual(noteB.note, "")
    }
}
