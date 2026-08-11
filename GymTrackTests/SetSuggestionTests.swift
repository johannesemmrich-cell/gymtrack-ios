import XCTest
@testable import GymTrack

final class SetSuggestionTests: XCTestCase {

    func testNoHistoryReturnsNil() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        XCTAssertNil(SetSuggestion.suggest(for: exercise, gym: gym, from: []))
    }

    func testUsesOnlyMatchingCompletedNormalSet() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let session = WorkoutSession(startedAt: .now)
        let set = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, gym: gym, session: session)
        let suggestion = SetSuggestion.suggest(for: exercise, gym: gym, from: [set])
        XCTAssertEqual(suggestion?.weight, 60)
        XCTAssertEqual(suggestion?.reps, 8)
    }

    func testIgnoresEntriesForADifferentExercise() {
        let target = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let other = Exercise(name: "Kniebeugen", muscleGroup: .legs)
        let gym = Gym(name: "Frankfurt")
        let session = WorkoutSession()
        let set = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: other, gym: gym, session: session)
        XCTAssertNil(SetSuggestion.suggest(for: target, gym: gym, from: [set]))
    }

    func testIgnoresEntriesForADifferentGym() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let targetGym = Gym(name: "Frankfurt")
        let otherGym = Gym(name: "Heimat-Gym")
        let session = WorkoutSession()
        let set = SetEntry(reps: 8, weight: 60, isCompleted: true, exercise: exercise, gym: otherGym, session: session)
        XCTAssertNil(SetSuggestion.suggest(for: exercise, gym: targetGym, from: [set]))
    }

    func testIgnoresIncompleteSets() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let session = WorkoutSession()
        let set = SetEntry(reps: 8, weight: 60, isCompleted: false, exercise: exercise, gym: gym, session: session)
        XCTAssertNil(SetSuggestion.suggest(for: exercise, gym: gym, from: [set]))
    }

    func testIgnoresWarmupAndDropsetTypes() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let session = WorkoutSession()
        let warmup = SetEntry(setType: .warmup, reps: 10, weight: 30, isCompleted: true, exercise: exercise, gym: gym, session: session)
        let dropset = SetEntry(setType: .dropset, reps: 15, weight: 40, isCompleted: true, exercise: exercise, gym: gym, session: session)
        XCTAssertNil(SetSuggestion.suggest(for: exercise, gym: gym, from: [warmup, dropset]))
    }

    func testPicksSetFromMostRecentSession() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let olderSession = WorkoutSession(startedAt: Date(timeIntervalSince1970: 1000))
        let newerSession = WorkoutSession(startedAt: Date(timeIntervalSince1970: 2000))
        let olderSet = SetEntry(reps: 10, weight: 50, isCompleted: true, exercise: exercise, gym: gym, session: olderSession)
        let newerSet = SetEntry(reps: 6, weight: 70, isCompleted: true, exercise: exercise, gym: gym, session: newerSession)
        let suggestion = SetSuggestion.suggest(for: exercise, gym: gym, from: [olderSet, newerSet])
        XCTAssertEqual(suggestion?.weight, 70)
        XCTAssertEqual(suggestion?.reps, 6)
    }

    func testWithinSameSessionPicksHighestOrder() {
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let gym = Gym(name: "Frankfurt")
        let session = WorkoutSession()
        let first = SetEntry(order: 0, reps: 10, weight: 50, isCompleted: true, exercise: exercise, gym: gym, session: session)
        let last = SetEntry(order: 2, reps: 6, weight: 65, isCompleted: true, exercise: exercise, gym: gym, session: session)
        let suggestion = SetSuggestion.suggest(for: exercise, gym: gym, from: [first, last])
        XCTAssertEqual(suggestion?.weight, 65)
        XCTAssertEqual(suggestion?.reps, 6)
    }
}
