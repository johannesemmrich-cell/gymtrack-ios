import XCTest
@testable import GymTrack

final class PlanExerciseDefaultsTests: XCTestCase {

    func testFallbackWhenNoHistoryExists() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let suggestion = PlanExerciseDefaults.suggest(for: exercise, from: [])
        XCTAssertEqual(suggestion.sets, PlanExerciseDefaults.fallbackSets)
        XCTAssertEqual(suggestion.reps, PlanExerciseDefaults.fallbackReps)
        XCTAssertNil(suggestion.weight)
    }

    func testUsesValuesFromOnlyMatchingHistoryEntry() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        let entry = PlanExercise(targetSets: 4, targetReps: 8, targetWeight: 60, plan: plan, exercise: exercise)
        let suggestion = PlanExerciseDefaults.suggest(for: exercise, from: [entry])
        XCTAssertEqual(suggestion.sets, 4)
        XCTAssertEqual(suggestion.reps, 8)
        XCTAssertEqual(suggestion.weight, 60)
    }

    func testIgnoresEntriesForADifferentExercise() {
        let target = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let other = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let plan = TrainingPlan(name: "Push")
        let entry = PlanExercise(targetSets: 5, targetReps: 5, plan: plan, exercise: other)
        let suggestion = PlanExerciseDefaults.suggest(for: target, from: [entry])
        XCTAssertEqual(suggestion.sets, PlanExerciseDefaults.fallbackSets)
        XCTAssertEqual(suggestion.reps, PlanExerciseDefaults.fallbackReps)
    }

    /// PlanExercise.updatedAt (bumped whenever THAT entry is tuned), not the parent plan's
    /// updatedAt, must drive recency — otherwise an unrelated edit to a different, newer plan
    /// would outrank the entry that was actually tuned most recently.
    func testPicksEntryWithMostRecentOwnUpdatedAtRegardlessOfPlanRecency() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let olderPlan = TrainingPlan(name: "Alt", updatedAt: Date(timeIntervalSince1970: 5000))
        let newerPlan = TrainingPlan(name: "Neu", updatedAt: Date(timeIntervalSince1970: 9000))
        let recentlyTunedEntry = PlanExercise(
            targetSets: 5, targetReps: 5, targetWeight: 80,
            updatedAt: Date(timeIntervalSince1970: 2000),
            plan: olderPlan, exercise: exercise
        )
        let staleEntryInNewerPlan = PlanExercise(
            targetSets: 3, targetReps: 12,
            updatedAt: Date(timeIntervalSince1970: 1000),
            plan: newerPlan, exercise: exercise
        )
        let suggestion = PlanExerciseDefaults.suggest(for: exercise, from: [staleEntryInNewerPlan, recentlyTunedEntry])
        XCTAssertEqual(suggestion.sets, 5)
        XCTAssertEqual(suggestion.reps, 5)
        XCTAssertEqual(suggestion.weight, 80)
    }

    func testEntryWithNoPlanIsStillConsideredByItsOwnUpdatedAt() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let older = PlanExercise(
            targetSets: 1, targetReps: 1,
            updatedAt: Date(timeIntervalSince1970: 1000),
            plan: nil, exercise: exercise
        )
        let newer = PlanExercise(
            targetSets: 4, targetReps: 6,
            updatedAt: Date(timeIntervalSince1970: 2000),
            plan: nil, exercise: exercise
        )
        let suggestion = PlanExerciseDefaults.suggest(for: exercise, from: [older, newer])
        XCTAssertEqual(suggestion.sets, 4)
        XCTAssertEqual(suggestion.reps, 6)
    }
}
