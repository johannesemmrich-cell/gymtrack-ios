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

    func testAddingCustomExerciseShowsItInLibrary() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Übungen"].tap()

        let addButton = app.navigationBars.buttons["Übung hinzufügen"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["Übungsname"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Meine Testübung")

        app.buttons["Sichern"].tap()

        // With ~35 seeded default exercises, the new one (grouped under "Sonstiges", the last
        // section) can be off-screen — SwiftUI's List only renders visible cells lazily. Scroll
        // down until it appears rather than relying on the exact accessibility shape of
        // .searchable's search field. ExerciseRow uses .accessibilityElement(children: .combine),
        // so query by identifier across any element type instead of assuming staticText.
        let newExerciseRow = app.descendants(matching: .any)["Meine Testübung"]
        var attempts = 0
        while !newExerciseRow.exists && attempts < 15 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(newExerciseRow.exists)
    }
}
