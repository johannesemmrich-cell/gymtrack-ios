import XCTest
@testable import GymTrack

final class EffectiveSetValuesTests: XCTestCase {

    func testRealWeightTakesPriorityOverGhostHint() {
        let set = SetEntry(weight: 55, suggestedWeight: 100)
        XCTAssertEqual(set.effectiveWeight, 55)
    }

    func testFallsBackToGhostHintWhenRealWeightIsZero() {
        let set = SetEntry(weight: 0, suggestedWeight: 100)
        XCTAssertEqual(set.effectiveWeight, 100)
    }

    func testZeroWhenNeitherRealNorGhostWeightExists() {
        let set = SetEntry(weight: 0, suggestedWeight: nil)
        XCTAssertEqual(set.effectiveWeight, 0)
    }

    func testRealRepsTakesPriorityOverGhostHint() {
        let set = SetEntry(reps: 6, suggestedReps: 12)
        XCTAssertEqual(set.effectiveReps, 6)
    }

    func testFallsBackToGhostHintWhenRealRepsIsZero() {
        let set = SetEntry(reps: 0, suggestedReps: 12)
        XCTAssertEqual(set.effectiveReps, 12)
    }

    func testZeroWhenNeitherRealNorGhostRepsExists() {
        let set = SetEntry(reps: 0, suggestedReps: nil)
        XCTAssertEqual(set.effectiveReps, 0)
    }
}
