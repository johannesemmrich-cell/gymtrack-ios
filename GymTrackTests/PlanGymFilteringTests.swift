import XCTest
@testable import GymTrack

final class PlanGymFilteringTests: XCTestCase {

    func testNilGymIDReturnsAllPlansUnchanged() {
        let gym = Gym(name: "Fitness Park")
        let plans = [
            TrainingPlan(name: "Push"),
            TrainingPlan(name: "Pull", gym: gym)
        ]

        let result = PlanGymFiltering.filter(plans, byGymID: nil)

        XCTAssertEqual(result.map(\.name), ["Push", "Pull"])
    }

    func testSpecificGymIDReturnsMatchingPlansPlusGymlessPlans() {
        let gymA = Gym(name: "Fitness Park")
        let gymB = Gym(name: "McFit")
        let plans = [
            TrainingPlan(name: "Push", gym: gymA),
            TrainingPlan(name: "Pull", gym: gymB),
            TrainingPlan(name: "Ganzkörper")
        ]

        let result = PlanGymFiltering.filter(plans, byGymID: gymA.id)

        XCTAssertEqual(result.map(\.name), ["Push", "Ganzkörper"])
    }

    func testGymIDMatchingNoPlanReturnsOnlyGymlessPlans() {
        let gymA = Gym(name: "Fitness Park")
        let plans = [
            TrainingPlan(name: "Push", gym: gymA),
            TrainingPlan(name: "Ganzkörper")
        ]

        let result = PlanGymFiltering.filter(plans, byGymID: UUID())

        XCTAssertEqual(result.map(\.name), ["Ganzkörper"])
    }

    func testEmptyPlanListReturnsEmptyRegardlessOfFilter() {
        XCTAssertTrue(PlanGymFiltering.filter([], byGymID: nil).isEmpty)
        XCTAssertTrue(PlanGymFiltering.filter([], byGymID: UUID()).isEmpty)
    }

    func testPreservesOriginalOrder() {
        let gym = Gym(name: "Fitness Park")
        let plans = [
            TrainingPlan(name: "C", gym: gym),
            TrainingPlan(name: "A"),
            TrainingPlan(name: "B", gym: gym)
        ]

        let result = PlanGymFiltering.filter(plans, byGymID: gym.id)

        XCTAssertEqual(result.map(\.name), ["C", "A", "B"])
    }
}
