import XCTest
@testable import GymTrack

final class TrainingPlanDuplicationTests: XCTestCase {

    func testCopyNameGetsKopieSuffix() {
        let plan = TrainingPlan(name: "Push Day")
        let result = TrainingPlanDuplication.duplicate(plan)
        XCTAssertEqual(result.plan.name, "Push Day (Kopie)")
    }

    func testCopyPreservesNote() {
        let plan = TrainingPlan(name: "Push Day", note: "Montags")
        let result = TrainingPlanDuplication.duplicate(plan)
        XCTAssertEqual(result.plan.note, "Montags")
    }

    func testEmptyPlanProducesEmptyCopy() {
        let plan = TrainingPlan(name: "Leer")
        let result = TrainingPlanDuplication.duplicate(plan)
        XCTAssertTrue(result.planExercises.isEmpty)
    }

    func testCopiesEachPlanExerciseWithSameTargetsAndSameExerciseReference() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push Day")
        _ = PlanExercise(order: 0, targetSets: 4, targetReps: 8, targetWeight: 60, note: "eng", plan: plan, exercise: exercise)

        let result = TrainingPlanDuplication.duplicate(plan)

        XCTAssertEqual(result.planExercises.count, 1)
        let copy = result.planExercises[0]
        XCTAssertEqual(copy.targetSets, 4)
        XCTAssertEqual(copy.targetReps, 8)
        XCTAssertEqual(copy.targetWeight, 60)
        XCTAssertEqual(copy.note, "eng")
        XCTAssertTrue(copy.exercise === exercise, "Copy must reference the same Exercise, not a duplicate")
    }

    func testCopiedPlanExercisesPointToTheNewPlanNotTheOriginal() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push Day")
        _ = PlanExercise(order: 0, plan: plan, exercise: exercise)

        let result = TrainingPlanDuplication.duplicate(plan)

        XCTAssertTrue(result.planExercises[0].plan === result.plan)
        XCTAssertFalse(result.planExercises[0].plan === plan)
    }

    func testPreservesRelativeOrder() {
        let a = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let b = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let plan = TrainingPlan(name: "Ganzkörper")
        _ = PlanExercise(order: 1, plan: plan, exercise: b)
        _ = PlanExercise(order: 0, plan: plan, exercise: a)

        let result = TrainingPlanDuplication.duplicate(plan)

        XCTAssertEqual(result.planExercises.map(\.order), [0, 1])
        XCTAssertEqual(result.planExercises.map { $0.exercise?.name }, ["Bankdrücken", "Kniebeugen"])
    }

    func testDoesNotMutateTheOriginalPlanOrItsExercises() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push Day")
        let original = PlanExercise(order: 0, targetSets: 3, plan: plan, exercise: exercise)

        _ = TrainingPlanDuplication.duplicate(plan)

        XCTAssertEqual(plan.name, "Push Day")
        XCTAssertEqual(plan.exercises?.count, 1)
        XCTAssertEqual(original.targetSets, 3)
        XCTAssertTrue(original.plan === plan)
    }

    /// The regression the review pass found: duplicating is not tuning, so a copied
    /// PlanExercise must inherit the source's updatedAt, not get a fresh `.now`. Otherwise a
    /// duplicate could silently outrank a genuinely more-recently-tuned entry for the same
    /// exercise in PlanExerciseDefaults.suggest's "most recent" lookup across plans.
    func testCopiedPlanExerciseInheritsSourceUpdatedAtRatherThanGettingAFreshTimestamp() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push Day")
        let staleTimestamp = Date(timeIntervalSince1970: 1000)
        let source = PlanExercise(order: 0, targetSets: 4, targetReps: 8, targetWeight: 60, updatedAt: staleTimestamp, plan: plan, exercise: exercise)

        let result = TrainingPlanDuplication.duplicate(plan)

        XCTAssertEqual(result.planExercises[0].updatedAt, staleTimestamp)
        XCTAssertEqual(source.updatedAt, staleTimestamp, "duplicating must not touch the source either")
    }

    func testHandlesPlanExerciseWithNilExerciseGracefully() {
        let plan = TrainingPlan(name: "Kaputter Plan")
        _ = PlanExercise(order: 0, targetSets: 3, plan: plan, exercise: nil)

        let result = TrainingPlanDuplication.duplicate(plan)

        XCTAssertEqual(result.planExercises.count, 1)
        XCTAssertNil(result.planExercises[0].exercise)
    }
}
