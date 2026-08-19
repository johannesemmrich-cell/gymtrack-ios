import XCTest
@testable import GymTrack

final class SetCompletionTests: XCTestCase {

    func testBothWeightAndRepsPresentIsComplete() {
        XCTAssertTrue(SetCompletion.isComplete(weight: 60, reps: 8))
    }

    func testZeroWeightIsNotComplete() {
        XCTAssertFalse(SetCompletion.isComplete(weight: 0, reps: 8))
    }

    func testZeroRepsIsNotComplete() {
        XCTAssertFalse(SetCompletion.isComplete(weight: 60, reps: 0))
    }

    func testBothZeroIsNotComplete() {
        XCTAssertFalse(SetCompletion.isComplete(weight: 0, reps: 0))
    }

    func testNegativeWeightIsNotComplete() {
        // Shouldn't be reachable via the UI (decimal pad), but the rule itself must not
        // treat a corrupt negative value as "entered".
        XCTAssertFalse(SetCompletion.isComplete(weight: -5, reps: 8))
    }
}
