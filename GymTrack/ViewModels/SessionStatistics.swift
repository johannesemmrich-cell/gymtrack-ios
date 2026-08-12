import Foundation

/// Average workout duration and weekly frequency, computed only from sessions that actually
/// represent real training: ended (so a duration exists) and containing at least one
/// completed set (an ended-but-empty session doesn't count as a training).
enum SessionStatistics {
    private static let secondsPerWeek: TimeInterval = 7 * 24 * 3600

    static func eligibleSessions(_ sessions: [WorkoutSession]) -> [WorkoutSession] {
        sessions.filter { session in
            guard session.endedAt != nil else { return false }
            return (session.sets ?? []).contains { $0.isCompleted }
        }
    }

    static func averageDuration(_ sessions: [WorkoutSession]) -> TimeInterval? {
        let durations = eligibleSessions(sessions).compactMap { session -> TimeInterval? in
            guard let endedAt = session.endedAt else { return nil }
            return endedAt.timeIntervalSince(session.startedAt)
        }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    static func averageSessionsPerWeek(_ sessions: [WorkoutSession]) -> Double? {
        let eligible = eligibleSessions(sessions)
        guard !eligible.isEmpty,
              let earliest = eligible.map(\.startedAt).min(),
              let latest = eligible.map(\.startedAt).max() else { return nil }
        // Never divide by less than one full week, so a burst of sessions on a single day
        // (or a single session ever) doesn't produce an inflated rate.
        let weeksSpanned = max(1.0, (latest.timeIntervalSince(earliest) / secondsPerWeek).rounded(.up))
        return Double(eligible.count) / weeksSpanned
    }
}
