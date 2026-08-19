import XCTest
@testable import GymTrack

final class ExerciseSideTests: XCTestCase {

    func testOppositeOfLeftIsRight() {
        XCTAssertEqual(ExerciseSide.left.opposite, .right)
    }

    func testOppositeOfRightIsLeft() {
        XCTAssertEqual(ExerciseSide.right.opposite, .left)
    }

    func testOppositeIsItsOwnInverse() {
        for side in ExerciseSide.allCases {
            XCTAssertEqual(side.opposite.opposite, side)
        }
    }

    func testEveryCaseHasANonEmptyShortAndFullLabel() {
        for side in ExerciseSide.allCases {
            XCTAssertFalse(side.shortLabel.isEmpty)
            XCTAssertFalse(side.fullLabel.isEmpty)
        }
    }

    func testShortLabelsAreDistinct() {
        let labels = ExerciseSide.allCases.map(\.shortLabel)
        XCTAssertEqual(labels.count, Set(labels).count)
    }
}
