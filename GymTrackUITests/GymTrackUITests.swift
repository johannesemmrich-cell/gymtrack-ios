import XCTest

final class GymTrackUITests: XCTestCase {

    func testAppLaunchesAndShowsTabBar() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }
}
