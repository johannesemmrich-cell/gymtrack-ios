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
}
