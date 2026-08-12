import XCTest
@testable import GymTrack

final class GymConversionTests: XCTestCase {

    // MARK: effectiveFactor

    func testEffectiveFactorUsesExerciseOverrideWhenPresent() {
        let result = GymConversion.effectiveFactor(gymFactor: 1.0, exerciseOverride: 0.8)
        XCTAssertEqual(result, 0.8)
    }

    func testEffectiveFactorFallsBackToGymFactorWhenNoOverride() {
        let result = GymConversion.effectiveFactor(gymFactor: 1.2, exerciseOverride: nil)
        XCTAssertEqual(result, 1.2)
    }

    // MARK: convert

    func testConvertWithEqualFactorsLeavesWeightUnchanged() {
        let result = GymConversion.convert(60, fromFactor: 1.0, toFactor: 1.0)
        XCTAssertEqual(result, 60)
    }

    func testConvertScalesWeightByRatioOfFactors() {
        // Gym A's machine is calibrated at 0.8, Gym B's (the reference) at 1.0 — a 60kg lift
        // at A should read as the equivalent of 48kg at B.
        let result = GymConversion.convert(60, fromFactor: 0.8, toFactor: 1.0)
        XCTAssertEqual(result, 48, accuracy: 0.0001)
    }

    func testConvertIsSymmetric() {
        let toB = GymConversion.convert(60, fromFactor: 0.8, toFactor: 1.0)
        let backToA = GymConversion.convert(toB, fromFactor: 1.0, toFactor: 0.8)
        XCTAssertEqual(backToA, 60, accuracy: 0.0001)
    }

    func testConvertWithZeroTargetFactorReturnsOriginalWeightRatherThanCrashOrInfinity() {
        let result = GymConversion.convert(60, fromFactor: 1.0, toFactor: 0)
        XCTAssertEqual(result, 60)
    }

    func testConvertWithZeroSourceFactorTreatsItAsNoConversionRatherThanZeroingOutTheWeight() {
        // A stored factor of 0 must never silently zero out every historical weight it's
        // applied to — treated as 1.0 (no conversion) instead, same as an unset factor would be.
        let result = GymConversion.convert(60, fromFactor: 0, toFactor: 1.0)
        XCTAssertEqual(result, 60)
    }

    func testConvertWithNegativeSourceFactorTreatsItAsNoConversion() {
        let result = GymConversion.convert(60, fromFactor: -0.5, toFactor: 1.0)
        XCTAssertEqual(result, 60)
    }

    func testConvertWithZeroWeightStaysZero() {
        let result = GymConversion.convert(0, fromFactor: 0.8, toFactor: 1.0)
        XCTAssertEqual(result, 0)
    }

    // MARK: Gym without history — the conversion never depends on set history at all

    func testConvertingForAGymWithNoLoggedSetsStillWorksUsingItsDefaultFactor() {
        let freshGym = Gym(name: "Neues Gym")
        XCTAssertEqual(freshGym.weightConversionFactor, 1.0, "New gyms default to no conversion")

        let result = GymConversion.convert(60, fromFactor: freshGym.weightConversionFactor, toFactor: 1.0)

        XCTAssertEqual(result, 60)
    }
}
