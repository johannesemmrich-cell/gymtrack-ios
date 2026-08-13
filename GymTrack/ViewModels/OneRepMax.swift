import Foundation

/// Estimates a one-rep max from a completed set using the Epley formula.
enum OneRepMax {
    /// A single rep already IS the 1RM — no estimation needed. Undefined (0) for non-positive
    /// weight or reps, since there's no meaningful max to estimate from a set that was never
    /// actually performed.
    static func estimate(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
}
