import XCTest
@testable import GymTrack

final class PersonalRecordFinderTests: XCTestCase {

    func testNoSessionsProducesEmptyResult() {
        XCTAssertTrue(PersonalRecordFinder.bestPerExercise(from: [], exerciseGymNotes: []).isEmpty)
    }

    func testPicksTheSetWithTheHighestEstimatedOneRepMaxAcrossSessions() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session1 = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, session: session1) // 1RM ~70

        let session2 = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 3, weight: 80, isCompleted: true, exercise: bench, session: session2) // 1RM ~88

        let result = PersonalRecordFinder.bestPerExercise(from: [session1, session2], exerciseGymNotes: [])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].exercise.id, bench.id)
        XCTAssertEqual(result[0].weight, 80)
        XCTAssertEqual(result[0].reps, 3)
    }

    func testOnAnExactTieThePickedRecordPrefersTheMoreRecentSession() {
        // Deterministic by date, not by array/iteration order — a tie shouldn't flip which
        // date/gym gets shown depending on unspecified SwiftData fetch ordering.
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let base = Date(timeIntervalSince1970: 0)
        let olderGym = Gym(name: "Alt")
        let newerGym = Gym(name: "Neu")

        let olderSession = WorkoutSession(startedAt: base, endedAt: base, gym: olderGym)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, gym: olderGym, session: olderSession)

        let newerSession = WorkoutSession(startedAt: base.addingTimeInterval(1000), endedAt: base.addingTimeInterval(1000), gym: newerGym)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, gym: newerGym, session: newerSession)

        // Feed the older session second, to confirm the result isn't just "whichever came last
        // in the input array" — it must specifically be the more recent one by date.
        let result = PersonalRecordFinder.bestPerExercise(from: [newerSession, olderSession], exerciseGymNotes: [])

        XCTAssertEqual(result[0].gym?.name, "Neu")
    }

    func testIncompleteSetsAreExcluded() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 200, isCompleted: false, exercise: bench, session: session)

        XCTAssertTrue(PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: []).isEmpty)
    }

    func testWarmupSetsAreExcludedEvenIfTheyHaveTheHighestRawWeight() {
        // A warmup isn't a genuine max-effort attempt, so it must never win a PR — matches
        // SetSuggestion's existing convention of ignoring warmup/dropset sets.
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(setType: .warmup, reps: 5, weight: 500, isCompleted: true, exercise: bench, session: session)
        _ = SetEntry(setType: .normal, reps: 5, weight: 60, isCompleted: true, exercise: bench, session: session)

        let result = PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: [])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].weight, 60)
    }

    func testDropsetsAreExcludedEvenIfTheyHaveTheHighestRawWeight() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(setType: .dropset, reps: 5, weight: 500, isCompleted: true, exercise: bench, session: session)
        _ = SetEntry(setType: .normal, reps: 5, weight: 60, isCompleted: true, exercise: bench, session: session)

        let result = PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: [])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].weight, 60)
    }

    func testIneligibleSessionsAreExcluded() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let stillActive = WorkoutSession(startedAt: .now, endedAt: nil)
        _ = SetEntry(reps: 5, weight: 200, isCompleted: true, exercise: bench, session: stillActive)

        XCTAssertTrue(PersonalRecordFinder.bestPerExercise(from: [stillActive], exerciseGymNotes: []).isEmpty)
    }

    func testSetsWithNilExerciseReferenceAreSkippedWithoutCrashing() {
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 100, isCompleted: true, exercise: nil, session: session)

        XCTAssertTrue(PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: []).isEmpty)
    }

    func testMultipleExercisesEachGetTheirOwnRecord() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squat = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, session: session)
        _ = SetEntry(reps: 5, weight: 100, isCompleted: true, exercise: squat, session: session)

        let result = PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: [])

        XCTAssertEqual(Set(result.map { $0.exercise.name }), ["Bankdrücken", "Kniebeugen"])
    }

    func testResultsAreSortedAlphabeticallyByExerciseName() {
        let squat = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: squat, session: session)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, session: session)

        let result = PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: [])

        XCTAssertEqual(result.map { $0.exercise.name }, ["Bankdrücken", "Kniebeugen"])
    }

    // MARK: cross-gym comparability via GymConversion

    func testGymWithAHeavierCalibrationFactorCanWinOverARawHeavierWeightElsewhere() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        // Gym A's equipment is calibrated 50% harder — its 60kg is worth more than a raw 100kg
        // at the (uncalibrated, factor 1.0) reference.
        let gymA = Gym(name: "A", weightConversionFactor: 1.5)
        let gymB = Gym(name: "B", weightConversionFactor: 1.0)

        let session1 = WorkoutSession(startedAt: .now, endedAt: .now, gym: gymA)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, gym: gymA, session: session1)

        let session2 = WorkoutSession(startedAt: .now, endedAt: .now, gym: gymB)
        _ = SetEntry(reps: 5, weight: 80, isCompleted: true, exercise: bench, gym: gymB, session: session2)

        let result = PersonalRecordFinder.bestPerExercise(from: [session1, session2], exerciseGymNotes: [])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].gym?.name, "A", "The gym-converted 1RM from Gym A (90kg-equivalent) should beat Gym B's raw 80kg")
    }

    func testGymWithNoConversionFactorSetDefaultsToNoConversion() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let session = WorkoutSession(startedAt: .now, endedAt: .now, gym: gym)
        _ = SetEntry(reps: 1, weight: 100, isCompleted: true, exercise: bench, gym: gym, session: session)

        let result = PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: [])

        XCTAssertEqual(result[0].estimatedOneRepMax, 100)
    }

    func testPerExerciseConversionOverrideTakesPrecedenceOverTheGymsGlobalFactor() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt", weightConversionFactor: 1.0)
        let session = WorkoutSession(startedAt: .now, endedAt: .now, gym: gym)
        _ = SetEntry(reps: 1, weight: 100, isCompleted: true, exercise: bench, gym: gym, session: session)

        // This specific exercise is overridden to a 2.0 factor at this gym, even though the
        // gym's own global factor is 1.0.
        let note = ExerciseGymNote(conversionFactor: 2.0, exercise: bench, gym: gym)

        let result = PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: [note])

        XCTAssertEqual(result[0].estimatedOneRepMax, 200)
    }

    func testSetWithNoRelevantOneRepMaxIsExcludedRatherThanShowingAZeroRecord() {
        // 0 reps produces an undefined (0) estimated 1RM — must not appear as a spurious record.
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 0, weight: 100, isCompleted: true, exercise: bench, session: session)

        XCTAssertTrue(PersonalRecordFinder.bestPerExercise(from: [session], exerciseGymNotes: []).isEmpty)
    }
}
