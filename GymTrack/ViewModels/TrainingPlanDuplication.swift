import Foundation

/// Deep-copies a plan and its exercise entries (same target sets/reps/weight/note, same
/// underlying Exercise references — not duplicated). Returned objects are not yet inserted
/// into a ModelContext; the caller must insert the plan and every copied entry explicitly.
enum TrainingPlanDuplication {
    static func duplicate(_ plan: TrainingPlan) -> (plan: TrainingPlan, planExercises: [PlanExercise]) {
        let copy = TrainingPlan(name: "\(plan.name) (Kopie)", note: plan.note)
        let sourceExercises = (plan.exercises ?? []).sorted { $0.order < $1.order }

        let copiedExercises = sourceExercises.map { source in
            PlanExercise(
                order: source.order,
                targetSets: source.targetSets,
                targetReps: source.targetReps,
                targetWeight: source.targetWeight,
                isUnilateral: source.isUnilateral,
                note: source.note,
                // Duplicating is not tuning — a fresh `.now` here would let a duplicate
                // silently outrank a genuinely more recently tuned entry in
                // PlanExerciseDefaults.suggest's "most recent" lookup across plans.
                updatedAt: source.updatedAt,
                plan: copy,
                exercise: source.exercise
            )
        }

        return (copy, copiedExercises)
    }
}
