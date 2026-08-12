import Foundation

/// Suggests staggered warmup weights as percentages of the working weight, e.g. 50/70/85 %
/// for three warmup sets. Purely a suggestion — always freely overridable in the UI.
enum WarmupSuggestion {
    /// Percentage ladders for the common cases, tuned by feel rather than pure linear
    /// spacing (matches the spec's own 50/70/85 % example for three warmups). Each ladder is
    /// a prefix of the next so that incrementally adding warmups (which never rewrites an
    /// already-created warmup's weight, since that would itself violate this ticket's "never
    /// change another set's weight" rule) produces a consistent progression: 50% → 70% → 85%.
    private static let commonLadders: [Int: [Double]] = [
        1: [0.5],
        2: [0.5, 0.7],
        3: [0.5, 0.7, 0.85]
    ]

    static func suggestedWeights(workingWeight: Double, count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let percentages: [Double]
        if let ladder = commonLadders[count] {
            percentages = ladder
        } else {
            // Beyond the common cases: evenly staged from 50% up to 90% of the working weight.
            percentages = (0..<count).map { index in
                0.5 + (Double(index) / Double(count - 1)) * 0.4
            }
        }
        return percentages.map { $0 * workingWeight }
    }
}
