import Foundation

extension ExerciseSide {
    var shortLabel: String {
        switch self {
        case .left: return "L"
        case .right: return "R"
        }
    }

    var fullLabel: String {
        switch self {
        case .left: return "Links"
        case .right: return "Rechts"
        }
    }
}
