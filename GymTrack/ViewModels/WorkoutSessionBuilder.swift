import Foundation

/// Builds a new WorkoutSession with pre-filled SetEntry rows from a plan's exercises,
/// using the most recent set history for weight/reps where available, falling back to
/// the plan's own targets. Returned objects are not yet inserted into a ModelContext —
/// the caller must insert the session and every set explicitly, and should do so
/// immediately/synchronously: holding these not-yet-inserted, relationship-linked objects
/// across multiple SwiftUI render passes (e.g. in `@State` while a screen just sits idle)
/// has been observed to corrupt SwiftUI's rendering of whatever reads them.
enum WorkoutSessionBuilder {
    static func build(
        from plan: TrainingPlan,
        gym: Gym?,
        setHistory: [SetEntry]
    ) -> (session: WorkoutSession, sets: [SetEntry]) {
        let session = WorkoutSession(startedAt: .now, planName: plan.name, gym: gym)
        let planExercises = (plan.exercises ?? []).sorted { $0.order < $1.order }

        var createdSets: [SetEntry] = []
        var order = 0

        for planExercise in planExercises {
            guard let exercise = planExercise.exercise else { continue }

            let suggestion = gym.flatMap { SetSuggestion.suggest(for: exercise, gym: $0, from: setHistory) }
            // Only a display hint — the real weight/reps stay at their zero default until the
            // user actually enters something, so a fresh set never looks pre-completed.
            let suggestedWeight = suggestion?.weight ?? planExercise.targetWeight
            let suggestedReps = suggestion?.reps ?? planExercise.targetReps

            let sides = UnilateralSetPlan.sides(targetSets: planExercise.targetSets, isUnilateral: planExercise.isUnilateral)
            for side in sides {
                let set = SetEntry(
                    order: order,
                    setType: .normal,
                    reps: 0,
                    weight: 0,
                    isCompleted: false,
                    supersetGroupID: planExercise.supersetGroupID,
                    suggestedWeight: suggestedWeight,
                    suggestedReps: suggestedReps,
                    side: side,
                    exercise: exercise,
                    gym: gym,
                    session: session
                )
                createdSets.append(set)
                order += 1
            }
        }

        return (session, createdSets)
    }
}
