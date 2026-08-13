import Foundation

/// Suggests a reduced weight for a new dropset — a set performed immediately after another
/// with no rest, at less weight. Purely a suggestion — always freely overridable in the UI.
enum DropsetSuggestion {
    /// 20% lighter than the set it drops from, matching common dropset practice. Each
    /// additional dropset continues the ladder down from the immediately preceding set's
    /// weight, not the original working weight — pass whichever set the new one drops from.
    private static let reductionFactor: Double = 0.8

    static func suggestedWeight(previousWeight: Double) -> Double {
        previousWeight * reductionFactor
    }
}
