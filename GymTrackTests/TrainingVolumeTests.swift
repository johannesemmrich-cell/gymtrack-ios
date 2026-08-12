import XCTest
@testable import GymTrack

final class TrainingVolumeTests: XCTestCase {

    func testNoSessionsProducesEmptyResult() {
        XCTAssertTrue(TrainingVolume.dataPoints(sessions: [], exercise: nil).isEmpty)
    }

    func testOverallVolumeSumsAllCompletedSetsInASession() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squat = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: bench, session: session) // 480
        _ = SetEntry(reps: 5, weight: 100, isCompleted: true, exercise: squat, session: session) // 500

        let result = TrainingVolume.dataPoints(sessions: [session], exercise: nil)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].volume, 980)
    }

    func testPerExerciseVolumeOnlySumsThatExercisesSets() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squat = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: bench, session: session)
        _ = SetEntry(reps: 5, weight: 100, isCompleted: true, exercise: squat, session: session)

        let result = TrainingVolume.dataPoints(sessions: [session], exercise: bench)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].volume, 480)
    }

    func testIncompleteSetsAreExcludedFromVolume() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: bench, session: session)

        XCTAssertTrue(TrainingVolume.dataPoints(sessions: [session], exercise: nil).isEmpty)
    }

    func testSessionsWithNoRelevantVolumeProduceNoDataPoint() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squat = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: squat, session: session)

        // Filtering for bench, which wasn't done this session, must not produce a zero point.
        XCTAssertTrue(TrainingVolume.dataPoints(sessions: [session], exercise: bench).isEmpty)
    }

    func testIneligibleSessionsAreExcluded() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let stillActive = WorkoutSession(startedAt: .now, endedAt: nil)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: bench, session: stillActive)

        XCTAssertTrue(TrainingVolume.dataPoints(sessions: [stillActive], exercise: nil).isEmpty)
    }

    func testResultsAreSortedChronologically() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let base = Date(timeIntervalSince1970: 0)
        let later = WorkoutSession(startedAt: base.addingTimeInterval(1000), endedAt: base.addingTimeInterval(2000))
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: bench, session: later)
        let earlier = WorkoutSession(startedAt: base, endedAt: base.addingTimeInterval(500))
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: bench, session: earlier)

        let result = TrainingVolume.dataPoints(sessions: [later, earlier], exercise: nil)

        XCTAssertEqual(result.map(\.date), [earlier.startedAt, later.startedAt])
    }

    func testCompletedSetWithZeroWeightStillProducesARealDataPoint() {
        // Regression: a session with a genuine isCompleted set logged at weight 0 (forgotten
        // input, or a bodyweight-style exercise) must still show up on the chart as volume 0,
        // not be silently dropped as if the session had no relevant data at all.
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 0, isCompleted: true, exercise: bench, session: session)

        let result = TrainingVolume.dataPoints(sessions: [session], exercise: nil)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].volume, 0)
    }

    func testExercisesWithVolumeHistoryListsDistinctExercisesWithAtLeastOneDataPoint() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squat = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let untouched = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: bench, session: session)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: squat, session: session)

        let result = TrainingVolume.exercisesWithVolumeHistory(sessions: [session])

        XCTAssertEqual(result.map(\.name), ["Bankdrücken"])
        XCTAssertFalse(result.contains { $0.id == untouched.id })
    }
}
