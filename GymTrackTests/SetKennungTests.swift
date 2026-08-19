import XCTest
@testable import GymTrack

final class SetKennungTests: XCTestCase {

    func testNormalSetsAreNumberedSequentiallyStartingAtOne() {
        let a = SetEntry(order: 0, setType: .normal)
        let b = SetEntry(order: 1, setType: .normal)
        let c = SetEntry(order: 2, setType: .normal)

        let labels = SetKennung.labels(for: [a, b, c])

        XCTAssertEqual(labels[a.id], "1")
        XCTAssertEqual(labels[b.id], "2")
        XCTAssertEqual(labels[c.id], "3")
    }

    func testWarmupSetsAreAllLabeledA() {
        let warmup1 = SetEntry(order: 0, setType: .warmup)
        let warmup2 = SetEntry(order: 1, setType: .warmup)

        let labels = SetKennung.labels(for: [warmup1, warmup2])

        XCTAssertEqual(labels[warmup1.id], "A")
        XCTAssertEqual(labels[warmup2.id], "A")
    }

    func testDropsetsAreAllLabeledD() {
        let normal = SetEntry(order: 0, setType: .normal)
        let drop1 = SetEntry(order: 1, setType: .dropset)
        let drop2 = SetEntry(order: 2, setType: .dropset)

        let labels = SetKennung.labels(for: [normal, drop1, drop2])

        XCTAssertEqual(labels[drop1.id], "D")
        XCTAssertEqual(labels[drop2.id], "D")
    }

    func testWarmupAndDropsetsDoNotAffectNormalSetNumbering() {
        let warmup = SetEntry(order: 0, setType: .warmup)
        let firstNormal = SetEntry(order: 1, setType: .normal)
        let drop = SetEntry(order: 2, setType: .dropset)
        let secondNormal = SetEntry(order: 3, setType: .normal)

        let labels = SetKennung.labels(for: [warmup, firstNormal, drop, secondNormal])

        XCTAssertEqual(labels[warmup.id], "A")
        XCTAssertEqual(labels[firstNormal.id], "1")
        XCTAssertEqual(labels[drop.id], "D")
        XCTAssertEqual(labels[secondNormal.id], "2")
    }

    func testEmptyListProducesEmptyLabels() {
        XCTAssertTrue(SetKennung.labels(for: []).isEmpty)
    }

    func testConvenienceLookupForASingleSetMatchesTheBatchResult() {
        let a = SetEntry(order: 0, setType: .normal)
        let b = SetEntry(order: 1, setType: .dropset)
        XCTAssertEqual(SetKennung.label(for: b, in: [a, b]), "D")
    }

    func testUnilateralNormalSetsCountEachSideIndependently() {
        let leftFirst = SetEntry(order: 0, setType: .normal, side: .left)
        let rightFirst = SetEntry(order: 1, setType: .normal, side: .right)
        let leftSecond = SetEntry(order: 2, setType: .normal, side: .left)
        let rightSecond = SetEntry(order: 3, setType: .normal, side: .right)

        let labels = SetKennung.labels(for: [leftFirst, rightFirst, leftSecond, rightSecond])

        XCTAssertEqual(labels[leftFirst.id], "1 L")
        XCTAssertEqual(labels[rightFirst.id], "1 R")
        XCTAssertEqual(labels[leftSecond.id], "2 L")
        XCTAssertEqual(labels[rightSecond.id], "2 R")
    }

    func testUnilateralAndBilateralSetsInTheSameExerciseCountSeparately() {
        // Defensive: shouldn't happen via the normal builder flow, but if a plan-exercise's
        // unilateral flag changes mid-history, bilateral (no side) and unilateral sets must
        // not share one counter.
        let bilateral = SetEntry(order: 0, setType: .normal, side: nil)
        let left = SetEntry(order: 1, setType: .normal, side: .left)

        let labels = SetKennung.labels(for: [bilateral, left])

        XCTAssertEqual(labels[bilateral.id], "1")
        XCTAssertEqual(labels[left.id], "1 L")
    }
}
