import Foundation

/// Positions a newly-created warmup set immediately before the first `.normal` set of the
/// same exercise, leaving every other set's relative order untouched. Pure array
/// rearrangement only — the caller still needs SetEntryOrdering.reindex(_:) to persist the
/// new `.order` values, and neither step ever touches weight/reps/note/isCompleted.
enum WarmupSetInsertion {
    static func insert(_ newWarmup: SetEntry, into allSets: [SetEntry], forExerciseID exerciseID: UUID) -> [SetEntry] {
        var result: [SetEntry] = []
        var inserted = false
        for set in allSets {
            if !inserted, set.exercise?.id == exerciseID, set.setType == .normal {
                result.append(newWarmup)
                inserted = true
            }
            result.append(set)
        }
        if !inserted {
            result.append(newWarmup)
        }
        return result
    }
}
