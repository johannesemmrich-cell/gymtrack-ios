import XCTest
@testable import GymTrack

final class FeedbackFilteringTests: XCTestCase {

    func testEmptyListReturnsEmpty() {
        let result = FeedbackFiltering.filter([], priority: nil, onlyOpen: true)
        XCTAssertTrue(result.isEmpty)
    }

    func testNoPriorityFilterAndOnlyOpenReturnsAllUnresolved() {
        let open = FeedbackEntry(priority: .high, isResolved: false)
        let resolved = FeedbackEntry(priority: .low, isResolved: true)

        let result = FeedbackFiltering.filter([open, resolved], priority: nil, onlyOpen: true)

        XCTAssertEqual(result, [open])
    }

    func testNoPriorityFilterAndNotOnlyOpenReturnsAllResolved() {
        let open = FeedbackEntry(priority: .high, isResolved: false)
        let resolved = FeedbackEntry(priority: .low, isResolved: true)

        let result = FeedbackFiltering.filter([open, resolved], priority: nil, onlyOpen: false)

        XCTAssertEqual(result, [resolved])
    }

    func testPriorityFilterReturnsOnlyMatchingPriority() {
        let high = FeedbackEntry(priority: .high, isResolved: false)
        let low = FeedbackEntry(priority: .low, isResolved: false)

        let result = FeedbackFiltering.filter([high, low], priority: .high, onlyOpen: true)

        XCTAssertEqual(result, [high])
    }

    func testPriorityFilterCombinedWithResolvedStateExcludesWrongState() {
        let matchingPriorityButResolved = FeedbackEntry(priority: .high, isResolved: true)
        let matchingPriorityAndOpen = FeedbackEntry(priority: .high, isResolved: false)

        let result = FeedbackFiltering.filter(
            [matchingPriorityButResolved, matchingPriorityAndOpen],
            priority: .high,
            onlyOpen: true
        )

        XCTAssertEqual(result, [matchingPriorityAndOpen])
    }

    func testPriorityFilterWithNoMatchesReturnsEmpty() {
        let low = FeedbackEntry(priority: .low, isResolved: false)
        let result = FeedbackFiltering.filter([low], priority: .urgent, onlyOpen: true)
        XCTAssertTrue(result.isEmpty)
    }
}
