import XCTest

final class GymTrackUITests: XCTestCase {

    /// Regression: multiple `Button`s sharing one `HStack` inside a List row, without an
    /// explicit `.buttonStyle`, silently merged into one tap target — tapping ANY of
    /// "Aufwärmsatz"/"Dropsatz"/"Satz hinzufügen" fired ALL of their actions at once, so one
    /// tap created one extra `SetEntry` per sibling button in the row (discovered via this
    /// ticket's testing; also affected the pre-existing "Aufwärmsatz" button, not just the
    /// newly added "Dropsatz" one). Root-caused by removing sibling buttons one at a time
    /// until a single button produced the correct, exactly-one-set-per-tap result. Fixed by
    /// giving each button its own `.buttonStyle(.borderless)`, matching the `.plain` style
    /// already used (and already working correctly) on the per-set row buttons above.
    func testAddingASetCreatesExactlyOneNewSetNotTwo() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // The default plan already pre-fills 3 sets (Satz 0/1/2).
        app.buttons["Satz hinzufügen"].tap()

        XCTAssertTrue(app.textFields["Satz 3 Gewicht"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Satz 4 Gewicht"].exists, "Tapping 'Satz hinzufügen' once must create exactly one new set")
    }

    /// Same regression as `testAddingASetCreatesExactlyOneNewSetNotTwo`, but for the
    /// pre-existing "Aufwärmsatz" button specifically (it shared the same merged-tap-target
    /// bug, discovered only because this ticket added a sibling button next to it).
    func testAddingAWarmupSetCreatesExactlyOneNewSetNotTwo() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        app.buttons["Aufwärmsatz"].tap()

        // A single warmup shifts the 3 pre-filled sets to Satz 1/2/3, adding the warmup at
        // Satz 0. If the merged-tap-target bug were still present, Satz 4 would also exist.
        XCTAssertTrue(app.textFields["Satz 0 Gewicht"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Satz 3 Gewicht"].exists)
        XCTAssertFalse(app.textFields["Satz 4 Gewicht"].exists, "Tapping 'Aufwärmsatz' once must create exactly one new set")
    }

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

    func testDeletingTheActiveGymPromotesAnotherGymToActive() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()

        createGym(app, name: "Berlin")
        createGym(app, name: "Frankfurt")

        let frankfurtButton = app.buttons["Frankfurt"]
        XCTAssertTrue(frankfurtButton.waitForExistence(timeout: 5))
        frankfurtButton.tap()
        XCTAssertTrue(frankfurtButton.isSelected)

        // Delete the now-active gym (Frankfurt) — Berlin, the only remaining gym, should be
        // auto-promoted to active rather than leaving the app with no active gym at all.
        frankfurtButton.swipeLeft()
        app.buttons["Löschen"].tap()

        let berlinButton = app.buttons["Berlin"]
        XCTAssertTrue(berlinButton.waitForExistence(timeout: 5))
        XCTAssertTrue(berlinButton.isSelected)
    }

    /// The gym switcher directly on the Pläne tab must both filter the plan list AND activate
    /// the chosen gym (same effect as tapping it in Einstellungen → Gyms) — the whole point of
    /// moving gym-switching out of Einstellungen. Gym-less plans stay visible under any filter;
    /// a specific-gym filter with no matching plans shows a dedicated empty state rather than
    /// the "create your first plan ever" one, since a plan does exist, just not for this gym.
    func testGymFilterOnPlanListSwitchesActiveGymAndFiltersPlans() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Berlin")
        createGym(app, name: "Frankfurt")

        app.tabBars.buttons["Pläne"].tap()
        let gymFilter = app.buttons["Gym-Filter"]
        XCTAssertTrue(gymFilter.waitForExistence(timeout: 5))
        gymFilter.tap()
        app.buttons["Berlin"].tap()

        // Picking Berlin above must have activated it immediately, exactly like tapping it
        // directly in Einstellungen → Gyms would. Checked right here, before picking Frankfurt
        // below (which would legitimately activate Frankfurt instead) confounds the picture.
        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        XCTAssertTrue(app.buttons["Berlin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Berlin"].isSelected)
        app.tabBars.buttons["Pläne"].tap()

        // A plan created while the Berlin filter is active must be tagged Berlin.
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()

        XCTAssertTrue(app.staticTexts["Neuer Plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 Übungen · Berlin"].waitForExistence(timeout: 5))

        gymFilter.tap()
        app.buttons["Frankfurt"].tap()
        XCTAssertTrue(app.staticTexts["Keine Pläne für dieses Gym"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Neuer Plan"].exists)

        gymFilter.tap()
        app.buttons["Alle"].tap()
        XCTAssertTrue(app.staticTexts["Neuer Plan"].waitForExistence(timeout: 5))
    }

    /// The very first time the Pläne tab appears, its gym filter must already default to
    /// whichever gym is currently active elsewhere in the app — not "Alle" — without the user
    /// ever having touched the filter picker themselves.
    func testPlanListInitiallySelectsTheCurrentlyActiveGymAsFilter() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Berlin")
        app.buttons["Berlin"].tap()
        XCTAssertTrue(app.buttons["Berlin"].isSelected)

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()

        XCTAssertTrue(app.staticTexts["0 Übungen · Berlin"].waitForExistence(timeout: 5))
    }

    /// Deleting the gym currently selected as the Pläne-tab filter auto-promotes a replacement
    /// gym app-wide (GymActivation.promoteReplacement, exercised by
    /// testDeletingTheActiveGymPromotesAnotherGymToActive above) — the filter must follow that
    /// promotion instead of silently falling back to "Alle" and diverging from the gym actually
    /// used for weight suggestions/logging for the rest of the session.
    func testDeletingTheActiveGymWhileSelectedAsPlanFilterFollowsThePromotedReplacement() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Berlin")
        createGym(app, name: "Frankfurt")
        app.buttons["Frankfurt"].tap()
        XCTAssertTrue(app.buttons["Frankfurt"].isSelected)

        app.tabBars.buttons["Pläne"].tap()
        let gymFilter = app.buttons["Gym-Filter"]
        XCTAssertTrue(gymFilter.waitForExistence(timeout: 5))
        gymFilter.tap()
        app.buttons["Frankfurt"].tap()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        app.buttons["Frankfurt"].swipeLeft()
        app.buttons["Löschen"].tap()
        XCTAssertTrue(app.buttons["Berlin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Berlin"].isSelected)

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()

        XCTAssertTrue(app.staticTexts["0 Übungen · Berlin"].waitForExistence(timeout: 5))
    }

    /// Activating a DIFFERENT, still-existing gym via Einstellungen → Gyms — not the new
    /// Pläne-tab picker, and not via deletion — must also update the Pläne-tab filter if it was
    /// already showing a gym before this happened. The filter derives live from the app-wide
    /// active gym rather than caching a snapshot that needs manual resyncing, so it can't drift
    /// regardless of which of the two switcher UIs was used.
    func testActivatingADifferentGymViaSettingsUpdatesAnAlreadyVisitedPlanFilter() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Berlin")
        createGym(app, name: "Frankfurt")
        app.buttons["Berlin"].tap()
        XCTAssertTrue(app.buttons["Berlin"].isSelected)

        // Visit Pläne once while Berlin is active — the filter picks it up.
        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()
        XCTAssertTrue(app.staticTexts["0 Übungen · Berlin"].waitForExistence(timeout: 5))

        // Switch the active gym via Einstellungen → Gyms, deliberately not via the Pläne-tab
        // picker, while the Pläne tab (already visited once) stays alive in the background.
        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        app.buttons["Frankfurt"].tap()
        XCTAssertTrue(app.buttons["Frankfurt"].isSelected)

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()
        XCTAssertTrue(app.staticTexts["0 Übungen · Frankfurt"].waitForExistence(timeout: 5))
    }

    /// A gym that becomes active only AFTER the Pläne tab's first-ever appearance (e.g. a new
    /// user visits Pläne before configuring any gym at all, then later creates and activates
    /// one) must still be picked up — the filter must never permanently lock onto "Alle" just
    /// because no gym happened to be active yet at that first appearance.
    func testActivatingAGymAfterFirstVisitingPlaneWithNoActiveGymUpdatesTheFilter() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        XCTAssertTrue(app.navigationBars.buttons["Plan hinzufügen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Berlin")
        app.buttons["Berlin"].tap()
        XCTAssertTrue(app.buttons["Berlin"].isSelected)

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()
        XCTAssertTrue(app.staticTexts["0 Übungen · Berlin"].waitForExistence(timeout: 5))
    }

    /// Independent of the list filter, a plan's gym must also be changeable after the fact from
    /// its own editor.
    func testAssigningAGymInThePlanEditorShowsItInThePlanList() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Frankfurt")

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))

        app.buttons["Gym"].tap()
        app.buttons["Frankfurt"].tap()
        app.buttons["BackButton"].tap()

        XCTAssertTrue(app.staticTexts["0 Übungen · Frankfurt"].waitForExistence(timeout: 5))
    }

    func testGymConversionFactorPersistsAfterEditing() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()

        app.navigationBars.buttons["Gym hinzufügen"].tap()
        let nameField = app.textFields["Gym-Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Kalibriertes Gym")

        let factorField = app.textFields["Umrechnungsfaktor"]
        XCTAssertTrue(factorField.exists)
        // Pre-filled with the default "1" — double-tap selects it (a single tap can leave the
        // cursor before the existing text rather than after it, so plain backspaces aren't
        // reliable here), so typing directly replaces it instead of appending to it.
        factorField.doubleTap()
        factorField.typeText("0.8")

        app.buttons["Sichern"].tap()
        let gymButton = app.buttons["Kalibriertes Gym"]
        XCTAssertTrue(gymButton.waitForExistence(timeout: 5))

        // "Bearbeiten" is a leading-edge swipe action — reveal it with swipeRight.
        gymButton.swipeRight()
        app.buttons["Bearbeiten"].tap()

        let reopenedFactorField = app.textFields["Umrechnungsfaktor"]
        XCTAssertTrue(reopenedFactorField.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedFactorField.value as? String, "0.8")
    }

    private func createGym(_ app: XCUIApplication, name: String) {
        app.navigationBars.buttons["Gym hinzufügen"].tap()
        let nameField = app.textFields["Gym-Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.buttons[name].waitForExistence(timeout: 5))
    }

    /// Unlocking developer mode (5× tap on the version number + correct password) reveals the
    /// "Entwicklermodus" section in Einstellungen that's hidden otherwise.
    func testUnlockingDeveloperModeViaVersionTapShowsDevModeSection() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        XCTAssertFalse(app.buttons["Entwicklermodus"].exists, "Dev mode section must be hidden before unlocking")

        unlockDeveloperMode(app)

        XCTAssertTrue(app.buttons["Entwicklermodus"].waitForExistence(timeout: 5))
    }

    func testWrongPasswordShowsErrorAndKeepsDeveloperModeOff() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        let versionButton = app.buttons["AppVersion"]
        XCTAssertTrue(versionButton.waitForExistence(timeout: 5))
        for _ in 0..<5 { versionButton.tap() }

        let passwordField = app.secureTextFields["Passwort"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText("falschesPasswort123")
        app.buttons["Bestätigen"].tap()

        XCTAssertTrue(app.staticTexts["Falsches Passwort."].waitForExistence(timeout: 5))

        app.buttons["Abbrechen"].tap()
        XCTAssertFalse(app.buttons["Entwicklermodus"].exists, "A wrong password must not activate developer mode")
    }

    func testSubmittingFeedbackViaThumbsDownCreatesEntryInDeveloperMode() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        unlockDeveloperMode(app)

        let feedbackButton = app.buttons["Feedback geben"]
        XCTAssertTrue(feedbackButton.waitForExistence(timeout: 5))
        feedbackButton.tap()

        XCTAssertTrue(app.navigationBars["Feedback senden"].waitForExistence(timeout: 5))
        let notesField = app.textViews["Feedback-Notiz"]
        XCTAssertTrue(notesField.waitForExistence(timeout: 5))
        notesField.tap()
        notesField.typeText("Testfeedback-Eintrag")
        app.buttons["Speichern"].tap()

        app.buttons["Entwicklermodus"].tap()
        XCTAssertTrue(app.staticTexts["Testfeedback-Eintrag"].waitForExistence(timeout: 5))
    }

    func testAddingATodoInDeveloperModeShowsItAndCanBeMarkedDone() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        unlockDeveloperMode(app)

        app.buttons["Entwicklermodus"].tap()
        XCTAssertTrue(app.navigationBars["Entwicklermodus"].waitForExistence(timeout: 5))

        app.buttons["Neues To-Do"].tap()
        let titleField = app.textFields["Titel"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Testaufgabe")
        app.buttons["Hinzufügen"].tap()

        XCTAssertTrue(app.staticTexts["Testaufgabe"].waitForExistence(timeout: 5))

        app.buttons["Als erledigt markieren"].tap()
        XCTAssertTrue(app.buttons["Als offen markieren"].waitForExistence(timeout: 5))
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
        // .searchable's search field. The row has no explicit .accessibilityIdentifier of its
        // own — it's found via the wrapping NavigationLink's auto-derived identifier — so query
        // by identifier across any element type instead of assuming a specific one.
        let newExerciseRow = app.descendants(matching: .any)["Meine Testübung"]
        var attempts = 0
        while !newExerciseRow.exists && attempts < 15 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(newExerciseRow.exists)
    }

    func testSwipingAnExerciseDeletesItFromTheLibrary() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Übungen"].tap()

        app.navigationBars.buttons["Übung hinzufügen"].tap()
        let nameField = app.textFields["Übungsname"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Löschbare Testübung")
        app.buttons["Sichern"].tap()

        let newExerciseRow = app.descendants(matching: .any)["Löschbare Testübung"]
        var attempts = 0
        while !newExerciseRow.exists && attempts < 15 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(newExerciseRow.exists)

        newExerciseRow.swipeLeft()
        app.buttons["Löschen"].tap()

        XCTAssertFalse(app.descendants(matching: .any)["Löschbare Testübung"].exists)
    }

    /// End-to-end: logging a real set, then setting a long-term goal above it shows the correct
    /// "Aktuell"/"Noch" progress text, and lowering the target to/below the logged best flips
    /// the row to "Ziel erreicht".
    func testExerciseGoalShowsProgressTowardLoggedBest() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        let weightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        weightField.typeText("80")
        let repsField = app.textFields["Satz 0 Wdh"]
        repsField.tap()
        repsField.typeText("10")
        app.navigationBars.firstMatch.tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Übungen"].tap()

        // The row resolves to two accessibility elements sharing the identifier "Bankdrücken"
        // (the real tappable NavigationLink row plus a non-hittable List-row backing element) —
        // same ambiguity class `tapHittableButton` already exists to resolve elsewhere.
        tapHittableButton(app, identifier: "Bankdrücken")

        let weightGoalField = app.textFields["Zielgewicht"]
        XCTAssertTrue(weightGoalField.waitForExistence(timeout: 5))
        weightGoalField.tap()
        weightGoalField.typeText("100")
        app.navigationBars.firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Aktuell: 80 kg"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Noch 20 kg"].waitForExistence(timeout: 5))

        let repsGoalField = app.textFields["Ziel-Wiederholungen"]
        XCTAssertTrue(repsGoalField.waitForExistence(timeout: 5))
        repsGoalField.tap()
        repsGoalField.typeText("15")
        app.navigationBars.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Aktuell: 10 Wdh."].waitForExistence(timeout: 5))

        // Lowering the target to/below the logged best should flip the row to "Ziel erreicht".
        weightGoalField.doubleTap()
        weightGoalField.typeText("70")
        app.navigationBars.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Ziel erreicht"].waitForExistence(timeout: 5))
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

    /// PlanExerciseEditView shares the same weight-field pattern as the rest of the app, but
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

    /// End-to-end: marking a plan-exercise unilateral changes the plan-editor summary,
    /// doubles the sets in the manual-start preview and the live session (alternating sides
    /// per set number, not all-left-then-all-right), and labels each row's field with its side.
    func testUnilateralExerciseAlternatesLeftAndRightSetLabels() {
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
        let unilateralToggle = app.switches["Einarmig/einseitig"]
        XCTAssertTrue(unilateralToggle.waitForExistence(timeout: 5))
        // Mirrors the documented pattern for this Toggle shape elsewhere in the suite: the
        // outer row-sized "Switch" element doesn't propagate a tap to the real inner control.
        unilateralToggle.switches.firstMatch.tap()
        app.buttons["Fertig"].tap()

        // Back in the plan editor, the row's combined accessibility label reflects "pro Seite".
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Bankdrücken"].label.contains("pro Seite"))

        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()

        // The manual-start preview already mirrors the doubled, alternating sides.
        XCTAssertTrue(app.staticTexts["Bankdrücken"].waitForExistence(timeout: 5))
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()

        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
        // The first two generated sets (order 0 and 1) are the first exercise's first left/right
        // pair — real identifiers are order-based, not side-based, so existence alone wouldn't
        // catch a broken alternation. Checking each Kennung's own accessibility label does.
        let firstKennung = app.staticTexts["Satz 0 Kennung"]
        XCTAssertTrue(firstKennung.waitForExistence(timeout: 5))
        XCTAssertEqual(firstKennung.label, "Satz 1 L, Links")
        let secondKennung = app.staticTexts["Satz 1 Kennung"]
        XCTAssertTrue(secondKennung.waitForExistence(timeout: 5))
        XCTAssertEqual(secondKennung.label, "Satz 1 R, Rechts")
        XCTAssertTrue(app.textFields["Satz 0 Gewicht"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Satz 1 Gewicht"].waitForExistence(timeout: 5))
    }

    func testGroupingTwoExercisesShowsASupersetIndicatorOnBoth() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))

        app.buttons["Übung hinzufügen"].tap()
        let bench = app.buttons["Bankdrücken"]
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        bench.tap()

        // ExercisePickerView's sheet ("Übung auswählen") can still be mid-dismiss-animation
        // right after tapping an exercise — its own row shares the exercise's identifier with
        // the row that's about to appear in the editor underneath, so waiting for that
        // identifier to merely *exist* doesn't prove the sheet is gone. Without waiting for
        // the sheet itself to disappear first, re-tapping "Übung hinzufügen" for the second
        // exercise can land back inside the still-open first sheet instead of opening a fresh
        // one — confirmed via an accessibility-tree diagnostic dump that caught the picker's
        // full exercise list still on screen well after this point.
        waitForDisappearance(app.navigationBars["Übung auswählen"])

        app.buttons["Übung hinzufügen"].tap()
        // "Rudern vorgebeugt" sits in the picker's "Rücken" section, off-screen without
        // scrolling — tap() auto-scrolls to it, but that path resolved an invalid hit point in
        // this List (same flavor of issue seen on the "Gruppieren" toolbar button elsewhere in
        // this ticket), so the tap silently missed and the sheet never dismissed. Filtering via
        // the picker's own search field instead keeps the target row on-screen without needing
        // any scroll.
        let searchField = app.searchFields["Übung suchen"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Rudern vorgebeugt")
        let row = app.buttons["Rudern vorgebeugt"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        waitForDisappearance(app.navigationBars["Übung auswählen"])

        // The editor's @Query refresh (now showing 2 rows, which is what un-disables
        // "Gruppieren" — it's disabled below 2 exercises) isn't instantaneous either. Without
        // this wait, the next lookup below can find "Gruppieren" already *existing* but still
        // disabled from when there was only 1 exercise, and tapping a disabled button is a
        // silent no-op.
        XCTAssertTrue(app.buttons["Rudern vorgebeugt"].waitForExistence(timeout: 5))

        let groupButton = app.navigationBars.buttons["Gruppieren"]
        XCTAssertTrue(groupButton.waitForExistence(timeout: 5))
        groupButton.tap()

        // In grouping mode, each row's identifier matches two accessibility elements: the
        // real, tappable row button, and a non-hittable backing element the List/Form row
        // infrastructure adds alongside it (confirmed via a diagnostic dump — same identifier,
        // different combined label, isHittable=false on the decoy). tapHittableButton picks
        // the one that's actually tappable instead of failing on the ambiguity.
        tapHittableButton(app, identifier: "Bankdrücken")
        tapHittableButton(app, identifier: "Rudern vorgebeugt")

        app.navigationBars.buttons["Fertig"].tap()

        // ExerciseRow/PlanExerciseRow combine their child text into the enclosing button's
        // label (`.accessibilityElement(children: .combine)`), so the superset caption shows
        // up as part of each row button's own label rather than as a separate static text.
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Bankdrücken"].label.contains("Superset"))
        XCTAssertTrue(app.buttons["Rudern vorgebeugt"].label.contains("Superset"))
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

    func testCreatingPlanFromTemplatePrefillsNameAndExercises() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Aus Vorlage erstellen"].tap()

        let pushTemplate = app.buttons["Push"]
        XCTAssertTrue(pushTemplate.waitForExistence(timeout: 5))
        pushTemplate.tap()

        // Selecting a template creates the plan and navigates straight into its editor,
        // pre-named after the template and with its exercises already added.
        let nameField = app.textFields["Planname"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Push")
        XCTAssertTrue(app.buttons["Bankdrücken"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Schulterdrücken"].waitForExistence(timeout: 5))
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

    /// The system Share Sheet and Files document picker are separate OS processes that aren't
    /// reliably driveable from XCUITest across simulator/OS versions, so this only confirms the
    /// entry points render and are tappable without crashing — the actual JSON encode/decode/
    /// matching logic is covered exhaustively by PlanExportImportTests instead.
    func testExportAndImportEntryPointsAreAvailable() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        XCTAssertTrue(app.navigationBars.buttons["Plan importieren"].waitForExistence(timeout: 5))

        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()

        let planRow = app.staticTexts["Neuer Plan"]
        XCTAssertTrue(planRow.waitForExistence(timeout: 5))
        planRow.swipeRight()
        XCTAssertTrue(app.buttons["Exportieren"].waitForExistence(timeout: 5))
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

        // Start it from the Training tab, via the manual-start preview.
        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()

        // The workout screen should show the exercise's pre-filled sets and a way to end it.
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bankdrücken"].waitForExistence(timeout: 5))

        // Regression test: typing a multi-digit weight must not corrupt the value via a
        // get/set round-trip through the live text field. Checked after EVERY keystroke, not
        // just the final value, since a mid-typing corruption could theoretically self-correct
        // by the last character.
        let weightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        typeAndCheckEachKeystroke(weightField, "55")
        app.navigationBars.firstMatch.tap()

        // Filling in reps too now auto-completes the row — check the row's own swipe-action
        // state reflects that instead of assuming ending the workout skips the incomplete-sets
        // alert outright (the other 2 default sets are still empty).
        let repsField = app.textFields["Satz 0 Wdh"]
        repsField.tap()
        repsField.typeText("10")
        app.navigationBars.firstMatch.tap()

        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        XCTAssertTrue(app.buttons["Nicht erledigt"].waitForExistence(timeout: 5), "Satz 0 should already be auto-completed after weight+reps were both entered")
    }

    func testStartingAWorkoutFromAPlanWithGroupedExercisesShowsTheSupersetCaption() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))

        app.buttons["Übung hinzufügen"].tap()
        let bench = app.buttons["Bankdrücken"]
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        bench.tap()

        // See the comment on the equivalent wait in
        // testGroupingTwoExercisesShowsASupersetIndicatorOnBoth for why this is needed before
        // re-opening the picker for the second exercise.
        waitForDisappearance(app.navigationBars["Übung auswählen"])

        app.buttons["Übung hinzufügen"].tap()
        // See the comment on the equivalent search-field step in
        // testGroupingTwoExercisesShowsASupersetIndicatorOnBoth for why searching instead of
        // scrolling is needed for this specific row.
        let searchField = app.searchFields["Übung suchen"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Rudern vorgebeugt")
        let row = app.buttons["Rudern vorgebeugt"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        waitForDisappearance(app.navigationBars["Übung auswählen"])

        // See the comment on the equivalent wait in
        // testGroupingTwoExercisesShowsASupersetIndicatorOnBoth — without it, "Gruppieren" can
        // be found while still disabled from when the list had only 1 exercise, and tapping a
        // disabled button silently does nothing.
        XCTAssertTrue(app.buttons["Rudern vorgebeugt"].waitForExistence(timeout: 5))

        app.navigationBars.buttons["Gruppieren"].tap()

        // See the comment on the equivalent step in
        // testGroupingTwoExercisesShowsASupersetIndicatorOnBoth for why tapHittableButton is
        // needed here instead of a plain app.buttons[identifier] lookup.
        tapHittableButton(app, identifier: "Bankdrücken")
        tapHittableButton(app, identifier: "Rudern vorgebeugt")

        app.navigationBars.buttons["Fertig"].tap()

        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()

        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
        // The grouping made at plan-editing time must carry through into the active session.
        XCTAssertTrue(app.staticTexts["🔗 Superset mit Rudern vorgebeugt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["🔗 Superset mit Bankdrücken"].waitForExistence(timeout: 5))
    }

    /// The preview must show the plan's exercises with a "Training starten" confirm button —
    /// and, critically, no session must exist yet at this point (no "Beenden" button).
    func testManualStartPreviewShowsPlanBeforeSessionIsCreated() {
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

        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()

        XCTAssertTrue(app.staticTexts["Bankdrücken"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Training starten"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars.buttons["Beenden"].exists, "No session should exist until 'Training starten' is tapped")
    }

    /// Backing out of the manual-start preview (without tapping "Training starten") must leave
    /// no trace — no session created, still offered to start the same plan afterward.
    func testBackingOutOfManualStartPreviewCreatesNoSession() {
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

        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        XCTAssertTrue(app.buttons["Training starten"].waitForExistence(timeout: 5))

        app.buttons["BackButton"].tap()

        // No session was created — the Training tab still offers to start the plan, not resume one.
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars.buttons["Beenden"].exists)
    }

    /// A fresh session's ghost weight shows as a placeholder derived from history, and typing
    /// only reps (never touching weight) silently fills weight from that same ghost value —
    /// proven indirectly via auto-completion, since a placeholder-only field still isn't real.
    func testGhostWeightIsShownAsPlaceholderAndAutofillsOnceRepsAreEntered() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // SetSuggestion.suggest is only ever consulted when there's an active gym
        // (gym.flatMap { ... } in both WorkoutSessionBuilder and PlanStartView) — without one,
        // the ghost value falls back to the plan's own (here: unset) target instead of history.
        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Testgym")
        let gymButton = app.buttons["Testgym"]
        XCTAssertTrue(gymButton.waitForExistence(timeout: 5))
        gymButton.tap()
        XCTAssertTrue(gymButton.isSelected)

        startWorkoutFromFreshPlan(app)

        // Log a real weight/reps so the next session for the same exercise has history to
        // suggest from.
        let weightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        weightField.typeText("70")
        let repsField = app.textFields["Satz 0 Wdh"]
        repsField.tap()
        repsField.typeText("8")
        app.navigationBars.firstMatch.tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        // Start a fresh session for the same plan — its first set should ghost-suggest 70 kg.
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))

        let newWeightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(newWeightField.waitForExistence(timeout: 5))
        // An untouched field renders its ghost suggestion as the native (dimmed) placeholder —
        // XCUITest reads a placeholder-only TextField's value as that placeholder text.
        XCTAssertEqual(newWeightField.value as? String, "70.0")

        // Typing only reps must silently fill the weight from that same ghost value.
        let newRepsField = app.textFields["Satz 0 Wdh"]
        newRepsField.tap()
        newRepsField.typeText("8")
        app.navigationBars.firstMatch.tap()

        // Proof the weight became a REAL value (not just still showing the placeholder): check
        // the row's own swipe-action state instead of assuming the whole-workout end flow
        // skips the incomplete-sets alert outright (the other 2 default sets are still empty).
        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        XCTAssertTrue(app.buttons["Nicht erledigt"].waitForExistence(timeout: 5), "Satz 0 should already be auto-completed after the ghost weight silently filled in")
    }

    /// Regression: an explicit "0" the user actually typed must never be silently overwritten
    /// by a later ghost-to-real autofill — only a genuinely untouched field may be autofilled.
    func testExplicitZeroWeightIsNotOverwrittenByGhostAutofill() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // SetSuggestion.suggest is only ever consulted when there's an active gym — without
        // one, there's no real ghost value to guard against in the first place.
        app.tabBars.buttons["Einstellungen"].tap()
        app.staticTexts["Gyms"].tap()
        createGym(app, name: "Testgym")
        let gymButton = app.buttons["Testgym"]
        XCTAssertTrue(gymButton.waitForExistence(timeout: 5))
        gymButton.tap()
        XCTAssertTrue(gymButton.isSelected)

        startWorkoutFromFreshPlan(app)

        // Log real history first so the next session has a non-zero ghost weight that a broken
        // guard could otherwise use to silently overwrite the explicit "0" below.
        let firstWeightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(firstWeightField.waitForExistence(timeout: 5))
        firstWeightField.tap()
        firstWeightField.typeText("60")
        let firstRepsField = app.textFields["Satz 0 Wdh"]
        firstRepsField.tap()
        firstRepsField.typeText("10")
        app.navigationBars.firstMatch.tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))

        let weightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        weightField.typeText("0")

        let repsField = app.textFields["Satz 0 Wdh"]
        repsField.tap()
        repsField.typeText("12")
        app.navigationBars.firstMatch.tap()

        XCTAssertEqual(weightField.value as? String, "0")
    }

    /// The Gesamt-/Übungsansicht toggle only appears once there's more than one exercise, and
    /// switching to Übungsansicht focuses one exercise at a time with prev/next navigation.
    func testSwitchingToUebungsansichtShowsFocusedExerciseWithNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        app.tabBars.buttons["Pläne"].tap()
        app.navigationBars.buttons["Plan hinzufügen"].tap()
        XCTAssertTrue(app.textFields["Planname"].waitForExistence(timeout: 5))
        app.buttons["Übung hinzufügen"].tap()
        let bench = app.buttons["Bankdrücken"]
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        bench.tap()
        waitForDisappearance(app.navigationBars["Übung auswählen"])

        app.buttons["Übung hinzufügen"].tap()
        let searchField = app.searchFields["Übung suchen"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Kniebeugen")
        let squats = app.buttons["Kniebeugen"]
        XCTAssertTrue(squats.waitForExistence(timeout: 5))
        squats.tap()
        waitForDisappearance(app.navigationBars["Übung auswählen"])
        XCTAssertTrue(app.buttons["Kniebeugen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Training"].tap()
        let startPlanButton = app.buttons["Neuer Plan"]
        XCTAssertTrue(startPlanButton.waitForExistence(timeout: 5))
        startPlanButton.tap()
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))

        // With 2 exercises, the view-mode toggle should appear.
        let viewToggle = app.segmentedControls["Ansicht-Umschalter"]
        XCTAssertTrue(viewToggle.waitForExistence(timeout: 5))
        viewToggle.buttons["Übungsansicht"].tap()

        // Not asserting a specific element type here — an HStack container's accessibility
        // type as bridged to XCUITest isn't guaranteed (e.g. "Übungsansicht-Kopf" wraps two
        // real Buttons, which can shift how the container itself gets categorized).
        XCTAssertTrue(app.descendants(matching: .any)["Übungsansicht-Kopf"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bankdrücken"].waitForExistence(timeout: 5))

        app.buttons["Nächste Übung"].tap()
        XCTAssertTrue(app.staticTexts["Kniebeugen"].waitForExistence(timeout: 5))
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

    /// If every set auto-completed (real weight + reps entered), ending must not interrupt
    /// with a prompt at all.
    func testEndingWorkoutWithAllSetsCompletedSkipsPrompt() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // The exercise defaults to 3 target sets (no history yet, PlanExerciseDefaults
        // fallback) — fill weight and reps on each so all three auto-complete.
        for order in 0..<3 {
            let weightField = app.textFields["Satz \(order) Gewicht"]
            XCTAssertTrue(weightField.waitForExistence(timeout: 5))
            weightField.tap()
            weightField.typeText("50")
            let repsField = app.textFields["Satz \(order) Wdh"]
            repsField.tap()
            repsField.typeText("10")
            app.navigationBars.firstMatch.tap()
        }

        app.navigationBars.buttons["Beenden"].tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))
    }

    /// A leading-edge swipe action toggles "Erledigt" manually, independent of the
    /// weight-and-reps auto-completion rule — and toggling again flips it back, proving the
    /// state genuinely changes rather than the button label being static.
    func testSwipingASetTogglesErledigtManually() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        let markDoneButton = app.buttons["Erledigt"]
        XCTAssertTrue(markDoneButton.waitForExistence(timeout: 5))
        markDoneButton.tap()

        // Toggling back must offer "Nicht erledigt" instead, proving the state actually flipped.
        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        let markUndoneButton = app.buttons["Nicht erledigt"]
        XCTAssertTrue(markUndoneButton.waitForExistence(timeout: 5))
        markUndoneButton.tap()

        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        XCTAssertTrue(app.buttons["Erledigt"].waitForExistence(timeout: 5))
    }

    /// The completion circle at the right edge of a set row must itself be tappable (not just
    /// reachable via the leading swipe action) — and tapping it again must flip it back, proving
    /// the tap genuinely toggles state instead of only ever marking a set done.
    func testTappingTheCompletionCircleTogglesErledigt() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        let toggle = app.buttons["Satz 0 Erledigt"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.label, "Satz 1, nicht erledigt")

        // Uses the same hittable-candidate-filtering tap helper as every other button in a
        // swipeable row (see tapHittableButton's doc comment) rather than a bare .tap(), since
        // this button lives in the same row as "Satz 0 Gewicht", which is documented elsewhere
        // to need that defense against ambiguous duplicate accessibility elements.
        tapHittableButton(app, identifier: "Satz 0 Erledigt")
        XCTAssertEqual(toggle.label, "Satz 1, erledigt")

        tapHittableButton(app, identifier: "Satz 0 Erledigt")
        XCTAssertEqual(toggle.label, "Satz 1, nicht erledigt")
    }

    /// Regression: once a set's completion is manually overridden via swipe, any later edit to
    /// an unrelated field (e.g. a typo fix in reps) must not silently recompute isCompleted
    /// from the auto rule and discard that manual decision.
    func testManualErledigtOverrideSurvivesAnUnrelatedFieldEdit() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // Manually mark Satz 0 done via swipe while it's still fully empty (e.g. a bodyweight set).
        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        let markDoneButton = app.buttons["Erledigt"]
        XCTAssertTrue(markDoneButton.waitForExistence(timeout: 5))
        markDoneButton.tap()

        // Now edit an unrelated field (reps) — must not silently flip completion back off.
        let repsField = app.textFields["Satz 0 Wdh"]
        XCTAssertTrue(repsField.waitForExistence(timeout: 5))
        repsField.tap()
        repsField.typeText("5")
        app.navigationBars.firstMatch.tap()

        // The manual override must still hold — checked via the row's own swipe-action state
        // rather than the whole-workout end flow (the other 2 default sets are still empty,
        // so ending would prompt regardless of Satz 0's own completion state).
        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        XCTAssertTrue(app.buttons["Nicht erledigt"].waitForExistence(timeout: 5), "The manual 'Erledigt' override must survive an unrelated field edit")
    }

    /// The ticket's own stated motivation, chained end-to-end: a set marked done via the quick
    /// swipe action must be just as "done" to the end-of-workout flow as an auto-completed one
    /// — i.e. "Beenden" must not treat it as incomplete and silently discard it.
    func testEndingWorkoutAfterMarkingAllSetsErledigtViaSwipeSkipsPrompt() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        for order in 0..<3 {
            swipeHittableElement(app, identifier: "Satz \(order) Gewicht", right: true)
            let markDoneButton = app.buttons["Erledigt"]
            XCTAssertTrue(markDoneButton.waitForExistence(timeout: 5))
            markDoneButton.tap()
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
        let weightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        typeAndCheckEachKeystroke(weightField, "100")
        app.navigationBars.firstMatch.tap()

        // Adding a warmup inserts it BEFORE the working set, so the working set's
        // identifier shifts from "Satz 0" to "Satz 1".
        app.buttons["Aufwärmsatz"].tap()
        let warmupWeightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(warmupWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(warmupWeightField.value as? String, "50.0", "A single warmup should default to 50% of the 100 kg working weight")

        // The working row's own SwiftUI view identity never changed (only its Kennung/order
        // shifted) — its @State-held typed text survives untouched as the raw "100" it was
        // typed as, not reformatted, since the row was never actually remounted.
        let shiftedWeightField = app.textFields["Satz 1 Gewicht"]
        XCTAssertTrue(shiftedWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(shiftedWeightField.value as? String, "100")

        // Delete the warmup via swipe-to-delete (the system-provided trailing action).
        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: false)
        app.buttons["Delete"].tap()

        // The working set's own weight must be completely untouched by the warmup's removal —
        // this app has never reindexed remaining sets after a delete, so it keeps its shifted
        // "Satz 1" identifier rather than moving back to "Satz 0".
        XCTAssertTrue(shiftedWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(shiftedWeightField.value as? String, "100")
    }

    func testAddingAndRemovingDropsetNeverChangesWorkingSetWeight() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // Dropsets drop from the LAST set of the exercise, so give Satz 2 — not Satz 0 — a
        // known weight, so the suggestion is checkable regardless of the other two sets.
        let workingWeightField = app.textFields["Satz 2 Gewicht"]
        XCTAssertTrue(workingWeightField.waitForExistence(timeout: 5))
        workingWeightField.tap()
        typeAndCheckEachKeystroke(workingWeightField, "100")
        app.navigationBars.firstMatch.tap()

        // Dropsets are logged after the set they drop from, so the three original sets keep
        // their identifiers and the new dropset appears as "Satz 3".
        app.buttons["Dropsatz"].tap()
        let dropsetWeightField = app.textFields["Satz 3 Gewicht"]
        XCTAssertTrue(dropsetWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(dropsetWeightField.value as? String, "80.0", "A dropset should default to 80% of the 100 kg set it drops from")
        XCTAssertFalse(app.textFields["Satz 4 Gewicht"].exists, "Tapping 'Dropsatz' once must create exactly one new set")

        // Delete the dropset via swipe-to-delete.
        swipeHittableElement(app, identifier: "Satz 3 Gewicht", right: false)
        app.buttons["Delete"].tap()

        // The set it dropped from must be completely untouched by the dropset's removal —
        // same reasoning as the warmup test: this row was never remounted, so its raw typed
        // text survives unformatted.
        XCTAssertTrue(workingWeightField.waitForExistence(timeout: 5))
        XCTAssertEqual(workingWeightField.value as? String, "100")
    }

    func testCompletingAWorkoutShowsStatistics() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // End the workout regardless of whether the default 3 target sets are all filled in —
        // marking just Satz 0 done via the manual swipe override (weight/reps stay at 0,
        // mirroring a real "logged but no weight tracked" scenario) is enough for the session
        // to be eligible.
        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        let markDoneButton = app.buttons["Erledigt"]
        XCTAssertTrue(markDoneButton.waitForExistence(timeout: 5))
        markDoneButton.tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Statistik"].tap()
        XCTAssertTrue(app.staticTexts["Ø Trainingsdauer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ø Trainings / Woche"].waitForExistence(timeout: 5))
        // The one exercise trained shows up in "Häufigste Übungen" with a session count of 1.
        XCTAssertTrue(app.staticTexts["Bankdrücken"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1×"].waitForExistence(timeout: 5))

        // Volume-over-time chart section: header, exercise picker, and the chart itself
        // (queried by its accessibility label, since Swift Charts marks aren't individually
        // exposed as static text elements).
        XCTAssertTrue(app.staticTexts["Trainingsvolumen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Übung, Gesamt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["Trainingsvolumen über Zeit"].waitForExistence(timeout: 5))
    }

    func testCompletingAWorkingSetShowsAPersonalRecordEstimate() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        // Give the working set a known weight so the estimated 1RM is checkable. The default
        // plan's target reps is 10 (PlanExerciseDefaults.fallbackReps).
        let weightField = app.textFields["Satz 0 Gewicht"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        typeAndCheckEachKeystroke(weightField, "100")
        let repsField = app.textFields["Satz 0 Wdh"]
        repsField.tap()
        repsField.typeText("10")
        app.navigationBars.firstMatch.tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Statistik"].tap()
        XCTAssertTrue(app.staticTexts["Bestleistungen (geschätztes 1RM)"].waitForExistence(timeout: 5))
        // Epley formula: 100 * (1 + 10/30) ≈ 133 kg.
        XCTAssertTrue(app.staticTexts["≈ 133 kg"].waitForExistence(timeout: 5))
    }

    func testRepeatingLastWorkoutStartsAFreshSessionWithTheSameExercise() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        startWorkoutFromFreshPlan(app)

        swipeHittableElement(app, identifier: "Satz 0 Gewicht", right: true)
        let markDoneButton = app.buttons["Erledigt"]
        XCTAssertTrue(markDoneButton.waitForExistence(timeout: 5))
        markDoneButton.tap()

        app.navigationBars.buttons["Beenden"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Entfernen & Beenden"].tap()
        }
        XCTAssertTrue(app.buttons["Neuer Plan"].waitForExistence(timeout: 5))

        let repeatButton = app.buttons["Letztes Training wiederholen"]
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 5))
        repeatButton.tap()

        // Repeating also goes through the manual-start preview, same as starting a plan fresh.
        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()

        // Lands directly on a fresh, uncompleted session carrying over the same exercise.
        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Satz 0 Gewicht"].waitForExistence(timeout: 5))
    }

    /// Builds a one-exercise plan and starts a workout from it (via the manual-start
    /// preview), landing on WorkoutSessionView.
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

        let confirmStart = app.buttons["Training starten"]
        XCTAssertTrue(confirmStart.waitForExistence(timeout: 5))
        confirmStart.tap()

        XCTAssertTrue(app.navigationBars.buttons["Beenden"].waitForExistence(timeout: 5))
    }

    /// Drives the 5×-tap-on-version → correct-password flow shared by every developer-mode
    /// test — assumes the Einstellungen tab isn't already showing a presented sheet.
    private func unlockDeveloperMode(_ app: XCUIApplication) {
        app.tabBars.buttons["Einstellungen"].tap()
        let versionButton = app.buttons["AppVersion"]
        XCTAssertTrue(versionButton.waitForExistence(timeout: 5))
        for _ in 0..<5 { versionButton.tap() }

        let passwordField = app.secureTextFields["Passwort"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText("Isg#45krusgL.")
        app.buttons["Bestätigen"].tap()
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

    /// Some rows (e.g. PlanEditorView's exercise rows in grouping mode) resolve to two
    /// accessibility elements sharing the same identifier — the real, tappable row button and
    /// a non-hittable backing element the List/Form row infrastructure adds alongside it.
    /// `app.buttons[identifier]` fails on that ambiguity; this picks the hittable one, polling
    /// briefly in case the row hasn't finished settling yet.
    private func tapHittableButton(_ app: XCUIApplication, identifier: String) {
        let matches = app.buttons.matching(identifier: identifier)
        var hittableCandidates: [XCUIElement] = []
        var attempts = 0
        while hittableCandidates.isEmpty && attempts < 25 {
            hittableCandidates = (0..<matches.count).map { matches.element(boundBy: $0) }.filter { $0.isHittable }
            if hittableCandidates.isEmpty {
                usleep(200_000)
                attempts += 1
            }
        }
        guard let hittable = hittableCandidates.first else {
            XCTFail("No hittable element with identifier '\(identifier)' found among \(matches.count) match(es)")
            return
        }
        // More than one hittable match means there's no way to tell which one is the intended
        // target — picking the first anyway would silently mask a real ambiguity (e.g. the
        // same exercise added to a plan twice) instead of failing loudly.
        guard hittableCandidates.count == 1 else {
            XCTFail("\(hittableCandidates.count) hittable elements with identifier '\(identifier)' found — ambiguous, expected exactly 1")
            return
        }
        hittable.tap()
    }

    /// Same ambiguity as `tapHittableButton`, but for swiping a set row: with several
    /// independently-interactive TextFields per row and no row-level identifier of its own
    /// (see the comment in WorkoutSessionView), the weight field's identifier is reused as the
    /// row's address for swipe actions, and resolves to more than one accessibility element
    /// the same way.
    private func swipeHittableElement(_ app: XCUIApplication, identifier: String, right: Bool) {
        let matches = app.descendants(matching: .any).matching(identifier: identifier)
        var hittableCandidates: [XCUIElement] = []
        var attempts = 0
        while hittableCandidates.isEmpty && attempts < 25 {
            hittableCandidates = (0..<matches.count).map { matches.element(boundBy: $0) }.filter { $0.isHittable }
            if hittableCandidates.isEmpty {
                usleep(200_000)
                attempts += 1
            }
        }
        guard let hittable = hittableCandidates.first else {
            XCTFail("No hittable element with identifier '\(identifier)' found among \(matches.count) match(es)")
            return
        }
        if right {
            hittable.swipeRight()
        } else {
            hittable.swipeLeft()
        }
    }

    /// Waits for `element` to leave the accessibility tree. Needed after dismissing
    /// ExercisePickerView's sheet: its `NavigationStack` title bar ("Übung auswählen") can
    /// briefly still exist while the sheet animates away, and picking a second exercise right
    /// after the first (tapping "Übung hinzufügen" again) can otherwise re-tap into the still-
    /// closing sheet instead of the editor underneath — the two "Übung hinzufügen" identifiers
    /// aren't ambiguous, but the *timing* is: without this wait, the whole "add exercise" flow
    /// silently repeats inside the not-yet-dismissed sheet instead of adding a second exercise.
    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed)
    }
}
