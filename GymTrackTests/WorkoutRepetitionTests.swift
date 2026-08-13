import XCTest
@testable import GymTrack

final class WorkoutRepetitionTests: XCTestCase {

    func testEmptySourceSessionProducesSessionWithNoSets() {
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        let result = WorkoutRepetition.build(repeating: source, gym: nil)
        XCTAssertTrue(result.sets.isEmpty)
    }

    func testCopiesReplicatesEachCompletedSetFromTheSourceSession() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)
        _ = SetEntry(order: 1, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertEqual(result.sets.count, 2)
        XCTAssertTrue(result.sets.allSatisfy { $0.weight == 60 && $0.reps == 8 && $0.exercise?.name == "Bankdrücken" })
    }

    func testCopiedSetsStartUncompletedRegardlessOfSourceCompletionState() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertTrue(result.sets.allSatisfy { $0.isCompleted == false })
    }

    func testIncompleteSourceSetsAreNotCopied() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)
        _ = SetEntry(order: 1, reps: 0, weight: 0, isCompleted: false, exercise: exercise, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertEqual(result.sets.count, 1)
    }

    func testPreservesSetTypeFromSourceSets() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, setType: .warmup, reps: 10, weight: 30, isCompleted: true, exercise: exercise, session: source)
        _ = SetEntry(order: 1, setType: .normal, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertEqual(result.sets.map(\.setType), [.warmup, .normal])
    }

    func testOrderIsContiguousStartingAtZeroEvenIfSourceSkipsIndices() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)
        _ = SetEntry(order: 5, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertEqual(result.sets.map(\.order), [0, 1])
    }

    func testSkipsSourceSetsWithNilExerciseReference() {
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: nil, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertTrue(result.sets.isEmpty)
    }

    func testNewSessionCarriesTheSourcesPlanName() {
        let source = WorkoutSession(startedAt: .now, endedAt: .now, planName: "Push")
        let result = WorkoutRepetition.build(repeating: source, gym: nil)
        XCTAssertEqual(result.session.planName, "Push")
    }

    func testNewSessionCarriesNoPlanNameWhenSourceHasNone() {
        // The ticket explicitly requires this to work even for a session that wasn't
        // started from a plan.
        let source = WorkoutSession(startedAt: .now, endedAt: .now, planName: nil)
        let result = WorkoutRepetition.build(repeating: source, gym: nil)
        XCTAssertNil(result.session.planName)
    }

    func testNewSessionUsesTheCurrentGymNotTheSourcesGym() {
        let originalGym = Gym(name: "Frankfurt")
        let currentGym = Gym(name: "Berlin")
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now, gym: originalGym)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, gym: originalGym, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: currentGym)

        XCTAssertEqual(result.session.gym?.name, "Berlin")
        XCTAssertTrue(result.sets.allSatisfy { $0.gym?.name == "Berlin" })
    }

    func testNewSessionStartsFreshWithNoEndDate() {
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        let result = WorkoutRepetition.build(repeating: source, gym: nil)
        XCTAssertNil(result.session.endedAt)
    }

    func testEachCreatedSetIsExplicitlyLinkedToTheNewSession() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let source = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(order: 0, reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: source)

        let result = WorkoutRepetition.build(repeating: source, gym: nil)

        XCTAssertTrue(result.sets.allSatisfy { $0.session === result.session })
    }
}
