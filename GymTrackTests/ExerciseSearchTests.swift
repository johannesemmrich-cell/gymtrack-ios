import XCTest
@testable import GymTrack

final class ExerciseSearchTests: XCTestCase {

    func testEmptyQueryReturnsAllExercises() {
        let exercises = [
            Exercise(name: "Bankdrücken", muscleGroup: .chest),
            Exercise(name: "Kniebeugen", muscleGroup: .legs)
        ]
        let result = ExerciseSearch.filter(exercises: exercises, query: "")
        XCTAssertEqual(result.count, 2)
    }

    func testFilterMatchesCaseInsensitiveSubstring() {
        let exercises = [
            Exercise(name: "Bankdrücken", muscleGroup: .chest),
            Exercise(name: "Kniebeugen", muscleGroup: .legs)
        ]
        let result = ExerciseSearch.filter(exercises: exercises, query: "bank")
        XCTAssertEqual(result.map(\.name), ["Bankdrücken"])
    }

    func testFilterWithNoMatchesReturnsEmpty() {
        let exercises = [Exercise(name: "Bankdrücken", muscleGroup: .chest)]
        let result = ExerciseSearch.filter(exercises: exercises, query: "xyz")
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterIgnoresLeadingTrailingWhitespaceInQuery() {
        let exercises = [Exercise(name: "Bankdrücken", muscleGroup: .chest)]
        let result = ExerciseSearch.filter(exercises: exercises, query: "  bank  ")
        XCTAssertEqual(result.map(\.name), ["Bankdrücken"])
    }

    func testFilterOnEmptyExerciseListReturnsEmpty() {
        let result = ExerciseSearch.filter(exercises: [], query: "bank")
        XCTAssertTrue(result.isEmpty)
    }

    func testGroupedOrdersByMuscleGroupDeclarationOrderAndSortsNamesWithinGroup() {
        let exercises = [
            Exercise(name: "Kniebeugen", muscleGroup: .legs),
            Exercise(name: "Bankdrücken", muscleGroup: .chest),
            Exercise(name: "Ausfallschritte", muscleGroup: .legs)
        ]
        let grouped = ExerciseSearch.grouped(exercises: exercises, query: "")
        XCTAssertEqual(grouped.map(\.group), [.chest, .legs])
        XCTAssertEqual(grouped.first(where: { $0.group == .legs })?.items.map(\.name), ["Ausfallschritte", "Kniebeugen"])
    }

    func testGroupedExcludesEmptyGroups() {
        let exercises = [Exercise(name: "Bankdrücken", muscleGroup: .chest)]
        let grouped = ExerciseSearch.grouped(exercises: exercises, query: "")
        XCTAssertEqual(grouped.count, 1)
    }

    func testGroupedAppliesQueryFilterBeforeGrouping() {
        let exercises = [
            Exercise(name: "Bankdrücken", muscleGroup: .chest),
            Exercise(name: "Kniebeugen", muscleGroup: .legs)
        ]
        let grouped = ExerciseSearch.grouped(exercises: exercises, query: "bank")
        XCTAssertEqual(grouped.map(\.group), [.chest])
    }
}
