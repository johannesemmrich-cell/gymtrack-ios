import XCTest
@testable import GymTrack

final class ExerciseFrequencyTests: XCTestCase {

    func testNoSessionsProducesEmptyResult() {
        XCTAssertTrue(ExerciseFrequency.mostFrequentExercises(from: []).isEmpty)
    }

    func testMultipleSetsOfSameExerciseInOneSessionCountOnce() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: session)
        _ = SetEntry(order: 1, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: session)

        let result = ExerciseFrequency.mostFrequentExercises(from: [session])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].sessionCount, 1)
    }

    func testSameExerciseAcrossMultipleSessionsSumsSessionCount() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let a = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: a)
        let b = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: b)

        let result = ExerciseFrequency.mostFrequentExercises(from: [a, b])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].sessionCount, 2)
    }

    func testIncompleteSetsDoNotCountTowardsTheirExercise() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let other = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: exercise, session: session)
        // Session is eligible only because of this OTHER exercise's completed set.
        _ = SetEntry(reps: 5, weight: 100, isCompleted: true, exercise: other, session: session)

        let result = ExerciseFrequency.mostFrequentExercises(from: [session])

        XCTAssertEqual(result.map(\.exercise.name), ["Kniebeugen"])
    }

    func testIneligibleSessionsAreExcludedEntirely() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let stillActive = WorkoutSession(startedAt: .now, endedAt: nil)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: stillActive)

        XCTAssertTrue(ExerciseFrequency.mostFrequentExercises(from: [stillActive]).isEmpty)
    }

    func testSortedDescendingByCount() {
        let frequent = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let rare = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let a = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: frequent, session: a)
        let b = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: frequent, session: b)
        _ = SetEntry(reps: 5, weight: 100, isCompleted: true, exercise: rare, session: b)

        let result = ExerciseFrequency.mostFrequentExercises(from: [a, b])

        XCTAssertEqual(result.map(\.exercise.name), ["Bankdrücken", "Kniebeugen"])
        XCTAssertEqual(result.map(\.sessionCount), [2, 1])
    }

    func testTiesBreakAlphabeticallyForDeterministicOrder() {
        let b = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let a = Exercise(name: "Ausfallschritte", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: b, session: session)
        _ = SetEntry(reps: 8, weight: 40, isCompleted: true, exercise: a, session: session)

        let result = ExerciseFrequency.mostFrequentExercises(from: [session])

        XCTAssertEqual(result.map(\.exercise.name), ["Ausfallschritte", "Bankdrücken"])
    }
}
