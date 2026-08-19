import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, biceps, triceps, legs, glutes, abs, calves, forearms, fullBody, cardio, other
}

enum SetType: String, Codable, CaseIterable, Sendable {
    case normal, warmup, dropset
}

enum FeedbackPriority: String, Codable, CaseIterable, Sendable {
    case urgent, high, medium, low, testing
}

enum ExerciseSide: String, Codable, CaseIterable, Sendable {
    case left, right

    var opposite: ExerciseSide {
        switch self {
        case .left: return .right
        case .right: return .left
        }
    }
}
