import XCTest
@testable import GymTrack

final class WeightInputTests: XCTestCase {

    func testEmptyStringParsesToNil() {
        XCTAssertNil(WeightInput.parse(""))
    }

    func testWhitespaceOnlyParsesToNil() {
        XCTAssertNil(WeightInput.parse("   "))
    }

    func testWholeNumberParsesCorrectly() {
        XCTAssertEqual(WeightInput.parse("55"), 55)
    }

    func testDecimalWithDotParsesCorrectly() {
        XCTAssertEqual(WeightInput.parse("102.5"), 102.5)
    }

    func testDecimalWithCommaParsesCorrectly() {
        XCTAssertEqual(WeightInput.parse("102,5"), 102.5)
    }

    func testGarbageInputParsesToNil() {
        XCTAssertNil(WeightInput.parse("abc"))
    }

    func testTrailingDecimalPointParsesAsWholeNumber() {
        // "42." is a valid intermediate state while a user is typing "42.5" — Swift's Double
        // parser accepts it as 42.0, which is correct: it must not crash or throw, and the
        // eventual full value ("42.5") will simply overwrite it on the next keystroke.
        XCTAssertEqual(WeightInput.parse("42."), 42.0)
    }
}
