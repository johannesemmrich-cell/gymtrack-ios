import XCTest
@testable import GymTrack

final class PlanExportImportTests: XCTestCase {

    // MARK: export

    func testExportMapsPlanFieldsAndExerciseEntries() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push", note: "Montags")
        _ = PlanExercise(order: 0, targetSets: 4, targetReps: 8, targetWeight: 60, note: "Flachbank", plan: plan, exercise: bench)

        let export = PlanExportImport.export(plan)

        XCTAssertEqual(export.name, "Push")
        XCTAssertEqual(export.note, "Montags")
        XCTAssertEqual(export.exercises.count, 1)
        XCTAssertEqual(export.exercises[0].exerciseName, "Bankdrücken")
        XCTAssertEqual(export.exercises[0].targetSets, 4)
        XCTAssertEqual(export.exercises[0].targetReps, 8)
        XCTAssertEqual(export.exercises[0].targetWeight, 60)
        XCTAssertEqual(export.exercises[0].note, "Flachbank")
    }

    func testExportOfEmptyPlanProducesEmptyExercisesArray() {
        let plan = TrainingPlan(name: "Leerer Plan")
        let export = PlanExportImport.export(plan)
        XCTAssertTrue(export.exercises.isEmpty)
    }

    func testExportSkipsPlanExercisesWithNilExerciseReference() {
        let plan = TrainingPlan(name: "Kaputter Plan")
        _ = PlanExercise(order: 0, targetSets: 3, plan: plan, exercise: nil)
        let export = PlanExportImport.export(plan)
        XCTAssertTrue(export.exercises.isEmpty)
    }

    // MARK: encode / decode round trip

    func testEncodeDecodeRoundTripPreservesAllFields() throws {
        let export = PlanExport(
            name: "Push",
            note: "Montags",
            exercises: [
                PlanExport.ExerciseEntry(exerciseName: "Bankdrücken", order: 0, targetSets: 4, targetReps: 8, targetWeight: 60, note: "Flachbank"),
                PlanExport.ExerciseEntry(exerciseName: "Klimmzüge", order: 1, targetSets: 3, targetReps: 10, targetWeight: nil, note: nil)
            ]
        )

        let data = try PlanExportImport.encode(export)
        let decoded = try PlanExportImport.decode(data)

        XCTAssertEqual(decoded.name, "Push")
        XCTAssertEqual(decoded.note, "Montags")
        XCTAssertEqual(decoded.exercises.count, 2)
        XCTAssertEqual(decoded.exercises[0].exerciseName, "Bankdrücken")
        XCTAssertEqual(decoded.exercises[0].targetWeight, 60)
        XCTAssertNil(decoded.exercises[1].targetWeight)
        XCTAssertNil(decoded.exercises[1].note)
    }

    func testEncodeDecodeRoundTripPreservesEmptyPlan() throws {
        let export = PlanExport(name: "Leerer Plan", note: nil, exercises: [])
        let data = try PlanExportImport.encode(export)
        let decoded = try PlanExportImport.decode(data)
        XCTAssertEqual(decoded.name, "Leerer Plan")
        XCTAssertTrue(decoded.exercises.isEmpty)
    }

    // MARK: decode — corrupted file edge case (explicitly required by the ticket)

    func testDecodingGarbageBytesThrowsCorruptedFile() {
        let garbage = Data([0x00, 0xFF, 0x13, 0x37, 0xDE, 0xAD])
        XCTAssertThrowsError(try PlanExportImport.decode(garbage)) { error in
            XCTAssertEqual(error as? PlanImportError, .corruptedFile)
        }
    }

    func testDecodingEmptyDataThrowsCorruptedFile() {
        XCTAssertThrowsError(try PlanExportImport.decode(Data())) { error in
            XCTAssertEqual(error as? PlanImportError, .corruptedFile)
        }
    }

    func testDecodingValidJSONWithWrongShapeThrowsCorruptedFile() {
        let wrongShape = Data(#"{"foo": "bar"}"#.utf8)
        XCTAssertThrowsError(try PlanExportImport.decode(wrongShape)) { error in
            XCTAssertEqual(error as? PlanImportError, .corruptedFile)
        }
    }

    func testDecodingValidJSONOfTheWrongTypeThrowsCorruptedFile() {
        let wrongType = Data(#""just a string""#.utf8)
        XCTAssertThrowsError(try PlanExportImport.decode(wrongType)) { error in
            XCTAssertEqual(error as? PlanImportError, .corruptedFile)
        }
    }

    // MARK: makePlan

    func testMakePlanUsesExportNameAndNote() {
        let export = PlanExport(name: "Push", note: "Montags", exercises: [])
        let result = PlanExportImport.makePlan(from: export, availableExercises: [])
        XCTAssertEqual(result.plan.name, "Push")
        XCTAssertEqual(result.plan.note, "Montags")
    }

    func testMakePlanMatchesExercisesByNameAndCopiesFields() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let export = PlanExport(
            name: "Push",
            note: nil,
            exercises: [PlanExport.ExerciseEntry(exerciseName: "Bankdrücken", order: 0, targetSets: 4, targetReps: 8, targetWeight: 60, note: "Flachbank")]
        )

        let result = PlanExportImport.makePlan(from: export, availableExercises: [bench])

        XCTAssertEqual(result.planExercises.count, 1)
        XCTAssertEqual(result.planExercises[0].exercise?.name, "Bankdrücken")
        XCTAssertEqual(result.planExercises[0].targetSets, 4)
        XCTAssertEqual(result.planExercises[0].targetReps, 8)
        XCTAssertEqual(result.planExercises[0].targetWeight, 60)
        XCTAssertEqual(result.planExercises[0].note, "Flachbank")
    }

    func testMakePlanSkipsEntriesWithNoMatchingExerciseWithoutCrashing() {
        let export = PlanExport(
            name: "Push",
            note: nil,
            exercises: [PlanExport.ExerciseEntry(exerciseName: "Unbekannte Übung", order: 0, targetSets: 3, targetReps: 10, targetWeight: nil, note: nil)]
        )
        let result = PlanExportImport.makePlan(from: export, availableExercises: [])
        XCTAssertTrue(result.planExercises.isEmpty)
    }

    func testMakePlanAssignsContiguousOrderStartingAtZeroInExportOrder() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        // Export entries deliberately out of order — makePlan must sort by the entry's own
        // `order` field before reassigning contiguous indices, not just take array order.
        let export = PlanExport(
            name: "Ganzkörper",
            note: nil,
            exercises: [
                PlanExport.ExerciseEntry(exerciseName: "Kniebeugen", order: 1, targetSets: 3, targetReps: 10, targetWeight: nil, note: nil),
                PlanExport.ExerciseEntry(exerciseName: "Bankdrücken", order: 0, targetSets: 3, targetReps: 10, targetWeight: nil, note: nil)
            ]
        )

        let result = PlanExportImport.makePlan(from: export, availableExercises: [bench, squats])

        XCTAssertEqual(result.planExercises.map { $0.exercise?.name }, ["Bankdrücken", "Kniebeugen"])
        XCTAssertEqual(result.planExercises.map(\.order), [0, 1])
    }

    func testEachCreatedPlanExerciseReferencesTheNewPlan() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let export = PlanExport(
            name: "Push",
            note: nil,
            exercises: [PlanExport.ExerciseEntry(exerciseName: "Bankdrücken", order: 0, targetSets: 3, targetReps: 10, targetWeight: nil, note: nil)]
        )
        let result = PlanExportImport.makePlan(from: export, availableExercises: [bench])
        XCTAssertTrue(result.planExercises[0].plan === result.plan)
    }

    // MARK: full round trip — export a real plan, encode, decode, rebuild

    func testFullExportImportRoundTripRecreatesAnEquivalentPlan() throws {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let squats = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let originalPlan = TrainingPlan(name: "Ganzkörper", note: "Mo/Mi/Fr")
        _ = PlanExercise(order: 0, targetSets: 3, targetReps: 10, targetWeight: 60, plan: originalPlan, exercise: bench)
        _ = PlanExercise(order: 1, targetSets: 4, targetReps: 8, targetWeight: 80, plan: originalPlan, exercise: squats)

        let data = try PlanExportImport.encode(PlanExportImport.export(originalPlan))
        let decoded = try PlanExportImport.decode(data)
        let rebuilt = PlanExportImport.makePlan(from: decoded, availableExercises: [bench, squats])

        XCTAssertEqual(rebuilt.plan.name, "Ganzkörper")
        XCTAssertEqual(rebuilt.plan.note, "Mo/Mi/Fr")
        XCTAssertEqual(rebuilt.planExercises.count, 2)
        XCTAssertEqual(rebuilt.planExercises.map { $0.exercise?.name }, ["Bankdrücken", "Kniebeugen"])
    }
}
