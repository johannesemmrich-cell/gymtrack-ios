import XCTest
@testable import GymTrack

final class GymActivationTests: XCTestCase {

    func testActivatingGymDeactivatesOthers() {
        let a = Gym(name: "Heimat-Gym", isActive: true)
        let b = Gym(name: "Frankfurt", isActive: false)
        let c = Gym(name: "Berlin", isActive: false)

        GymActivation.activate(b, among: [a, b, c])

        XCTAssertFalse(a.isActive)
        XCTAssertTrue(b.isActive)
        XCTAssertFalse(c.isActive)
    }

    func testActivatingAlreadyActiveGymStaysActiveAndOthersStayInactive() {
        let a = Gym(name: "Heimat-Gym", isActive: true)
        let b = Gym(name: "Frankfurt", isActive: false)

        GymActivation.activate(a, among: [a, b])

        XCTAssertTrue(a.isActive)
        XCTAssertFalse(b.isActive)
    }

    func testActivatingOnlyGymInList() {
        let a = Gym(name: "Heimat-Gym", isActive: false)
        GymActivation.activate(a, among: [a])
        XCTAssertTrue(a.isActive)
    }

    func testActivatingWithEmptyListDoesNothingAndDoesNotCrash() {
        let a = Gym(name: "Heimat-Gym", isActive: false)
        GymActivation.activate(a, among: [])
        XCTAssertFalse(a.isActive, "The target gym itself is not in the list, so nothing should change")
    }

    func testActivatingGymNotPresentInListDeactivatesAllListedGyms() {
        let a = Gym(name: "Heimat-Gym", isActive: true)
        let b = Gym(name: "Frankfurt", isActive: false)
        let outsider = Gym(name: "Nicht in der Liste", isActive: false)

        GymActivation.activate(outsider, among: [a, b])

        XCTAssertFalse(a.isActive)
        XCTAssertFalse(b.isActive)
    }

    func testActivatingWithMultipleAlreadyActiveGymsCorrectsToExactlyOne() {
        // Defensive case: data shouldn't get here, but if two gyms were ever both
        // marked active, activating a third must still leave exactly one active.
        let a = Gym(name: "Heimat-Gym", isActive: true)
        let b = Gym(name: "Frankfurt", isActive: true)
        let c = Gym(name: "Berlin", isActive: false)

        GymActivation.activate(c, among: [a, b, c])

        XCTAssertFalse(a.isActive)
        XCTAssertFalse(b.isActive)
        XCTAssertTrue(c.isActive)
    }
}
