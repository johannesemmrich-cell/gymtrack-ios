import XCTest
@testable import GymTrack

final class GoalMetricProgressTests: XCTestCase {

    func testFractionWithNoCurrentIsZero() {
        let progress = GoalMetricProgress(target: 100, current: nil)
        XCTAssertEqual(progress.fraction, 0)
    }

    func testFractionIsExactRatioWhenBelowTarget() {
        let progress = GoalMetricProgress(target: 100, current: 60)
        XCTAssertEqual(progress.fraction, 0.6)
    }

    func testFractionIsClampedToOneWhenCurrentExceedsTarget() {
        let progress = GoalMetricProgress(target: 100, current: 150)
        XCTAssertEqual(progress.fraction, 1)
    }

    func testFractionWithNonPositiveTargetIsZeroEvenWithCurrent() {
        XCTAssertEqual(GoalMetricProgress(target: 0, current: 50).fraction, 0)
        XCTAssertEqual(GoalMetricProgress(target: -10, current: 50).fraction, 0)
    }

    func testRemainingWithNoCurrentEqualsFullTarget() {
        let progress = GoalMetricProgress(target: 100, current: nil)
        XCTAssertEqual(progress.remaining, 100)
    }

    func testRemainingIsPositiveDifferenceWhenBelowTarget() {
        let progress = GoalMetricProgress(target: 100, current: 60)
        XCTAssertEqual(progress.remaining, 40)
    }

    func testRemainingIsZeroWhenAlreadyAtOrAboveTarget() {
        XCTAssertEqual(GoalMetricProgress(target: 100, current: 100).remaining, 0)
        XCTAssertEqual(GoalMetricProgress(target: 100, current: 150).remaining, 0)
    }

    func testIsAchievedFalseWithNoCurrent() {
        XCTAssertFalse(GoalMetricProgress(target: 100, current: nil).isAchieved)
    }

    func testIsAchievedFalseWhenBelowTarget() {
        XCTAssertFalse(GoalMetricProgress(target: 100, current: 99).isAchieved)
    }

    func testIsAchievedTrueWhenCurrentEqualsTarget() {
        XCTAssertTrue(GoalMetricProgress(target: 100, current: 100).isAchieved)
    }

    func testIsAchievedTrueWhenCurrentExceedsTarget() {
        XCTAssertTrue(GoalMetricProgress(target: 100, current: 150).isAchieved)
    }
}

final class GoalProgressTests: XCTestCase {

    func testWeightProgressWithNoSessionsHasNoCurrent() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let progress = GoalProgress.weightProgress(for: bench, in: [], target: 100)
        XCTAssertNil(progress.current)
        XCTAssertEqual(progress.target, 100)
    }

    func testWeightProgressPicksHighestCompletedNormalSetWeight() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session1 = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 60, isCompleted: true, exercise: bench, session: session1)
        let session2 = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 3, weight: 80, isCompleted: true, exercise: bench, session: session2)

        let progress = GoalProgress.weightProgress(for: bench, in: [session1, session2], target: 100)
        XCTAssertEqual(progress.current, 80)
    }

    func testWeightProgressExcludesWarmupSets() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(setType: .warmup, reps: 5, weight: 500, isCompleted: true, exercise: bench, session: session)

        let progress = GoalProgress.weightProgress(for: bench, in: [session], target: 100)
        XCTAssertNil(progress.current)
    }

    func testWeightProgressExcludesDropsets() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(setType: .dropset, reps: 5, weight: 500, isCompleted: true, exercise: bench, session: session)

        let progress = GoalProgress.weightProgress(for: bench, in: [session], target: 100)
        XCTAssertNil(progress.current)
    }

    func testWeightProgressExcludesIncompleteSets() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 200, isCompleted: false, exercise: bench, session: session)

        let progress = GoalProgress.weightProgress(for: bench, in: [session], target: 100)
        XCTAssertNil(progress.current)
    }

    func testWeightProgressExcludesSessionsThatHaveNotEnded() {
        // A currently active workout's provisional sets shouldn't count yet — matches
        // `SessionStatistics.eligibleSessions`, which every other statistic already relies on.
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let session = WorkoutSession(startedAt: .now, endedAt: nil)
        _ = SetEntry(reps: 5, weight: 200, isCompleted: true, exercise: bench, session: session)

        let progress = GoalProgress.weightProgress(for: bench, in: [session], target: 100)
        XCTAssertNil(progress.current)
    }

    func testWeightProgressExcludesOtherExercises() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 5, weight: 200, isCompleted: true, exercise: squats, session: session)

        let progress = GoalProgress.weightProgress(for: bench, in: [session], target: 100)
        XCTAssertNil(progress.current)
    }

    func testRepsProgressPicksHighestCompletedNormalSetReps() {
        let pullups = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let session1 = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 8, weight: 0, isCompleted: true, exercise: pullups, session: session1)
        let session2 = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 12, weight: 0, isCompleted: true, exercise: pullups, session: session2)

        let progress = GoalProgress.repsProgress(for: pullups, in: [session1, session2], target: 15)
        XCTAssertEqual(progress.current, 12)
        XCTAssertEqual(progress.target, 15)
    }

    func testRepsProgressExcludesWarmupAndIncompleteSets() {
        let pullups = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(setType: .warmup, reps: 20, weight: 0, isCompleted: true, exercise: pullups, session: session)
        _ = SetEntry(reps: 20, weight: 0, isCompleted: false, exercise: pullups, session: session)

        let progress = GoalProgress.repsProgress(for: pullups, in: [session], target: 15)
        XCTAssertNil(progress.current)
    }

    /// A logged bodyweight set (0 kg) must read as a genuine "current: 0", not be confused with
    /// "no history at all" — the exact nil-vs-zero distinction that caused the ghost-value
    /// autofill bug in the immediately preceding ticket.
    func testWeightProgressDistinguishesGenuineZeroFromNoHistory() {
        let pullups = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        _ = SetEntry(reps: 12, weight: 0, isCompleted: true, exercise: pullups, session: session)

        let progress = GoalProgress.weightProgress(for: pullups, in: [session], target: 100)
        XCTAssertEqual(progress.current, 0)
        XCTAssertNotNil(progress.current)
    }
}
