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

    /// Creating a brand-new exercise from inside the plan's exercise picker (rather than
    /// having to back out to Einstellungen → Übungen first) must add it to the plan directly.
    func testCreatingExerciseFromWithinPlanEditorAddsItDirectly() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["Übung hinzufügen"].tap()

        let createButton = app.buttons["Neue Übung erstellen"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let nameField = app.textFields["Übungsname"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Ganz Neue Übung")
        app.buttons["Sichern"].tap()

        // Both the create sheet and the picker sheet should be gone, landing back on the
        // plan editor with the freshly created exercise already added.
        XCTAssertTrue(app.buttons["Ganz Neue Übung"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
    }

    func testDuplicatingPlanCreatesACopyAlongsideTheOriginal() {
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
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))

        app.buttons["BackButton"].tap()

        let originalRow = app.staticTexts["Neuer Plan"]
        XCTAssertTrue(originalRow.waitForExistence(timeout: 5))
        // "Duplizieren" is a leading-edge swipe action — reveal it with swipeRight.
        originalRow.swipeRight()
        let duplicateButton = app.buttons["Duplizieren"]
        XCTAssertTrue(duplicateButton.waitForExistence(timeout: 5))
        duplicateButton.tap()

        XCTAssertTrue(app.staticTexts["Neuer Plan (Kopie)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Neuer Plan"].waitForExistence(timeout: 5))

        // The copy must carry over the exercise, not start empty.
        app.staticTexts["Neuer Plan (Kopie)"].tap()
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

    /// Ending a workout that still has un-toggled sets must prompt once, in one tap remove
    /// them, and never leave the session hanging around.
    func testEndingWorkoutWithIncompleteSetsPromptsOneTapRemoval() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // Sets are pre-filled but not marked "Erledigt" by default — ending now must prompt.
        app.navigationBars.buttons["Beenden"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        app.buttons["Entfernen & Beenden"].tap()

        // Session is over: Training tab falls back to the plan-picker list.
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))
    }

    /// If every set was already marked done, ending must not interrupt with a prompt at all.
    func testEndingWorkoutWithAllSetsCompletedSkipsPrompt() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // The exercise defaults to 3 target sets (no history yet, PlanExerciseDefaults
        // fallback). Each SetRow carries a deterministic "Satz <order>" identifier
        // (0, 1, 2), so mark every one of them done by address rather than by content —
        // all 3 rows render identically ("0 kg × 10") until touched, which makes
        // position/content-based queries unreliable once one row's state changes.
        for order in 0..<3 {
            let row = app.buttons["Satz \(order)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()
            let toggle = app.switches["Satz erledigt"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            // SwiftUI's Toggle exposes a row-sized outer "Switch" element (matched by our
            // accessibility label) wrapping the actual iOS switch widget as an unlabeled
            // inner "Switch" — tapping the outer element doesn't propagate to flip the real
            // control, so tap the inner one directly.
            toggle.switches.firstMatch.tap()
            app.buttons["Fertig"].tap()
        }

        app.navigationBars.buttons["Beenden"].tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))
    }

    /// The ticket's explicit regression, end-to-end: adding a warmup set suggests the
    /// correct percentage and inserts it before the working set (shifting the working set's
    /// identifier), and deleting the warmup afterward must never change the working set's
    /// own weight — the exact RepCount-style bug this project avoids.
    func testAddingAndRemovingWarmupSetNeverChangesWorkingSetWeight() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // Give the working set a known weight so the warmup suggestion is checkable.
        let workingRow = app.buttons["Satz 0"]
        XCTAssertTrue(workingRow.waitForExistence(timeout: 5))
        workingRow.tap()
        let weightField = app.textFields["Satz-Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        typeAndCheckEachKeystroke(weightField, "100")
        app.buttons["Fertig"].tap()

        // Adding a warmup inserts it BEFORE the working set, so the working set's
        // identifier shifts from "Satz 0" to "Satz 1".
        app.buttons["Aufwärmsatz"].tap()
        let warmupRow = app.buttons["Satz 0"]
        XCTAssertTrue(warmupRow.waitForExistence(timeout: 5))
        warmupRow.tap()
        let warmupWeightField = app.textFields["Satz-Gewicht"]
        XCTAssertTrue(warmupWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(warmupWeightField.value as? String, "50.0", "A single warmup should default to 50% of the 100 kg working weight")
        app.buttons["Fertig"].tap()

        let shiftedWorkingRow = app.buttons["Satz 1"]
        XCTAssertTrue(shiftedWorkingRow.waitForExistence(timeout: 5))

        // Delete the warmup via swipe-to-delete.
        warmupRow.swipeLeft()
        app.buttons["Delete"].tap()

        // The working set's own weight must be completely untouched by the warmup's removal.
        XCTAssertTrue(shiftedWorkingRow.waitForExistence(timeout: 5))
        shiftedWorkingRow.tap()
        let reopenedWeightField = app.textFields["Satz-Gewicht"]
        XCTAssertTrue(reopenedWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedWeightField.value as? String, "100.0")
        app.buttons["Fertig"].tap()
    }

    func testCompletingAWorkoutShowsStatistics() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // End the workout regardless of whether the default 3 target sets are all marked
        // done — if the incomplete-sets alert appears, remove-and-end still leaves at least
        // one completed set behind (the eligibility bar for a session to count).
        let workingRow = app.buttons["Satz 0"]
        XCTAssertTrue(workingRow.waitForExistence(timeout: 5))
        workingRow.tap()
        let toggle = app.switches["Satz erledigt"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.switches.firstMatch.tap()
        app.buttons["Fertig"].tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Statistik"].tap()
        XCTAssertTrue(app.staticTexts["Ø Trainingsdauer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ø Trainings / Woche"].waitForExistence(timeout: 5))
    }

    /// Builds a one-exercise plan and starts a workout from it, landing on WorkoutSessionView.
    private func startWorkoutFromFreshPlan(_ app: XCUIApplication) {
        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["Übung hinzufügen"].tap()
        let pickerOption = app.buttons["Bankdrücken"]
        XCTAssertTrue(pickerOption.waitForExistence(timeout: 5))
        pickerOption.tap()
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
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
