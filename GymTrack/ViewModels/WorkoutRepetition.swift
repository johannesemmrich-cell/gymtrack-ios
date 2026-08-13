import Foundation

/// Builds a new WorkoutSession by replaying a past, completed session's sets as an
/// uncompleted starting point — works even for a session that was never tied to a
/// TrainingPlan. Returned objects are not yet inserted into a ModelContext — the caller
/// must insert the session and every set explicitly.
enum WorkoutRepetition {
    static func build(repeating source: WorkoutSession, gym: Gym?) -> (session: WorkoutSession, sets: [SetEntry]) {
        let session = WorkoutSession(startedAt: .now, planName: source.planName, gym: gym)
        let sourceSets = (source.sets ?? [])
            .filter(\.isCompleted)
            .sorted { $0.order < $1.order }

        var createdSets: [SetEntry] = []
        for sourceSet in sourceSets {
            guard let exercise = sourceSet.exercise else { continue }
            let set = SetEntry(
                order: createdSets.count,
                setType: sourceSet.setType,
                reps: sourceSet.reps,
                weight: sourceSet.weight,
                isCompleted: false,
                exercise: exercise,
                gym: gym,
                session: session
            )
            createdSets.append(set)
        }

        return (session, createdSets)
    }
}
