import XCTest
@testable import GymTrack

final class SupersetGroupingTests: XCTestCase {

    // MARK: group

    func testGroupingTwoExercisesAssignsTheSameSharedGroupID() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let row = Exercise(name: "Rudern vorgebeugt", muscleGroup: .back)
        let plan = TrainingPlan(name: "Push/Pull")
        let a = PlanExercise(order: 0, plan: plan, exercise: bench)
        let b = PlanExercise(order: 1, plan: plan, exercise: row)

        SupersetGrouping.group([a, b], allPlanExercises: [a, b])

        XCTAssertNotNil(a.supersetGroupID)
        XCTAssertEqual(a.supersetGroupID, b.supersetGroupID)
    }

    func testGroupingThreeExercisesAssignsAllTheSameGroupID() {
        let plan = TrainingPlan(name: "Ganzkörper")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        let c = PlanExercise(order: 2, plan: plan)

        SupersetGrouping.group([a, b, c], allPlanExercises: [a, b, c])

        XCTAssertEqual(a.supersetGroupID, b.supersetGroupID)
        XCTAssertEqual(b.supersetGroupID, c.supersetGroupID)
    }

    func testGroupingFewerThanTwoExercisesIsANoOp() {
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan)

        SupersetGrouping.group([a], allPlanExercises: [a])
        XCTAssertNil(a.supersetGroupID)

        SupersetGrouping.group([], allPlanExercises: [a])
        // Just confirming it doesn't crash on an empty selection.
    }

    func testRegroupingExercisesThatWereInDifferentGroupsUnifiesThemIntoOneNewGroup() {
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        SupersetGrouping.group([a, b], allPlanExercises: [a, b])
        let originalGroupID = a.supersetGroupID

        let c = PlanExercise(order: 2, plan: plan)
        SupersetGrouping.group([a, c], allPlanExercises: [a, b, c])

        XCTAssertNotEqual(a.supersetGroupID, originalGroupID)
        XCTAssertEqual(a.supersetGroupID, c.supersetGroupID)
    }

    func testRegroupingASubsetOfATwoMemberGroupUngroupsTheExerciseLeftBehind() {
        // A+B are grouped. The user re-enters grouping mode but only reselects A (forgetting
        // B) together with a brand-new C. B must not keep a supersetGroupID shared with
        // nobody — with only 1 member left behind, it has to be ungrouped entirely, exactly
        // like SupersetGrouping.leave would do.
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        SupersetGrouping.group([a, b], allPlanExercises: [a, b])

        let c = PlanExercise(order: 2, plan: plan)
        SupersetGrouping.group([a, c], allPlanExercises: [a, b, c])

        XCTAssertNil(b.supersetGroupID)
        XCTAssertEqual(a.supersetGroupID, c.supersetGroupID)
    }

    func testRegroupingASubsetOfAThreeMemberGroupLeavesTheOtherTwoStillGrouped() {
        // A+B+C are grouped. The user reselects A together with a new D, leaving B+C behind.
        // B and C still have each other, so they must stay grouped together (just no longer
        // with A) rather than being ungrouped.
        let plan = TrainingPlan(name: "Ganzkörper")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        let c = PlanExercise(order: 2, plan: plan)
        SupersetGrouping.group([a, b, c], allPlanExercises: [a, b, c])

        let d = PlanExercise(order: 3, plan: plan)
        SupersetGrouping.group([a, d], allPlanExercises: [a, b, c, d])

        XCTAssertEqual(a.supersetGroupID, d.supersetGroupID)
        XCTAssertNotNil(b.supersetGroupID)
        XCTAssertEqual(b.supersetGroupID, c.supersetGroupID)
        XCTAssertNotEqual(b.supersetGroupID, a.supersetGroupID)
    }

    // MARK: ungroup

    func testUngroupClearsTheGroupIDOnEveryGivenExercise() {
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        SupersetGrouping.group([a, b], allPlanExercises: [a, b])

        SupersetGrouping.ungroup([a, b])

        XCTAssertNil(a.supersetGroupID)
        XCTAssertNil(b.supersetGroupID)
    }

    // MARK: leave

    func testLeavingATwoMemberGroupDissolvesBothMembers() {
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        SupersetGrouping.group([a, b], allPlanExercises: [a, b])

        SupersetGrouping.leave(a, from: [a, b])

        XCTAssertNil(a.supersetGroupID, "A superset of one isn't meaningful — the group must fully dissolve")
        XCTAssertNil(b.supersetGroupID)
    }

    func testLeavingAThreeMemberGroupLeavesTheOtherTwoStillGrouped() {
        let plan = TrainingPlan(name: "Ganzkörper")
        let a = PlanExercise(order: 0, plan: plan)
        let b = PlanExercise(order: 1, plan: plan)
        let c = PlanExercise(order: 2, plan: plan)
        SupersetGrouping.group([a, b, c], allPlanExercises: [a, b, c])

        SupersetGrouping.leave(a, from: [a, b, c])

        XCTAssertNil(a.supersetGroupID)
        XCTAssertNotNil(b.supersetGroupID)
        XCTAssertEqual(b.supersetGroupID, c.supersetGroupID)
    }

    func testLeavingAnUngroupedExerciseIsANoOp() {
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan)

        SupersetGrouping.leave(a, from: [a])

        XCTAssertNil(a.supersetGroupID)
    }

    // MARK: partnerNames

    func testPartnerNamesListsTheOtherMembersOfTheSameGroup() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let row = Exercise(name: "Rudern vorgebeugt", muscleGroup: .back)
        let plan = TrainingPlan(name: "Push/Pull")
        let a = PlanExercise(order: 0, plan: plan, exercise: bench)
        let b = PlanExercise(order: 1, plan: plan, exercise: row)
        SupersetGrouping.group([a, b], allPlanExercises: [a, b])

        XCTAssertEqual(SupersetGrouping.partnerNames(of: a, in: [a, b]), ["Rudern vorgebeugt"])
        XCTAssertEqual(SupersetGrouping.partnerNames(of: b, in: [a, b]), ["Bankdrücken"])
    }

    func testPartnerNamesIsEmptyForAnUngroupedExercise() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan, exercise: bench)

        XCTAssertTrue(SupersetGrouping.partnerNames(of: a, in: [a]).isEmpty)
    }

    func testPartnerNamesExcludesTheExerciseItself() {
        let bench = Exercise(name: "Bankdrücken", muscleGroup: .chest)
        let plan = TrainingPlan(name: "Push")
        let a = PlanExercise(order: 0, plan: plan, exercise: bench)
        let other = PlanExercise(order: 1, plan: plan)
        SupersetGrouping.group([a, other], allPlanExercises: [a, other])

        XCTAssertFalse(SupersetGrouping.partnerNames(of: a, in: [a]).contains("Bankdrücken"))
    }
}
