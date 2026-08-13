import XCTest
@testable import GymTrack

final class DropsetSuggestionTests: XCTestCase {

    func testSuggestsTwentyPercentLighterThanThePreviousSet() {
        XCTAssertEqual(DropsetSuggestion.suggestedWeight(previousWeight: 100), 80)
    }

    func testSuggestionIsAlwaysLighterThanThePreviousWeightForAPositiveInput() {
        XCTAssertLessThan(DropsetSuggestion.suggestedWeight(previousWeight: 60), 60)
    }

    func testZeroPreviousWeightSuggestsZeroWithoutCrashing() {
        XCTAssertEqual(DropsetSuggestion.suggestedWeight(previousWeight: 0), 0)
    }

    func testChainingContinuesTheLadderDownFromThePreviousDropRatherThanResetting() {
        let firstDrop = DropsetSuggestion.suggestedWeight(previousWeight: 100)
        let secondDrop = DropsetSuggestion.suggestedWeight(previousWeight: firstDrop)
        XCTAssertEqual(firstDrop, 80)
        XCTAssertEqual(secondDrop, 64)
    }
}
