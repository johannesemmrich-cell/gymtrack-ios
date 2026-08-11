import Foundation

/// Ensures exactly one gym in a list is marked active.
enum GymActivation {
    static func activate(_ gym: Gym, among gyms: [Gym]) {
        for candidate in gyms {
            candidate.isActive = (candidate.id == gym.id)
        }
    }
}
