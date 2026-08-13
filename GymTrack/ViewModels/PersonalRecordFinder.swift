import Foundation

/// Finds, per exercise, the completed working set with the highest estimated one-rep max —
/// gym-converted so a lift at a differently-calibrated gym is comparable to one anywhere else.
/// Purely a read-time computation over existing session/set history, matching the rest of the
/// Statistics tab's stateless approach (`SessionStatistics`, `ExerciseFrequency`,
/// `TrainingVolume`) rather than writing back to the `PersonalRecord` model — there's no
/// meaningful moment to "commit" a PR short of recomputing it, and a stateless read avoids any
/// question of when to persist one.
enum PersonalRecordFinder {
    struct Entry {
        let exercise: Exercise
        /// Gym-converted (see `GymConversion`), so records from different gyms are comparable.
        let estimatedOneRepMax: Double
        /// Raw, as actually logged — for display alongside the converted estimate.
        let weight: Double
        let reps: Int
        let gym: Gym?
        let achievedAt: Date
    }

    /// A personal record needs a genuine max-effort working set — warmup and dropset sets are
    /// excluded, matching `SetSuggestion`'s existing convention that they don't represent a
    /// lifter's real capability.
    static func bestPerExercise(from sessions: [WorkoutSession], exerciseGymNotes: [ExerciseGymNote]) -> [Entry] {
        var bestByExerciseID: [UUID: Entry] = [:]

        for session in SessionStatistics.eligibleSessions(sessions) {
            for set in (session.sets ?? []) where set.isCompleted && set.setType == .normal {
                guard let exercise = set.exercise else { continue }

                let gymFactor = set.gym?.weightConversionFactor ?? 1.0
                let override = exerciseGymNotes.first {
                    $0.exercise?.id == exercise.id && $0.gym?.id == set.gym?.id
                }?.conversionFactor
                let effectiveFactor = GymConversion.effectiveFactor(gymFactor: gymFactor, exerciseOverride: override)
                let convertedWeight = GymConversion.convert(set.weight, fromFactor: effectiveFactor, toFactor: 1.0)
                let oneRepMax = OneRepMax.estimate(weight: convertedWeight, reps: set.reps)
                guard oneRepMax > 0 else { continue }

                // On an exact tie, prefer the more recent session — deterministic by date
                // rather than by SwiftData's unspecified fetch/relationship iteration order,
                // which could otherwise make a tied PR's shown date/gym flip between launches.
                if let existing = bestByExerciseID[exercise.id] {
                    let isWorse = oneRepMax < existing.estimatedOneRepMax
                    let isTiedAndNotNewer = oneRepMax == existing.estimatedOneRepMax && session.startedAt <= existing.achievedAt
                    if isWorse || isTiedAndNotNewer {
                        continue
                    }
                }

                bestByExerciseID[exercise.id] = Entry(
                    exercise: exercise,
                    estimatedOneRepMax: oneRepMax,
                    weight: set.weight,
                    reps: set.reps,
                    gym: set.gym,
                    achievedAt: session.startedAt
                )
            }
        }

        return bestByExerciseID.values.sorted { $0.exercise.name < $1.exercise.name }
    }
}
