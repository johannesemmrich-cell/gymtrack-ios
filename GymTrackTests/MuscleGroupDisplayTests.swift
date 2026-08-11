import XCTest
@testable import GymTrack

final class MuscleGroupDisplayTests: XCTestCase {

    func testEveryMuscleGroupHasANonEmptyDisplayName() {
        for group in MuscleGroup.allCases {
            XCTAssertFalse(group.displayName.isEmpty, "\(group) is missing a display name")
        }
    }

    func testDisplayNamesAreUniquePerMuscleGroup() {
        let names = MuscleGroup.allCases.map(\.displayName)
        XCTAssertEqual(names.count, Set(names).count, "Two muscle groups must not share the same display name")
    }
}
