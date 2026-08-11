import Foundation

extension MuscleGroup {
    var displayName: String {
        switch self {
        case .chest: return "Brust"
        case .back: return "Rücken"
        case .shoulders: return "Schultern"
        case .biceps: return "Bizeps"
        case .triceps: return "Trizeps"
        case .legs: return "Beine"
        case .glutes: return "Gesäß"
        case .abs: return "Bauch"
        case .calves: return "Waden"
        case .forearms: return "Unterarme"
        case .fullBody: return "Ganzkörper"
        case .cardio: return "Cardio"
        case .other: return "Sonstiges"
        }
    }
}
