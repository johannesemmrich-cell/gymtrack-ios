import XCTest
@testable import GymTrack

final class UnilateralSetPlanTests: XCTestCase {

    func testBilateralProducesAllNilSidesMatchingTargetSetsCount() {
        let sides = UnilateralSetPlan.sides(targetSets: 3, isUnilateral: false)
        XCTAssertEqual(sides, [nil, nil, nil])
    }

    func testUnilateralProducesTwiceTargetSetsAlternatingLeftRight() {
        let sides = UnilateralSetPlan.sides(targetSets: 3, isUnilateral: true)
        XCTAssertEqual(sides, [.left, .right, .left, .right, .left, .right])
    }

    func testUnilateralWithOneTargetSetProducesOneLeftOneRight() {
        let sides = UnilateralSetPlan.sides(targetSets: 1, isUnilateral: true)
        XCTAssertEqual(sides, [.left, .right])
    }

    func testZeroTargetSetsProducesEmptySequenceRegardlessOfUnilateral() {
        XCTAssertTrue(UnilateralSetPlan.sides(targetSets: 0, isUnilateral: false).isEmpty)
        XCTAssertTrue(UnilateralSetPlan.sides(targetSets: 0, isUnilateral: true).isEmpty)
    }

    func testNegativeTargetSetsDoesNotCrashAndProducesEmptySequence() {
        // Defensive: shouldn't happen via the UI (Stepper is clamped to 1...20), but this
        // function must not crash on a corrupt/negative value.
        XCTAssertTrue(UnilateralSetPlan.sides(targetSets: -1, isUnilateral: true).isEmpty)
    }
}
