import Foundation

/// Reassigns `order` on each PlanExercise to match its position in the given array,
/// used after a drag-to-reorder or a delete to keep order values contiguous.
enum PlanExerciseOrdering {
    static func reindex(_ items: [PlanExercise]) {
        for (index, item) in items.enumerated() {
            item.order = index
        }
    }
}
