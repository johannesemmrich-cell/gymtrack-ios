import XCTest
@testable import GymTrack

final class FeedbackPriorityDisplayTests: XCTestCase {

    func testEveryCaseHasANonEmptyLabel() {
        for priority in FeedbackPriority.allCases {
            XCTAssertFalse(priority.label.isEmpty, "\(priority) has no label")
        }
    }

    func testEveryCaseHasANonEmptyEmoji() {
        for priority in FeedbackPriority.allCases {
            XCTAssertFalse(priority.emoji.isEmpty, "\(priority) has no emoji")
        }
    }

    func testAllLabelsAreDistinct() {
        let labels = FeedbackPriority.allCases.map(\.label)
        XCTAssertEqual(labels.count, Set(labels).count, "Two priorities share the same label")
    }

    func testAllEmojiAreDistinct() {
        let emoji = FeedbackPriority.allCases.map(\.emoji)
        XCTAssertEqual(emoji.count, Set(emoji).count, "Two priorities share the same emoji")
    }
}
