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
        XCTAssertTrue(result.sets.allSatisfy { $0.weight == 70 && $0.reps == 6 })
    }

    func testFallsBackToPlanExerciseTargetsWhenNoHistory() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let plan = TrainingPlan(name: "Push")
        _ = PlanExercise(order: 0, targetSets: 1, targetReps: 12, targetWeight: 45, plan: plan, exercise: exercise)
        let result = WorkoutSessionBuilder.build(from: plan, gym: gym, setHistory: [])
        XCTAssertEqual(result.sets.first?.weight, 45)
        XCTAssertEqual(result.sets.first?.reps, 12)
    }

    func testFallsBackToZeroWeightWhenNoHistoryAndNoTargetWeight() {
        let exercise = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let plan = TrainingPlan(name: "Pull")
        _ = PlanExercise(order: 0, targetSets: 1, targetReps: 10, targetWeight: nil, plan: plan, exercise: exercise)
        let result = WorkoutSessionBuilder.build(from: plan, gym: nil, setHistory: [])
        XCTAssertEqual(result.sets.first?.weight, 0)
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
        XCTAssertEqual(result.sets.first?.weight, 20)
        XCTAssertEqual(result.sets.first?.reps, 10)
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
}
