import Foundation

/// Filters the plan list by gym for the switcher on the Pläne tab. A plan with no gym assigned
/// applies everywhere, so it's never hidden by a specific-gym filter — only plans explicitly
/// tied to a *different* gym are.
enum PlanGymFiltering {
    static func filter(_ plans: [TrainingPlan], byGymID gymID: UUID?) -> [TrainingPlan] {
        guard let gymID else { return plans }
        return plans.filter { $0.gym == nil || $0.gym?.id == gymID }
    }
}
