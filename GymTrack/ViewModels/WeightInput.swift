import Foundation

/// Parses free-text weight entry (decimal-pad keyboard, comma or dot as separator).
/// Kept as a pure function so weight-field views can compose it without repeating this
/// logic locally with copy-paste drift risk.
enum WeightInput {
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
