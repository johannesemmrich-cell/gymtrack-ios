import XCTest
@testable import GymTrack

final class WorkoutCompletionTests: XCTestCase {

    func testEmptySessionHasNoIncompleteSets() {
        let session = WorkoutSession()
        XCTAssertTrue(WorkoutCompletion.incompleteSets(in: session).isEmpty)
    }

    func testAllCompletedSetsReturnsEmpty() {
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: session)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: session)
        // WorkoutSession.sets is populated automatically by SwiftData's inverse relationship
        // once each SetEntry's `session` is set — verified by ModelTests already.
        XCTAssertTrue(WorkoutCompletion.incompleteSets(in: session).isEmpty)
    }

    func testReturnsOnlyIncompleteSets() {
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let done = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: session)
        let notDone = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: exercise, session: session)
        let incomplete = WorkoutCompletion.incompleteSets(in: session)
        XCTAssertEqual(incomplete.count, 1)
        XCTAssertTrue(incomplete.contains { $0 === notDone })
        XCTAssertFalse(incomplete.contains { $0 === done })
    }

    func testAllIncompleteSetsAreAllReturned() {
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: exercise, session: session)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: exercise, session: session)
        XCTAssertEqual(WorkoutCompletion.incompleteSets(in: session).count, 2)
    }
}
