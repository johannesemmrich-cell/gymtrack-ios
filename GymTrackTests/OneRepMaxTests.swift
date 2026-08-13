import XCTest
@testable import GymTrack

final class OneRepMaxTests: XCTestCase {

    func testEstimatesUsingTheEpleyFormula() {
        // 100 * (1 + 5/30) = 116.666...
        XCTAssertEqual(OneRepMax.estimate(weight: 100, reps: 5), 100 * (1 + 5.0 / 30.0), accuracy: 0.0001)
    }

    func testSingleRepIsExactlyTheWeightItself() {
        // No estimation needed — a 1-rep set already IS the 1RM.
        XCTAssertEqual(OneRepMax.estimate(weight: 80, reps: 1), 80)
    }

    func testZeroRepsIsUndefinedAndReturnsZero() {
        XCTAssertEqual(OneRepMax.estimate(weight: 100, reps: 0), 0)
    }

    func testZeroWeightIsUndefinedAndReturnsZero() {
        XCTAssertEqual(OneRepMax.estimate(weight: 0, reps: 5), 0)
    }

    func testNegativeRepsIsUndefinedAndReturnsZeroRatherThanCrashing() {
        XCTAssertEqual(OneRepMax.estimate(weight: 100, reps: -1), 0)
    }

    func testHigherRepsProducesAHigherEstimateForTheSameWeight() {
        let fiveReps = OneRepMax.estimate(weight: 100, reps: 5)
        let tenReps = OneRepMax.estimate(weight: 100, reps: 10)
        XCTAssertGreaterThan(tenReps, fiveReps)
    }

    func testVeryHighRepsStillProducesASensibleResultWithoutCrashing() {
        let result = OneRepMax.estimate(weight: 20, reps: 50)
        XCTAssertGreaterThan(result, 20)
        XCTAssertTrue(result.isFinite)
    }
}
