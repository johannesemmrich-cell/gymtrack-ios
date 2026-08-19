import XCTest
@testable import GymTrack

final class WorkoutSessionBuilderTests: XCTestCase {

    func testEmptyPlanProducesSessionWithNoSets() {
        let plan = TrainingPlan(name: "Leerer Plan")
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertTrue(result.sets.isEmpty)
        XCTAssertEqual(result.session.planName, "Leerer Plan")
    }

    func testCreatesTargetSetsCountPerExercise() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 4, targetReps: 8, plan: plan, exercise: exercise)
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertEqual(result.sets.count, 4)
        XCTAssertTrue(result.sets.allSatisfy { $0.setType == .normal && $0.isCompleted == false })
    }

    func testUsesSetSuggestionWhenHistoryExists() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 2, targetReps: 10, targetWeight: 40, plan: plan, exercise: exercise)
        let pastSession = WorkoutSession(startedAt: .now)
        let history = [
            SetEntry(reps: 6, weight: 70, isCompleted: true, exercise: exercise, gym: gym, session: pastSession)
        ]
        let result = WorkoutSessionBuilder.build(from: plan, gym: gym, setHistory: history)
        // History wins over the plan's own target as the *ghost hint* — but the real fields
        // must stay empty regardless, so the set doesn't look already-completed.
        XCTAssertTrue(result.sets.allSatisfy { $0.suggestedWeight == 70 && $0.suggestedReps == 6 })
        XCTAssertTrue(result.sets.allSatisfy { $0.weight == 0 && $0.reps == 0 })
    }

    func testFallsBackToPlanExerciseTargetsWhenNoHistory() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 1, targetReps: 12, targetWeight: 45, plan: plan, exercise: exercise)
        let result = WorkoutSessionBuilder.build(from: plan, gym: gym, setHistory: [])
        XCTAssertEqual(result.sets.first?.suggestedWeight, 45)
        XCTAssertEqual(result.sets.first?.suggestedReps, 12)
        XCTAssertEqual(result.sets.first?.weight, 0)
        XCTAssertEqual(result.sets.first?.reps, 0)
    }

    func testFallsBackToZeroWeightWhenNoHistoryAndNoTargetWeight() {
        let exercise = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let plan = TrainingPlan(name: "Pull")
        _ = PlanExercise(order: 0, targetSets: 1, targetReps: 10, targetWeight: nil, plan: plan, exercise: exercise)
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertEqual(result.sets.first?.weight, 0)
        // No history and no plan target weight means there's genuinely nothing to hint at.
        XCTAssertNil(result.sets.first?.suggestedWeight)
    }

    func testNormalSetsAlwaysStartWithZeroRealWeightAndReps() {
        // Regression guard for the ghost-value mechanic's core invariant: a freshly-built set
        // must never carry a real (non-ghost) weight/reps value, no matter how strong the
        // suggestion is — otherwise it would immediately read as "erledigt" once the
        // weight-and-reps-present auto-completion rule is applied to it.
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 3, targetReps: 10, targetWeight: 80, plan: plan, exercise: exercise)
        let pastSession = WorkoutSession(startedAt: .now)
        let history = [
            SetEntry(reps: 8, weight: 90, isCompleted: true, exercise: exercise, gym: gym, session: pastSession)
        ]
        let result = WorkoutSessionBuilder.build(from: plan, gym: gym, setHistory: history)
        XCTAssertTrue(result.sets.allSatisfy { $0.weight == 0 && $0.reps == 0 && !$0.isCompleted })
    }

    func testSkipsPlanExerciseWithNilExerciseReference() {
        let plan = TrainingPlan(name: "Kaputter Plan")
        _ = PlanExercise(order: 0, targetSets: 3, plan: plan, exercise: nil)
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertTrue(result.sets.isEmpty)
    }

    func testOrderIsContinuousAcrossExercises() {
        let a = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let b = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let plan = TrainingPlan(name: "Ganzkörper")
        _ = PlanExercise(order: 0, targetSets: 2, plan: plan, exercise: a)
        _ = PlanExercise(order: 1, targetSets: 2, plan: plan, exercise: b)
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertEqual(result.sets.map(\.order), [0, 1, 2, 3])
    }

    func testSessionCarriesPlanNameAndGym() {
        let gym = Gym(name: "Frankfurt")
        let plan = TrainingPlan(name: "Push")
        let result = WorkoutSessionBuilder.build(from: plan, gym: gym, setHistory: [])
        XCTAssertEqual(result.session.planName, "Push")
        XCTAssertEqual(result.session.gym?.name, "Frankfurt")
        XCTAssertNil(result.session.endedAt)
    }

    func testNoGymSkipsSuggestionAndUsesPlanDefaults() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 1, targetReps: 10, targetWeight: 20, plan: plan, exercise: exercise)
        // History exists, but for a gym-less start we must not use it (no gym to match against).
        let pastSession = WorkoutSession(startedAt: .now)
        let history = [
            SetEntry(reps: 6, weight: 70, isCompleted: true, exercise: exercise, gym: gym, session: pastSession)
        ]
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: history)
        XCTAssertEqual(result.sets.first?.suggestedWeight, 20)
        XCTAssertEqual(result.sets.first?.suggestedReps, 10)
        XCTAssertEqual(result.sets.first?.weight, 0)
        XCTAssertEqual(result.sets.first?.reps, 0)
    }

    func testEachCreatedSetIsExplicitlyLinkedToTheSession() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 2, plan: plan, exercise: exercise)
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertTrue(result.sets.allSatisfy { $0.session === result.session })
    }

    func testSetsInheritTheirPlanExercisesSupersetGroupID() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let row = Exercise(name: "Rudern vorgebeugt", muscleGroup: .back)
        let plan = TrainingPlan(name: "Push/Pull")
        let benchPlanExercise = PlanExercise(order: 0, targetSets: 1, plan: plan, exercise: bench)
        let rowPlanExercise = PlanExercise(order: 1, targetSets: 1, plan: plan, exercise: row)
        SupersetGrouping.group([benchPlanExercise, rowPlanExercise], allPlanExercises: [benchPlanExercise, rowPlanExercise])

        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])

        let groupID = benchPlanExercise.supersetGroupID
        XCTAssertNotNil(groupID)
        XCTAssertTrue(result.sets.allSatisfy { $0.supersetGroupID == groupID })
    }

    func testSetsFromAStandaloneExerciseHaveNoSupersetGroupID() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 1, plan: plan, exercise: exercise)

        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])

        XCTAssertTrue(result.sets.allSatisfy { $0.supersetGroupID == nil })
    }

    func testNonUnilateralExerciseSetsHaveNoSide() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 3, isUnilateral: false, plan: plan, exercise: exercise)

        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])

        XCTAssertTrue(result.sets.allSatisfy { $0.side == nil })
    }

    func testUnilateralExerciseCreatesTwiceTargetSetsAlternatingLeftAndRight() {
        // "3 sets per arm" means targetSets is per side, not total — 3 must become 6 sets.
        let exercise = Exercise(name: "Bizeps-Curl einarmig", muscleGroup: .biceps)
        let plan = TrainingPlan(name: "Arme")
        _ = PlanExercise(order: 0, targetSets: 3, isUnilateral: true, plan: plan, exercise: exercise)

        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])

        XCTAssertEqual(result.sets.count, 6)
        // Alternating L/R per set number, not all-left-then-all-right — matches training a
        // working set on one side immediately followed by the same set on the other side.
        XCTAssertEqual(result.sets.map(\.side), [.left, .right, .left, .right, .left, .right])
    }

    func testUnilateralExerciseBothSidesShareTheSameSuggestion() {
        // Deliberately not side-specific for now — both sides get the same ghost hint.
        let exercise = Exercise(name: "Kurzhantel-Rudern einarmig", muscleGroup: .back)
        let plan = TrainingPlan(name: "Rücken")
        _ = PlanExercise(order: 0, targetSets: 2, targetReps: 12, targetWeight: 16, isUnilateral: true, plan: plan, exercise: exercise)

        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])

        XCTAssertTrue(result.sets.allSatisfy { $0.suggestedWeight == 16 && $0.suggestedReps == 12 })
    }
}
