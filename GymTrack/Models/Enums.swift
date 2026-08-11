import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, biceps, triceps, legs, glutes, abs, calves, forearms, fullBody, cardio, other
}

enum SetType: String, Codable, CaseIterable, Sendable {
    case normal, warmup, dropset
}
