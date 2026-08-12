import Foundation

/// Computes training volume (Σ weight × reps across completed sets) per eligible session,
/// either overall or scoped to one exercise, for use in the volume-over-time chart.
enum TrainingVolume {
    struct DataPoint: Identifiable {
        let date: Date
        let volume: Double

        var id: Date { date }
    }

    static func dataPoints(sessions: [WorkoutSession], exercise: Exercise?) -> [DataPoint] {
        SessionStatistics.eligibleSessions(sessions)
            .compactMap { session -> DataPoint? in
                let relevantSets = (session.sets ?? [])
                    .filter(\.isCompleted)
                    .filter { exercise == nil || $0.exercise?.id == exercise?.id }

                guard !relevantSets.isEmpty else { return nil }

                let volume = relevantSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                return DataPoint(date: session.startedAt, volume: volume)
            }
            .sorted { $0.date < $1.date }
    }

    static func exercisesWithVolumeHistory(sessions: [WorkoutSession]) -> [Exercise] {
        var exercisesByID: [UUID: Exercise] = [:]

        for session in SessionStatistics.eligibleSessions(sessions) {
            for set in (session.sets ?? []) where set.isCompleted {
                if let exercise = set.exercise {
                    exercisesByID[exercise.id] = exercise
                }
            }
        }

        return exercisesByID.values.sorted { $0.name < $1.name }
    }
}
