import Foundation

/// Converts a weight logged at one gym into its equivalent at another, using each gym's
/// `weightConversionFactor` (optionally overridden per exercise via `ExerciseGymNote`), so
/// stats/PRs can compare lifts across gyms with differently calibrated equipment. Pure math,
/// independent of any set history — a gym with no logged sets still has a well-defined factor
/// (its default of 1.0, or whatever the user set), so conversion always works.
enum GymConversion {
    /// The factor that actually applies for one (Exercise, Gym) pair: the per-exercise
    /// override if set, otherwise the gym's own global factor.
    static func effectiveFactor(gymFactor: Double, exerciseOverride: Double?) -> Double {
        exerciseOverride ?? gymFactor
    }

    /// Converts `weight` from a gym with `fromFactor` into the equivalent at a gym with
    /// `toFactor`. A non-positive factor (0 or negative) is never meaningful — treated as 1.0
    /// ("no conversion") on either side, rather than dividing by zero or silently zeroing out
    /// a converted weight. Defends against bad data reaching here (e.g. a future import) even
    /// though write paths already clamp factors to be positive before persisting them.
    static func convert(_ weight: Double, fromFactor: Double, toFactor: Double) -> Double {
        let safeFromFactor = fromFactor > 0 ? fromFactor : 1.0
        let safeToFactor = toFactor > 0 ? toFactor : 1.0
        return weight * safeFromFactor / safeToFactor
    }
}
