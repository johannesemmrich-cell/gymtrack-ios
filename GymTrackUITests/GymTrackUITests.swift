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

    func testCreatingPlanAndAddingExerciseShowsItInEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()

        let addPlanButton = app.navigationBars.buttons["Plan hinzufügen"]
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 5))
        addPlanButton.tap()

        // Tapping "+" creates the plan and navigates straight into its editor.
        let nameField = app.textFields["Planname"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))

        let addExerciseButton = app.buttons["Übung hinzufügen"]
        XCTAssertTrue(addExerciseButton.waitForExistence(timeout: 5))
        addExerciseButton.tap()

        // "Bankdrücken" is alphabetically first within "Brust", the first muscle-group
        // section, so it's guaranteed visible in the picker without scrolling/searching.
        let pickerOption = app.buttons["Bankdrücken"]
        XCTAssertTrue(pickerOption.waitForExistence(timeout: 5))
        pickerOption.tap()

        // Back in the editor, the newly added exercise should now be the only row.
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))
    }

    func testStartingWorkoutFromPlanShowsLoggableSets() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Build a one-exercise plan first.
        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["Übung hinzufügen"].tap()
        let pickerOption = app.buttons["Bankdrücken"]
        XCTAssertTrue(pickerOption.waitForExistence(timeout: 5))
        pickerOption.tap()
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))

        // Start it from the Training tab.
        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()

        // The workout screen should show the exercise as a section with its pre-filled sets,
        // and a way to end the workout.
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bankdrücken"].waitForExistence(timeout: 5))

        // Editing the first set should open its edit sheet.
        let firstSetRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'kg'")).firstMatch
        XCTAssertTrue(firstSetRow.waitForExistence(timeout: 5))
        firstSetRow.tap()

        let repsStepper = app.steppers.firstMatch
        XCTAssertTrue(repsStepper.waitForExistence(timeout: 5))

        // Regression test: typing a multi-digit weight must not corrupt the value via a
        // get/set round-trip through the live text field (a real bug found during review —
        // "55" was ending up stored as "5.05"). Check after EVERY keystroke, not just the
        // final value, since a mid-typing corruption could theoretically self-correct by the
        // last character.
        let weightField = app.textFields["Satz-Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        typeAndCheckEachKeystroke(weightField, "55")

        app.buttons["Fertig"].tap()

        // Reopen the same set and confirm the persisted weight round-trips correctly too.
        firstSetRow.tap()
        let reopenedWeightField = app.textFields["Satz-Gewicht"]
        XCTAssertTrue(reopenedWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedWeightField.value as? String, "55.0")
        app.buttons["Fertig"].tap()
    }

    /// PlanExerciseEditView shares the same weight-field pattern as SetEditView, but
    /// targetWeight is Optional<Double> there. A freshly-added plan-exercise never had a
    /// weight entered, so its field must render empty, not "0.0" — this is the UI-visible
    /// half of the nil-vs-zero distinction (the parsing itself is unit-tested in
    /// WeightInputTests, which also directly covers what "clearing the field" resolves to).
    func testFreshPlanExerciseWeightFieldStartsEmptyNotZero() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["Übung hinzufügen"].tap()
        let pickerOption = app.buttons["Bankdrücken"]
        XCTAssertTrue(pickerOption.waitForExistence(timeout: 5))
        pickerOption.tap()
        let exerciseRow = app.buttons["Bankdrücken"]
        XCTAssertTrue(exerciseRow.waitForExistence(timeout: 5))

        exerciseRow.tap()
        let weightField = app.textFields["Zielgewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        // XCUITest reports an empty TextField's value as its placeholder text ("optional",
        // set in PlanExerciseEditView), not "" — both indicate "no weight entered".
        let renderedValue = (weightField.value as? String) ?? ""
        XCTAssertTrue(
            renderedValue.isEmpty || renderedValue == "optional",
            "A never-set target weight must render as an empty field, not '0.0' — got '\(renderedValue)'"
        )
        app.buttons["Fertig"].tap()
    }

    private func typeAndCheckEachKeystroke(_ field: XCUIElement, _ text: String) {
        var expected = ""
        for character in text {
            field.typeText(String(character))
            expected.append(character)
            let actual = field.value as? String ?? "<nil>"
            XCTAssertEqual(actual, expected, "After typing '\(character)', field should read '\(expected)' but read '\(actual)'")
        }
    }
}
