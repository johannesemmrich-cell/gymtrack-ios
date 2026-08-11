import XCTest
import SwiftData
@testable import GymTrack

@MainActor
final class ExerciseSeederTests: XCTestCase {

    private func makeContext() -> ModelContext {
        let container = PersistenceController.makeInMemoryContainer()
        return ModelContext(container)
    }

    func testSeedingEmptyStoreInsertsAllDefaultExercises() throws {
        let context = makeContext()
        ExerciseSeeder.seedIfNeeded(context: context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(all.count, ExerciseSeeder.defaultExercises.count)
        XCTAssertTrue(all.allSatisfy { !$0.isCustom })
    }

    func testSeedingTwiceDoesNotDuplicate() throws {
        let context = makeContext()
        ExerciseSeeder.seedIfNeeded(context: context)
        ExerciseSeeder.seedIfNeeded(context: context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(all.count, ExerciseSeeder.defaultExercises.count)
    }

    func testSeedingSkipsExerciseThatAlreadyExistsByName() throws {
        let context = makeContext()
        guard let first = ExerciseSeeder.defaultExercises.first else {
            XCTFail("Expected at least one default exercise")
            return
        }
        let preExisting = Exercise(name: first.name, muscleGroup: first.muscleGroup, isCustom: false)
        context.insert(preExisting)
        try context.save()

        ExerciseSeeder.seedIfNeeded(context: context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(all.count, ExerciseSeeder.defaultExercises.count, "Should not insert a duplicate for an already-present name")
    }

    func testSeedingDoesNotTouchCustomUserExercises() throws {
        let context = makeContext()
        let custom = Exercise(name: "Meine geheime Übung", muscleGroup: .other, isCustom: true)
        context.insert(custom)
        try context.save()

        ExerciseSeeder.seedIfNeeded(context: context)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(all.count, ExerciseSeeder.defaultExercises.count + 1)
        XCTAssertTrue(all.contains { $0.name == "Meine geheime Übung" && $0.isCustom })
    }

    func testDefaultExerciseListHasNoDuplicateNames() {
        let names = ExerciseSeeder.defaultExercises.map(\.name)
        XCTAssertEqual(names.count, Set(names).count, "Default exercise list must not contain duplicate names")
    }
}
