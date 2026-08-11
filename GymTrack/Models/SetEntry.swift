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
    var supersetGroupID: UUID? = nil
    /// Free-text note scoped to this one logged set (e.g. "Griff eng"), not carried forward.
    var note: String? = nil

    var exercise: Exercise? = nil
    var gym: Gym? = nil
    var session: WorkoutSession? = nil

    var setType: SetType {
        get { SetType(rawValue: setTypeRawValue) ?? .normal }
        set { setTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        order: Int = 0,
        setType: SetType = .normal,
        reps: Int = 0,
        weight: Double = 0,
        isCompleted: Bool = false,
        supersetGroupID: UUID? = nil,
        note: String? = nil,
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
        self.supersetGroupID = supersetGroupID
        self.note = note
        self.exercise = exercise
        self.gym = gym
        self.session = session
    }
}
