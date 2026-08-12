import XCTest
@testable import GymTrack

final class WarmupSuggestionTests: XCTestCase {

    func testZeroCountReturnsEmpty() {
        XCTAssertTrue(WarmupSuggestion.suggestedWeights(workingWeight: 100, count: 0).isEmpty)
    }

    func testZeroWorkingWeightReturnsZeros() {
        XCTAssertEqual(WarmupSuggestion.suggestedWeights(workingWeight: 0, count: 3), [0, 0, 0])
    }

    func testSingleWarmupIsHalfWorkingWeight() {
        XCTAssertEqual(WarmupSuggestion.suggestedWeights(workingWeight: 100, count: 1), [50])
    }

    func testThreeWarmupsMatchTheReferenceLadder() {
        // Spec's own example: 50/70/85 % of the working weight.
        XCTAssertEqual(WarmupSuggestion.suggestedWeights(workingWeight: 100, count: 3), [50, 70, 85])
    }

    func testWeightsAreStrictlyIncreasing() {
        let weights = WarmupSuggestion.suggestedWeights(workingWeight: 100, count: 5)
        for i in 1..<weights.count {
            XCTAssertGreaterThan(weights[i], weights[i - 1])
        }
    }

    func testAllSuggestionsStayBelowWorkingWeight() {
        for count in 1...6 {
            let weights = WarmupSuggestion.suggestedWeights(workingWeight: 100, count: count)
            XCTAssertTrue(weights.allSatisfy { $0 < 100 }, "count=\(count) produced a weight >= working weight: \(weights)")
        }
    }

    func testCountMatchesRequestedLength() {
        for count in 0...6 {
            XCTAssertEqual(WarmupSuggestion.suggestedWeights(workingWeight: 80, count: count).count, count)
        }
    }
}
