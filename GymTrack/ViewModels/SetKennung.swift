import Foundation

/// The leading per-set label shown in a set row: "A" for every warmup set, "D" for every
/// dropset, and a sequential number (starting at 1) counting normal sets only — matches the
/// user-facing spec exactly (warmups/dropsets are never numbered, only distinguished by
/// letter). For a unilateral set (`side` set), the number counts that side independently
/// (Left and Right each start back at 1) and the label carries the side's short letter, since
/// "3 sets per arm" means the count itself is per side. Shared between the live workout row
/// and the pre-start preview so both agree.
enum SetKennung {
    static func labels(for sets: [SetEntry]) -> [UUID: String] {
        var result: [UUID: String] = [:]
        var normalIndexBySide: [ExerciseSide?: Int] = [:]
        for set in sets {
            switch set.setType {
            case .warmup:
                result[set.id] = "A"
            case .dropset:
                result[set.id] = "D"
            case .normal:
                let side = set.side
                let nextIndex = (normalIndexBySide[side] ?? 0) + 1
                normalIndexBySide[side] = nextIndex
                if let side {
                    result[set.id] = "\(nextIndex) \(side.shortLabel)"
                } else {
                    result[set.id] = "\(nextIndex)"
                }
            }
        }
        return result
    }

    static func label(for set: SetEntry, in sets: [SetEntry]) -> String {
        labels(for: sets)[set.id] ?? ""
    }
}
