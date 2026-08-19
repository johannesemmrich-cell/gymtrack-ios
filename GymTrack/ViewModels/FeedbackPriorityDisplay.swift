import Foundation

extension FeedbackPriority {
    var label: String {
        switch self {
        case .urgent: return "Dringend"
        case .high: return "Hoch"
        case .medium: return "Mittel"
        case .low: return "Niedrig"
        case .testing: return "Zum Testen"
        }
    }

    var emoji: String {
        switch self {
        case .urgent: return "⛔"
        case .high: return "🔴"
        case .medium: return "🟠"
        case .low: return "🔵"
        case .testing: return "🟣"
        }
    }
}
