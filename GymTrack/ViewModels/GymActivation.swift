import Foundation

/// Ensures exactly one gym in a list is marked active.
enum GymActivation {
    static func activate(_ gym: Gym, among gyms: [Gym]) {
        for candidate in gyms {
            candidate.isActive = (candidate.id == gym.id)
        }
    }

    /// Call right before deleting `deletedGym`. If it was the active gym, promotes the
    /// alphabetically-first remaining gym to active, so weight suggestions and workout
    /// logging (both keyed off the active gym) never silently lose one. No-op if the
    /// deleted gym wasn't active, or if no gyms remain.
    static func promoteReplacement(afterDeleting deletedGym: Gym, remaining: [Gym]) {
        guard deletedGym.isActive else { return }
        guard let replacement = remaining.min(by: { $0.name < $1.name }) else { return }
        activate(replacement, among: remaining)
    }
}
