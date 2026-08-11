import XCTest
@testable import GymTrack

final class PlanExerciseOrderingTests: XCTestCase {

    func testReindexAssignsSequentialOrderMatchingArrayPosition() {
        let a = PlanExercise(order: 5)
        let b = PlanExercise(order: 1)
        let c = PlanExercise(order: 9)
        PlanExerciseOrdering.reindex([a, b, c])
        XCTAssertEqual(a.order, 0)
        XCTAssertEqual(b.order, 1)
        XCTAssertEqual(c.order, 2)
    }

    func testReindexOnEmptyArrayDoesNotCrash() {
        PlanExerciseOrdering.reindex([])
    }

    func testReindexOnSingleItemSetsOrderZero() {
        let a = PlanExercise(order: 42)
        PlanExerciseOrdering.reindex([a])
        XCTAssertEqual(a.order, 0)
    }
}
