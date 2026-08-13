import Foundation

/// Turns a `PlanTemplate` into a real `TrainingPlan` + `PlanExercise`s by matching each
/// template entry to an existing `Exercise` by name. Entries with no matching exercise (e.g.
/// the user renamed or deleted a seeded default) are skipped rather than crashing or creating
/// a duplicate exercise — the template is a starting point, not a strict requirement.
enum PlanTemplateApplication {
    static func makePlan(from template: PlanTemplate, availableExercises: [Exercise]) -> (plan: TrainingPlan, planExercises: [PlanExercise]) {
        let exercisesByName = Dictionary(availableExercises.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let plan = TrainingPlan(name: template.name)

        var planExercises: [PlanExercise] = []
        for entry in template.exercises {
            guard let exercise = exercisesByName[entry.exerciseName] else { continue }
            planExercises.append(PlanExercise(
                order: planExercises.count,
                targetSets: entry.targetSets,
                targetReps: entry.targetReps,
                plan: plan,
                exercise: exercise
            ))
        }

        return (plan, planExercises)
    }
}
