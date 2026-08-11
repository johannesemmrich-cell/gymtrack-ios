import XCTest

final class GymTrackUITests: XCTestCase {

    func testAppLaunchesAndShowsTabBar() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testCreatingAGymShowsItInTheList() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()

        let addButton = app.navigationBars.buttons["Gym hinzufügen"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["Gym-Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Test-Gym")

        app.buttons["Sichern"].tap()

        // GymRow uses .accessibilityElement(children: .combine) for VoiceOver, so the row's
        // Text is merged into the enclosing Button's label rather than exposed as its own
        // staticText element.
        XCTAssertTrue(app.buttons["Test-Gym"].waitForExistence(timeout: 5))
    }
}
