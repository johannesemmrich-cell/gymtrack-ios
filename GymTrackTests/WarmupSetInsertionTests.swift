import XCTest
@testable import GymTrack

final class WarmupSetInsertionTests: XCTestCase {

    func testInsertsBeforeFirstNormalSetOfSameExercise() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession()
        let working = SetEntry(order: 0, setType: .normal, reps: 8, weight: 60, exercise: exercise, session: session)
        let warmup = SetEntry(setType: .warmup, reps: 10, weight: 30, exercise: exercise, session: session)

        let result = WarmupSetInsertion.insert(warmup, into: [working], forExerciseID: exercise.id)

        XCTAssertEqual(result.map { $0 === warmup ? "warmup" : "working" }, ["warmup", "working"])
    }

    func testAppendsAtEndWhenExerciseHasNoWorkingSetYet() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let other = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession()
        let otherWorking = SetEntry(order: 0, setType: .normal, reps: 5, weight: 100, exercise: other, session: session)
        let warmup = SetEntry(setType: .warmup, reps: 10, weight: 30, exercise: exercise, session: session)

        let result = WarmupSetInsertion.insert(warmup, into: [otherWorking], forExerciseID: exercise.id)

        XCTAssertEqual(result.last, warmup)
        XCTAssertEqual(result.first, otherWorking)
    }

    func testDoesNotReorderSetsOfOtherExercises() {
        let target = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let other = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession()
        let otherA = SetEntry(order: 0, setType: .normal, reps: 5, weight: 100, exercise: other, session: session)
        let otherB = SetEntry(order: 1, setType: .normal, reps: 5, weight: 100, exercise: other, session: session)
        let targetWorking = SetEntry(order: 2, setType: .normal, reps: 8, weight: 60, exercise: target, session: session)
        let warmup = SetEntry(setType: .warmup, reps: 10, weight: 30, exercise: target, session: session)

        let result = WarmupSetInsertion.insert(warmup, into: [otherA, otherB, targetWorking], forExerciseID: target.id)

        let otherIndices = result.enumerated().filter { $0.element === otherA || $0.element === otherB }.map(\.offset)
        XCTAssertEqual(otherIndices, otherIndices.sorted(), "otherA must still come before otherB")
        XCTAssertEqual(result.filter { $0.exercise?.id == other.id }, [otherA, otherB])
    }

    /// The exact regression the ticket calls out: inserting a warmup (and reindexing the
    /// resulting order) must never change any other set's weight, reps, note, or completion —
    /// only `.order` may change.
    func testInsertingAndReindexingNeverMutatesSiblingSetProperties() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession()
        let working = SetEntry(order: 0, setType: .normal, reps: 8, weight: 60, isCompleted: true, note: "wichtig", exercise: exercise, session: session)
        let warmup = SetEntry(setType: .warmup, reps: 10, weight: 30, exercise: exercise, session: session)

        let result = WarmupSetInsertion.insert(warmup, into: [working], forExerciseID: exercise.id)
        SetEntryOrdering.reindex(result)

        XCTAssertEqual(working.reps, 8)
        XCTAssertEqual(working.weight, 60)
        XCTAssertTrue(working.isCompleted)
        XCTAssertEqual(working.note, "wichtig")
        // Order did legitimately change (warmup now precedes it) — that's the whole point.
        XCTAssertEqual(working.order, 1)
        XCTAssertEqual(warmup.order, 0)
    }
}
