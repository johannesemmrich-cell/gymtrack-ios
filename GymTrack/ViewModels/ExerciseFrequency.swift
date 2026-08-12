import Foundation

/// Ranks exercises by how many eligible training sessions (see SessionStatistics) included
/// at least one completed set of that exercise — doing 5 sets of an exercise in one session
/// counts as one occurrence, not five.
enum ExerciseFrequency {
    struct Entry {
        let exercise: Exercise
        let sessionCount: Int
    }

    static func mostFrequentExercises(from sessions: [WorkoutSession]) -> [Entry] {
        var sessionCountByExerciseID: [UUID: Int] = [:]
        var exercisesByID: [UUID: Exercise] = [:]

        for session in SessionStatistics.eligibleSessions(sessions) {
            let exercisesInSession = (session.sets ?? [])
                .filter(\.isCompleted)
                .compactMap(\.exercise)

            var seenInThisSession: Set<UUID> = []
            for exercise in exercisesInSession where !seenInThisSession.contains(exercise.id) {
                seenInThisSession.insert(exercise.id)
                exercisesByID[exercise.id] = exercise
                sessionCountByExerciseID[exercise.id, default: 0] += 1
            }
        }

        return sessionCountByExerciseID
            .compactMap { id, count in exercisesByID[id].map { Entry(exercise: $0, sessionCount: count) } }
            .sorted { lhs, rhs in
                if lhs.sessionCount != rhs.sessionCount {
                    return lhs.sessionCount > rhs.sessionCount
                }
                return lhs.exercise.name < rhs.exercise.name
            }
    }
}
