import XCTest
@testable import GymTrack

final class InProgressStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "InProgressStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testFreshIDIsNotInProgress() {
        XCTAssertFalse(InProgressStore.isInProgress(UUID(), defaults: defaults))
    }

    func testSettingInProgressTrueMarksIt() {
        let id = UUID()
        InProgressStore.setInProgress(id, true, defaults: defaults)
        XCTAssertTrue(InProgressStore.isInProgress(id, defaults: defaults))
    }

    func testSettingInProgressFalseAfterTrueClearsIt() {
        let id = UUID()
        InProgressStore.setInProgress(id, true, defaults: defaults)
        InProgressStore.setInProgress(id, false, defaults: defaults)
        XCTAssertFalse(InProgressStore.isInProgress(id, defaults: defaults))
    }

    func testTrackingOneIDDoesNotAffectAnother() {
        let a = UUID()
        let b = UUID()
        InProgressStore.setInProgress(a, true, defaults: defaults)
        XCTAssertFalse(InProgressStore.isInProgress(b, defaults: defaults))
    }

    func testSettingFalseWithoutPriorTrueIsANoOpAndDoesNotCrash() {
        let id = UUID()
        InProgressStore.setInProgress(id, false, defaults: defaults)
        XCTAssertFalse(InProgressStore.isInProgress(id, defaults: defaults))
    }

    func testMultipleIDsCanBeInProgressSimultaneously() {
        let a = UUID()
        let b = UUID()
        InProgressStore.setInProgress(a, true, defaults: defaults)
        InProgressStore.setInProgress(b, true, defaults: defaults)
        XCTAssertTrue(InProgressStore.isInProgress(a, defaults: defaults))
        XCTAssertTrue(InProgressStore.isInProgress(b, defaults: defaults))
    }

    func testAllIDsReturnsEmptySetWhenNoneStored() {
        XCTAssertTrue(InProgressStore.allIDs(defaults: defaults).isEmpty)
    }

    func testAllIDsReturnsEveryStoredID() {
        let a = UUID()
        let b = UUID()
        InProgressStore.setInProgress(a, true, defaults: defaults)
        InProgressStore.setInProgress(b, true, defaults: defaults)
        XCTAssertEqual(InProgressStore.allIDs(defaults: defaults), [a, b])
    }

    func testAllIDsExcludesRemovedID() {
        let a = UUID()
        let b = UUID()
        InProgressStore.setInProgress(a, true, defaults: defaults)
        InProgressStore.setInProgress(b, true, defaults: defaults)
        InProgressStore.setInProgress(a, false, defaults: defaults)
        XCTAssertEqual(InProgressStore.allIDs(defaults: defaults), [b])
    }
}
