import Foundation

/// Builds a new WorkoutSession with pre-filled SetEntry rows from a plan's exercises,
/// using the most recent set history for weight/reps where available, falling back to
/// the plan's own targets. Returned objects are not yet inserted into a ModelContext —
/// the caller must insert the session and every set explicitly.
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
            let weight = suggestion?.weight ?? planExercise.targetWeight ?? 0
            let reps = suggestion?.reps ?? planExercise.targetReps

            for _ in 0..<planExercise.targetSets {
                let set = SetEntry(
                    order: order,
                    setType: .normal,
                    reps: reps,
                    weight: weight,
                    isCompleted: false,
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
