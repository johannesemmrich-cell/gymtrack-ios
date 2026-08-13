import XCTest
@testable import GymTrack

final class PlanTemplateApplicationTests: XCTestCase {

    private let template = PlanTemplate(id: "test", name: "Testplan", exercises: [
        .init(exerciseName: "Bankdrücken", targetSets: 4, targetReps: 8),
        .init(exerciseName: "Klimmzüge", targetSets: 3, targetReps: 10),
        .init(exerciseName: "Kniebeugen", targetSets: 5, targetReps: 5)
    ])

    func testMakePlanUsesTheTemplateName() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench])
        XCTAssertEqual(result.plan.name, "Testplan")
    }

    func testMakePlanCreatesOnePlanExercisePerMatchedTemplateEntry() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let pullups = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)

        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench, pullups, squats])

        XCTAssertEqual(result.planExercises.count, 3)
        XCTAssertEqual(Set(result.planExercises.compactMap { $0.exercise?.name }), ["Bankdrücken", "Klimmzüge", "Kniebeugen"])
    }

    func testMakePlanCopiesTargetSetsAndRepsFromTheTemplateEntry() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench])

        let benchPlanExercise = result.planExercises.first { $0.exercise?.name == "Bankdrücken" }
        XCTAssertEqual(benchPlanExercise?.targetSets, 4)
        XCTAssertEqual(benchPlanExercise?.targetReps, 8)
    }

    func testMakePlanAssignsContiguousOrderStartingAtZero() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let pullups = Exercise(name: "Klimmzüge", muscleGroup: .back)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)

        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench, pullups, squats])

        XCTAssertEqual(result.planExercises.map(\.order).sorted(), [0, 1, 2])
    }

    func testMakePlanSkipsEntriesWithNoMatchingExerciseWithoutCrashing() {
        // Only Bankdrücken exists in the library — Klimmzüge/Kniebeugen were renamed/deleted.
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench])

        XCTAssertEqual(result.planExercises.count, 1)
        XCTAssertEqual(result.planExercises[0].exercise?.name, "Bankdrücken")
    }

    func testMakePlanSkippedEntriesLeaveOrderContiguousWithoutGaps() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        // Klimmzüge (the middle template entry) has no match here.
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench, squats])

        XCTAssertEqual(result.planExercises.map(\.order).sorted(), [0, 1])
    }

    func testMakePlanWithNoMatchingExercisesAtAllCreatesAnEmptyPlanWithoutCrashing() {
        let unrelated = Exercise(name: "Wadenheben", muscleGroup: .calves)
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [unrelated])

        XCTAssertEqual(result.plan.name, "Testplan")
        XCTAssertTrue(result.planExercises.isEmpty)
    }

    func testMakePlanWithEmptyExerciseLibraryCreatesAnEmptyPlanWithoutCrashing() {
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [])
        XCTAssertTrue(result.planExercises.isEmpty)
    }

    func testEachCreatedPlanExerciseReferencesTheNewPlan() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: [bench])
        XCTAssertTrue(result.planExercises[0].plan === result.plan)
    }

    // MARK: PlanTemplateLibrary consistency — templates only ever reference exercises that
    // actually exist in the seeded default library, otherwise a fresh install would silently
    // apply near-empty templates.

    func testAllBundledTemplateExercisesExistInTheDefaultSeedList() {
        let defaultNames = Set(ExerciseSeeder.defaultExercises.map(\.name))
        for template in PlanTemplateLibrary.all {
            for entry in template.exercises {
                XCTAssertTrue(
                    defaultNames.contains(entry.exerciseName),
                    "Template '\(template.name)' references '\(entry.exerciseName)', which is not in ExerciseSeeder.defaultExercises"
                )
            }
        }
    }

    func testEveryBundledTemplateHasAtLeastOneExercise() {
        for template in PlanTemplateLibrary.all {
            XCTAssertFalse(template.exercises.isEmpty, "Template '\(template.name)' has no exercises")
        }
    }
}
