import Foundation

/// Groups/ungroups `PlanExercise`s into supersets — exercises logged back-to-back as one unit.
/// A shared, freshly-generated `supersetGroupID` is the only thing that ties members together;
/// there's no separate "group" entity to keep in sync.
enum SupersetGrouping {
    /// Assigns a shared new group id to every given exercise, replacing whatever group (if
    /// any) each was previously in. Fewer than 2 exercises can't form a superset — a no-op.
    ///
    /// `allPlanExercises` is the full population to check for fallout: if some of the newly
    /// grouped exercises were previously in a *different* group together with exercises that
    /// aren't part of this new selection, those left-behind exercises would otherwise keep a
    /// `supersetGroupID` shared with nobody (or with too few partners to still count as a
    /// superset) — so they're cleaned up the same way `leave` would clean them up.
    static func group(_ planExercises: [PlanExercise], allPlanExercises: [PlanExercise]) {
        guard planExercises.count >= 2 else { return }
        let selectedIDs = Set(planExercises.map(\.id))
        let previousGroupIDs = Set(planExercises.compactMap(\.supersetGroupID))

        let groupID = UUID()
        for planExercise in planExercises {
            planExercise.supersetGroupID = groupID
        }

        for previousGroupID in previousGroupIDs {
            let leftBehind = allPlanExercises.filter {
                $0.supersetGroupID == previousGroupID && !selectedIDs.contains($0.id)
            }
            if leftBehind.count < 2 {
                for member in leftBehind {
                    member.supersetGroupID = nil
                }
            }
        }
    }

    /// Removes every given exercise from its superset group, regardless of who else is in it.
    static func ungroup(_ planExercises: [PlanExercise]) {
        for planExercise in planExercises {
            planExercise.supersetGroupID = nil
        }
    }

    /// Removes just `planExercise` from its group. If that would leave fewer than 2 members —
    /// a "superset" of one isn't meaningful — the remaining member(s) are ungrouped too.
    static func leave(_ planExercise: PlanExercise, from allPlanExercises: [PlanExercise]) {
        guard let groupID = planExercise.supersetGroupID else { return }
        let remainingMembers = allPlanExercises.filter {
            $0.supersetGroupID == groupID && $0.id != planExercise.id
        }
        planExercise.supersetGroupID = nil
        if remainingMembers.count < 2 {
            for member in remainingMembers {
                member.supersetGroupID = nil
            }
        }
    }

    /// Names of the OTHER exercises sharing `planExercise`'s superset group, for display
    /// (e.g. "Superset mit Rudern vorgebeugt"). Empty if standalone.
    static func partnerNames(of planExercise: PlanExercise, in allPlanExercises: [PlanExercise]) -> [String] {
        guard let groupID = planExercise.supersetGroupID else { return [] }
        return allPlanExercises
            .filter { $0.supersetGroupID == groupID && $0.id != planExercise.id }
            .compactMap { $0.exercise?.name }
    }
}
