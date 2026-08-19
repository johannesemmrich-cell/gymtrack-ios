import XCTest
@testable import GymTrack

final class DeveloperPasswordCheckTests: XCTestCase {

    func testCorrectPasswordMatches() {
        XCTAssertTrue(DeveloperPasswordCheck.matches("Isg#45krusgL."))
    }

    func testWrongPasswordDoesNotMatch() {
        XCTAssertFalse(DeveloperPasswordCheck.matches("falschesPasswort"))
    }

    func testEmptyPasswordDoesNotMatch() {
        XCTAssertFalse(DeveloperPasswordCheck.matches(""))
    }

    func testPasswordWithSurroundingWhitespaceStillMatches() {
        XCTAssertTrue(DeveloperPasswordCheck.matches("  Isg#45krusgL.  "))
    }

    func testPasswordIsCaseSensitive() {
        XCTAssertFalse(DeveloperPasswordCheck.matches("isg#45krusgl."))
    }

    func testCloselyWrongPasswordMissingTrailingPeriodDoesNotMatch() {
        XCTAssertFalse(DeveloperPasswordCheck.matches("Isg#45krusgL"))
    }
}
