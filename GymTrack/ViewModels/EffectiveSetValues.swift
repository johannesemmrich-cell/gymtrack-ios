import Foundation

extension SetEntry {
    /// The weight/reps to use when *deriving something else* from this set (e.g. the next
    /// warmup/dropset suggestion) — the real logged value once entered, otherwise the ghost
    /// hint shown as its placeholder, otherwise 0. Lets suggestion chains behave sensibly even
    /// before the user has typed anything into a set that's still showing only its ghost value.
    var effectiveWeight: Double { weight != 0 ? weight : (suggestedWeight ?? 0) }
    var effectiveReps: Int { reps != 0 ? reps : (suggestedReps ?? 0) }
}
