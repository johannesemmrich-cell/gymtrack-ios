import Foundation
import SwiftData

@Model
final class SetEntry {
    var id: UUID = UUID()
    var order: Int = 0
    var setTypeRawValue: String = SetType.normal.rawValue
    var reps: Int = 0
    var weight: Double = 0
    var isCompleted: Bool = false
    /// Once true, `isCompleted` was last changed via the manual swipe override rather than
    /// the weight-and-reps auto-completion rule — further edits to weight/reps must leave it
    /// alone instead of silently recomputing over the user's explicit decision.
    var isCompletionManual: Bool = false
    var supersetGroupID: UUID? = nil
    /// Free-text note scoped to this one logged set (e.g. "Griff eng"), not carried forward.
    var note: String? = nil
    /// Display-only hint (previous session's value, or a same-session warmup/dropset
    /// suggestion) shown as a translucent placeholder — never counted as an actual logged
    /// value. `weight`/`reps` stay at their zero default until the user enters something real.
    var suggestedWeight: Double? = nil
    var suggestedReps: Int? = nil
    /// Which side a unilateral set belongs to — nil for a normal (bilateral) set. Independent
    /// of `PlanExercise.isUnilateral`, so a set keeps its side even if the plan is edited later.
    var sideRawValue: String? = nil

    var exercise: Exercise? = nil
    var gym: Gym? = nil
    var session: WorkoutSession? = nil

    var setType: SetType {
        get { SetType(rawValue: setTypeRawValue) ?? .normal }
        set { setTypeRawValue = newValue.rawValue }
    }

    var side: ExerciseSide? {
        get { sideRawValue.flatMap(ExerciseSide.init(rawValue:)) }
        set { sideRawValue = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        order: Int = 0,
        setType: SetType = .normal,
        reps: Int = 0,
        weight: Double = 0,
        isCompleted: Bool = false,
        isCompletionManual: Bool = false,
        supersetGroupID: UUID? = nil,
        note: String? = nil,
        suggestedWeight: Double? = nil,
        suggestedReps: Int? = nil,
        side: ExerciseSide? = nil,
        exercise: Exercise? = nil,
        gym: Gym? = nil,
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.order = order
        self.setTypeRawValue = setType.rawValue
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.isCompletionManual = isCompletionManual
        self.supersetGroupID = supersetGroupID
        self.note = note
        self.suggestedWeight = suggestedWeight
        self.suggestedReps = suggestedReps
        self.sideRawValue = side?.rawValue
        self.exercise = exercise
        self.gym = gym
        self.session = session
    }
}
