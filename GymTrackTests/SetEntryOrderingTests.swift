import XCTest
@testable import GymTrack

final class SetEntryOrderingTests: XCTestCase {

    func testReindexAssignsSequentialOrderMatchingArrayPosition() {
        let a = SetEntry(order: 5)
        let b = SetEntry(order: 1)
        let c = SetEntry(order: 9)
        SetEntryOrdering.reindex([a, b, c])
        XCTAssertEqual(a.order, 0)
        XCTAssertEqual(b.order, 1)
        XCTAssertEqual(c.order, 2)
    }

    func testReindexOnEmptyArrayDoesNotCrash() {
        SetEntryOrdering.reindex([])
    }

    /// The exact regression this project must never reintroduce: reindexing must only ever
    /// touch `.order`, never any other property of any set it reorders.
    func testReindexNeverTouchesWeightRepsNoteOrCompletion() {
        let a = SetEntry(order: 2, reps: 8, weight: 60, isCompleted: true, note: "A")
        let b = SetEntry(order: 0, reps: 12, weight: 20, isCompleted: false, note: nil)
        SetEntryOrdering.reindex([b, a])
        XCTAssertEqual(a.reps, 8)
        XCTAssertEqual(a.weight, 60)
        XCTAssertTrue(a.isCompleted)
        XCTAssertEqual(a.note, "A")
        XCTAssertEqual(b.reps, 12)
        XCTAssertEqual(b.weight, 20)
        XCTAssertFalse(b.isCompleted)
        XCTAssertNil(b.note)
    }
}
