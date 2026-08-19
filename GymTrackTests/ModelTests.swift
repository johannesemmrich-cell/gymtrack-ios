import XCTest
import SwiftData
@testable import GymTrack

@MainActor
final class ModelTests: XCTestCase {

    private func makeContext() -> ModelContext {
        let container = PersistenceController.makeInMemoryContainer()
        return ModelContext(container)
    }

    // MARK: - CloudKit schema validation
    //
    // `makeInMemoryContainer()` does not enable CloudKit, so it silently accepts schemas
    // that would crash at app launch (e.g. a relationship missing its inverse). This test
    // builds the real schema with CloudKit enabled to catch that class of bug directly.

    func testSchemaIsCloudKitCompatible() throws {
        let configuration = ModelConfiguration(
            schema: PersistenceController.schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .private("iCloud.com.johannes.gymtrack")
        )
        XCTAssertNoThrow(
            try ModelContainer(for: PersistenceController.schema, configurations: [configuration]),
            "Every relationship needs an explicit inverse for CloudKit sync (see Exercise/Gym back-references)"
        )
    }

    // MARK: - Defaults / 0-values

    func testGymCreationDefaults() {
        let gym = Gym(name: "Home Gym")
        XCTAssertEqual(gym.name, "Home Gym")
        XCTAssertFalse(gym.isActive)
        XCTAssertNil(gym.note)
    }

    func testSetEntryDefaultsToZeroValues() {
        let set = SetEntry()
        XCTAssertEqual(set.reps, 0)
        XCTAssertEqual(set.weight, 0)
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.supersetGroupID)
        XCTAssertEqual(set.setType, .normal)
    }

    // MARK: - Enum raw-value round-trip

    func testExerciseMuscleGroupRoundTrip() {
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest)
        XCTAssertEqual(exercise.muscleGroup, .chest)
        exercise.muscleGroup = .back
        XCTAssertEqual(exercise.muscleGroupRawValue, MuscleGroup.back.rawValue)
        XCTAssertEqual(exercise.muscleGroup, .back)
    }

    func testSetEntrySetTypeRoundTrip() {
        let set = SetEntry(setType: .warmup)
        XCTAssertEqual(set.setType, .warmup)
        set.setType = .dropset
        XCTAssertEqual(set.setTypeRawValue, SetType.dropset.rawValue)
        XCTAssertEqual(set.setType, .dropset)
    }

    func testMuscleGroupFallsBackToOtherForUnknownRawValue() {
        let exercise = Exercise(name: "Mystery Move")
        exercise.muscleGroupRawValue = "not-a-real-case"
        XCTAssertEqual(exercise.muscleGroup, .other)
    }

    func testSetTypeFallsBackToNormalForUnknownRawValue() {
        let set = SetEntry()
        set.setTypeRawValue = "not-a-real-case"
        XCTAssertEqual(set.setType, .normal)
    }

    // MARK: - Relationship / cascade-delete correctness

    func testTrainingPlanCascadeDeletesPlanExercises() throws {
        let context = makeContext()
        let plan = TrainingPlan(name: "Push Day")
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest)
        let planExercise = PlanExercise(order: 0, plan: plan, exercise: exercise)
        context.insert(plan)
        context.insert(exercise)
        context.insert(planExercise)
        try context.save()

        let planExerciseID = planExercise.id
        context.delete(plan)
        try context.save()

        let descriptor = FetchDescriptor<PlanExercise>(
            predicate: #Predicate { $0.id == planExerciseID }
        )
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "Deleting a plan should cascade-delete its PlanExercise entries")
    }

    func testDeletingExerciseNullifiesButDoesNotDeletePlanExercise() throws {
        let context = makeContext()
        let plan = TrainingPlan(name: "Push Day")
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest)
        let planExercise = PlanExercise(order: 0, plan: plan, exercise: exercise)
        context.insert(plan)
        context.insert(exercise)
        context.insert(planExercise)
        try context.save()

        context.delete(exercise)
        try context.save()

        XCTAssertNotNil(planExercise.plan, "PlanExercise should survive its Exercise being deleted")
        XCTAssertNil(planExercise.exercise)
    }

    func testWorkoutSessionCascadeDeletesSets() throws {
        let context = makeContext()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Squat", muscleGroup: .legs)
        let setEntry = SetEntry(order: 0, reps: 10, weight: 60, exercise: exercise, session: session)
        context.insert(session)
        context.insert(exercise)
        context.insert(setEntry)
        try context.save()

        let setID = setEntry.id
        context.delete(session)
        try context.save()

        let descriptor = FetchDescriptor<SetEntry>(predicate: #Predicate { $0.id == setID })
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "Deleting a WorkoutSession should cascade-delete its SetEntry rows")
    }

    /// Guards against the RepCount-style bug class: removing one set must never
    /// mutate sibling sets that were not touched.
    func testDeletingOneSetDoesNotMutateSiblingSets() throws {
        let context = makeContext()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest)
        let warmup = SetEntry(order: 0, setType: .warmup, reps: 10, weight: 30, exercise: exercise, session: session)
        let working = SetEntry(order: 1, setType: .normal, reps: 8, weight: 60, exercise: exercise, session: session)
        context.insert(session)
        context.insert(exercise)
        context.insert(warmup)
        context.insert(working)
        try context.save()

        context.delete(warmup)
        try context.save()

        XCTAssertEqual(working.weight, 60, "Removing a warmup set must not change another set's weight")
        XCTAssertEqual(working.reps, 8)
    }

    func testWorkoutSessionIsCompletedReflectsEndedAt() {
        let session = WorkoutSession()
        XCTAssertFalse(session.isCompleted)
        session.endedAt = .now
        XCTAssertTrue(session.isCompleted)
    }

    func testPersonalRecordStoresEstimatedOneRepMax() {
        let exercise = Exercise(name: "Deadlift", muscleGroup: .back)
        let record = PersonalRecord(estimatedOneRepMax: 140, weight: 120, reps: 5, exercise: exercise)
        XCTAssertEqual(record.estimatedOneRepMax, 140)
        XCTAssertEqual(record.exercise?.name, "Deadlift")
    }

    // MARK: - Notes (permanent Exercise+Gym note, temporary PlanExercise/SetEntry notes)

    func testPlanExerciseNoteDefaultsToNilAndIsSettable() {
        let planExercise = PlanExercise()
        XCTAssertNil(planExercise.note)
        planExercise.note = "Flachbank statt Schrägbank"
        XCTAssertEqual(planExercise.note, "Flachbank statt Schrägbank")
    }

    func testSetEntryNoteDefaultsToNilAndIsSettable() {
        let set = SetEntry()
        XCTAssertNil(set.note)
        set.note = "Griff eng"
        XCTAssertEqual(set.note, "Griff eng")
    }

    func testExerciseGymNoteDefaults() {
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gym = Gym(name: "Frankfurt")
        let note = ExerciseGymNote(note: "Sitz Stufe 4", exercise: exercise, gym: gym)
        XCTAssertEqual(note.note, "Sitz Stufe 4")
        XCTAssertEqual(note.exercise?.name, "Beinpresse")
        XCTAssertEqual(note.gym?.name, "Frankfurt")
        XCTAssertNil(note.conversionFactor, "No per-exercise override by default — inherits the gym's global factor")
    }

    func testExerciseGymNoteConversionFactorIsSettable() {
        let note = ExerciseGymNote(conversionFactor: 0.8)
        XCTAssertEqual(note.conversionFactor, 0.8)
    }

    func testGymDefaultsToNoConversion() {
        let gym = Gym(name: "Frankfurt")
        XCTAssertEqual(gym.weightConversionFactor, 1.0)
    }

    func testGymConversionFactorIsSettable() {
        let gym = Gym(name: "Frankfurt", weightConversionFactor: 0.8)
        XCTAssertEqual(gym.weightConversionFactor, 0.8)
    }

    func testExerciseGymNoteCascadeDeletesWhenExerciseDeleted() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gym = Gym(name: "Frankfurt")
        let note = ExerciseGymNote(note: "Sitz Stufe 4", exercise: exercise, gym: gym)
        context.insert(exercise)
        context.insert(gym)
        context.insert(note)
        try context.save()

        let noteID = note.id
        context.delete(exercise)
        try context.save()

        let descriptor = FetchDescriptor<ExerciseGymNote>(predicate: #Predicate { $0.id == noteID })
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "An equipment note is meaningless without its Exercise and should be cascade-deleted")
    }

    func testExerciseGymNoteCascadeDeletesWhenGymDeleted() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gym = Gym(name: "Frankfurt")
        let note = ExerciseGymNote(note: "Sitz Stufe 4", exercise: exercise, gym: gym)
        context.insert(exercise)
        context.insert(gym)
        context.insert(note)
        try context.save()

        let noteID = note.id
        context.delete(gym)
        try context.save()

        let descriptor = FetchDescriptor<ExerciseGymNote>(predicate: #Predicate { $0.id == noteID })
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "An equipment note is meaningless without its Gym and should be cascade-deleted")
    }

    /// Deleting one gym's equipment note must not touch another gym's note for the same exercise
    /// (the same class of "unrelated sibling gets mutated" bug this project explicitly guards against).
    func testDeletingOneExerciseGymNoteDoesNotAffectAnotherGymsNote() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Beinpresse", muscleGroup: .legs)
        let gymA = Gym(name: "Heimat-Gym")
        let gymB = Gym(name: "Frankfurt")
        let noteA = ExerciseGymNote(note: "Sitz Stufe 2", exercise: exercise, gym: gymA)
        let noteB = ExerciseGymNote(note: "Sitz Stufe 4", exercise: exercise, gym: gymB)
        context.insert(exercise)
        context.insert(gymA)
        context.insert(gymB)
        context.insert(noteA)
        context.insert(noteB)
        try context.save()

        context.delete(noteA)
        try context.save()

        XCTAssertEqual(noteB.note, "Sitz Stufe 4")
        XCTAssertEqual(noteB.gym?.name, "Frankfurt")
    }

    // MARK: - Temporary reminder (shown once at the next training for one Exercise+Gym)

    func testExerciseGymReminderDefaults() {
        let exercise = Exercise(name: "Kreuzheben", muscleGroup: .back)
        let gym = Gym(name: "Frankfurt")
        let reminder = ExerciseGymReminder(text: "Nächstes Mal Gurt benutzen", exercise: exercise, gym: gym)
        XCTAssertEqual(reminder.text, "Nächstes Mal Gurt benutzen")
        XCTAssertFalse(reminder.isConsumed)
        XCTAssertEqual(reminder.exercise?.name, "Kreuzheben")
        XCTAssertEqual(reminder.gym?.name, "Frankfurt")
    }

    func testExerciseGymReminderCascadeDeletesWhenExerciseDeleted() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Kreuzheben", muscleGroup: .back)
        let gym = Gym(name: "Frankfurt")
        let reminder = ExerciseGymReminder(text: "Nächstes Mal Gurt benutzen", exercise: exercise, gym: gym)
        context.insert(exercise)
        context.insert(gym)
        context.insert(reminder)
        try context.save()

        let reminderID = reminder.id
        context.delete(exercise)
        try context.save()

        let descriptor = FetchDescriptor<ExerciseGymReminder>(predicate: #Predicate { $0.id == reminderID })
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "A reminder is meaningless without its Exercise and should be cascade-deleted")
    }

    func testExerciseGoalCascadeDeletesWhenExerciseDeleted() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let goal = ExerciseGoal(targetWeight: 100, exercise: exercise)
        context.insert(exercise)
        context.insert(goal)
        try context.save()

        let goalID = goal.id
        context.delete(exercise)
        try context.save()

        let descriptor = FetchDescriptor<ExerciseGoal>(predicate: #Predicate { $0.id == goalID })
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "A goal is meaningless without its Exercise and should be cascade-deleted")
    }

    func testExerciseGymReminderCascadeDeletesWhenGymDeleted() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Kreuzheben", muscleGroup: .back)
        let gym = Gym(name: "Frankfurt")
        let reminder = ExerciseGymReminder(text: "Nächstes Mal Gurt benutzen", exercise: exercise, gym: gym)
        context.insert(exercise)
        context.insert(gym)
        context.insert(reminder)
        try context.save()

        let reminderID = reminder.id
        context.delete(gym)
        try context.save()

        let descriptor = FetchDescriptor<ExerciseGymReminder>(predicate: #Predicate { $0.id == reminderID })
        let remaining = try context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty, "A reminder is meaningless without its Gym and should be cascade-deleted")
    }

    /// Consuming (or deleting) one gym's reminder must not touch another gym's reminder for the same exercise.
    func testConsumingOneReminderDoesNotAffectAnotherGymsReminder() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Kreuzheben", muscleGroup: .back)
        let gymA = Gym(name: "Heimat-Gym")
        let gymB = Gym(name: "Frankfurt")
        let reminderA = ExerciseGymReminder(text: "Gurt benutzen", exercise: exercise, gym: gymA)
        let reminderB = ExerciseGymReminder(text: "Aufwärmen nicht vergessen", exercise: exercise, gym: gymB)
        context.insert(exercise)
        context.insert(gymA)
        context.insert(gymB)
        context.insert(reminderA)
        context.insert(reminderB)
        try context.save()

        reminderA.isConsumed = true
        try context.save()

        XCTAssertTrue(reminderA.isConsumed)
        XCTAssertFalse(reminderB.isConsumed, "Marking one reminder as consumed must not affect a different gym's reminder")
        XCTAssertEqual(reminderB.text, "Aufwärmen nicht vergessen")
    }

    func testMultiplePendingRemindersCanCoexistForSameExerciseAndGym() throws {
        let context = makeContext()
        let exercise = Exercise(name: "Kreuzheben", muscleGroup: .back)
        let gym = Gym(name: "Frankfurt")
        context.insert(exercise)
        context.insert(gym)
        context.insert(ExerciseGymReminder(text: "Gurt benutzen", exercise: exercise, gym: gym))
        context.insert(ExerciseGymReminder(text: "Aufwärmen nicht vergessen", exercise: exercise, gym: gym))
        try context.save()

        let descriptor = FetchDescriptor<ExerciseGymReminder>()
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.count, 2, "No uniqueness constraint at the model layer; multiple pending reminders are allowed to coexist")
    }

    // MARK: - Many sets on one session

    func testWorkoutSessionSupportsManySets() throws {
        let context = makeContext()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Leg Press", muscleGroup: .legs)
        context.insert(session)
        context.insert(exercise)

        for i in 0..<50 {
            let set = SetEntry(order: i, reps: 10, weight: Double(i), exercise: exercise, session: session)
            context.insert(set)
        }
        try context.save()

        let descriptor = FetchDescriptor<SetEntry>()
        let allSets = try context.fetch(descriptor)
        XCTAssertEqual(allSets.count, 50)
    }
}
