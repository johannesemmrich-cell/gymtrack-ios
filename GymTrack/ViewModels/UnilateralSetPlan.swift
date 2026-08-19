import Foundation

/// The ordered side sequence for a plan-exercise's generated sets: `nil` per set for a
/// bilateral exercise, otherwise alternating left/right per set number (left, right, left,
/// right, … — not all-left-then-all-right, matching a working set trained on one side
/// immediately followed by the same set on the other side before resting). `targetSets` means
/// "sets per side" once unilateral, so the sequence is twice as long as `targetSets` in that
/// case. Shared by `WorkoutSessionBuilder` and `PlanStartView`'s preview so the two can never
/// independently drift out of sync on how unilateral sets are laid out.
enum UnilateralSetPlan {
    static func sides(targetSets: Int, isUnilateral: Bool) -> [ExerciseSide?] {
        let count = max(targetSets, 0)
        guard isUnilateral else {
            return Array(repeating: nil, count: count)
        }
        return (0..<count).flatMap { _ in [ExerciseSide.left, ExerciseSide.right] }
    }
}
