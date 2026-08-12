import XCTest
@testable import GymTrack

final class SessionStatisticsTests: XCTestCase {

    private func makeEndedSession(start: Date, end: Date, completedSet: Bool) -> WorkoutSession {
        let session = WorkoutSession(startedAt: start, endedAt: end)
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: completedSet, exercise: exercise, session: session)
        return session
    }

    // MARK: - eligibleSessions

    func testEligibleSessionsExcludesStillActiveSessions() {
        let active = WorkoutSession(startedAt: .now, endedAt: nil)
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        _ = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, session: active)

        XCTAssertTrue(SessionStatistics.eligibleSessions([active]).isEmpty)
    }

    func testEligibleSessionsExcludesEndedSessionsWithNoCompletedSets() {
        let session = makeEndedSession(start: .now, end: .now, completedSet: false)
        XCTAssertTrue(SessionStatistics.eligibleSessions([session]).isEmpty)
    }

    func testEligibleSessionsExcludesEndedSessionsWithNoSetsAtAll() {
        let session = WorkoutSession(startedAt: .now, endedAt: .now)
        XCTAssertTrue(SessionStatistics.eligibleSessions([session]).isEmpty)
    }

    func testEligibleSessionsIncludesEndedSessionsWithAtLeastOneCompletedSet() {
        let session = makeEndedSession(start: .now, end: .now, completedSet: true)
        XCTAssertEqual(SessionStatistics.eligibleSessions([session]).count, 1)
    }

    // MARK: - averageDuration

    func testAverageDurationIsNilWithNoEligibleSessions() {
        XCTAssertNil(SessionStatistics.averageDuration([]))
    }

    func testAverageDurationComputesMeanOfEndedMinusStarted() {
        let base = Date(timeIntervalSince1970: 0)
        let a = makeEndedSession(start: base, end: base.addingTimeInterval(60 * 30), completedSet: true) // 30 min
        let b = makeEndedSession(start: base, end: base.addingTimeInterval(60 * 60), completedSet: true) // 60 min
        XCTAssertEqual(SessionStatistics.averageDuration([a, b]), 60 * 45) // 45 min average
    }

    func testAverageDurationIgnoresIneligibleSessions() {
        let base = Date(timeIntervalSince1970: 0)
        let eligible = makeEndedSession(start: base, end: base.addingTimeInterval(60 * 30), completedSet: true)
        let ineligible = makeEndedSession(start: base, end: base.addingTimeInterval(60 * 1000), completedSet: false)
        XCTAssertEqual(SessionStatistics.averageDuration([eligible, ineligible]), 60 * 30)
    }

    // MARK: - averageSessionsPerWeek

    func testAverageSessionsPerWeekIsNilWithNoEligibleSessions() {
        XCTAssertNil(SessionStatistics.averageSessionsPerWeek([]))
    }

    func testSingleSessionCountsAsOnePerWeek() {
        let session = makeEndedSession(start: .now, end: .now, completedSet: true)
        XCTAssertEqual(SessionStatistics.averageSessionsPerWeek([session]), 1.0)
    }

    func testMultipleSessionsOnTheSameDayStillFloorToOneWeek() {
        let base = Date(timeIntervalSince1970: 0)
        let a = makeEndedSession(start: base, end: base.addingTimeInterval(60), completedSet: true)
        let b = makeEndedSession(start: base.addingTimeInterval(3600), end: base.addingTimeInterval(3660), completedSet: true)
        XCTAssertEqual(SessionStatistics.averageSessionsPerWeek([a, b]), 2.0)
    }

    func testSessionsSpanningExactlyTwoWeeksAverageCorrectly() {
        let base = Date(timeIntervalSince1970: 0)
        let secondsPerWeek: TimeInterval = 7 * 24 * 3600
        let sessions = [
            makeEndedSession(start: base, end: base.addingTimeInterval(60), completedSet: true),
            makeEndedSession(start: base.addingTimeInterval(secondsPerWeek), end: base.addingTimeInterval(secondsPerWeek + 60), completedSet: true),
            makeEndedSession(start: base.addingTimeInterval(2 * secondsPerWeek), end: base.addingTimeInterval(2 * secondsPerWeek + 60), completedSet: true)
        ]
        // Spans 2 full weeks, 3 sessions -> 1.5/week.
        XCTAssertEqual(SessionStatistics.averageSessionsPerWeek(sessions), 1.5)
    }
}
