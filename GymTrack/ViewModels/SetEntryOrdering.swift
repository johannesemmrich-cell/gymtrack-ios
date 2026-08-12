import Foundation

/// Reassigns `order` on each SetEntry to match its position in the given array. Must never
/// touch any other property — this is the exact guarantee the RepCount-style bug this
/// project avoids depends on ("removing a warmup set shifted another set's weight").
enum SetEntryOrdering {
    static func reindex(_ items: [SetEntry]) {
        for (index, item) in items.enumerated() {
            item.order = index
        }
    }
}
