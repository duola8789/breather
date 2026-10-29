import XCTest
@testable import BreatherCore

final class SliderIconTests: XCTestCase {
    func testCasesStayInMenuOrder() {
        XCTAssertEqual(SliderIcon.allCases, [.tortoise, .dog, .cat, .person, .hare])
    }

    func testSymbolNames() {
        XCTAssertEqual(SliderIcon.tortoise.symbolName, "tortoise.fill")
        XCTAssertEqual(SliderIcon.dog.symbolName, "dog.fill")
        XCTAssertEqual(SliderIcon.cat.symbolName, "cat.fill")
        XCTAssertEqual(SliderIcon.person.symbolName, "figure.walk")
        XCTAssertEqual(SliderIcon.hare.symbolName, "hare.fill")
    }

    func testOpticalHeights() {
        XCTAssertEqual(SliderIcon.tortoise.opticalHeight, 12)
        XCTAssertEqual(SliderIcon.dog.opticalHeight, 15)
        XCTAssertEqual(SliderIcon.cat.opticalHeight, 15)
        XCTAssertEqual(SliderIcon.person.opticalHeight, 16)
        XCTAssertEqual(SliderIcon.hare.opticalHeight, 14)
    }

    func testStoredValuesRoundTrip() {
        for icon in SliderIcon.allCases {
            XCTAssertEqual(SliderIcon(stored: icon.rawValue), icon)
        }
    }

    func testUnknownOrMissingStoredValueFallsBackToDefault() {
        XCTAssertEqual(SliderIcon(stored: "dragon"), .tortoise)
        XCTAssertEqual(SliderIcon(stored: ""), .tortoise)
        XCTAssertEqual(SliderIcon(stored: "TORTOISE"), .tortoise)
    }
}

final class SliderGeometryTests: XCTestCase {
    private let width = 240.0
    private let inset = 10.0

    func testProgressAtEndpointsAndMiddle() {
        XCTAssertEqual(SliderGeometry.progress(forX: 10, width: width, inset: inset), 0, accuracy: 0.0001)
        XCTAssertEqual(SliderGeometry.progress(forX: 120, width: width, inset: inset), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SliderGeometry.progress(forX: 230, width: width, inset: inset), 1, accuracy: 0.0001)
    }

    func testProgressClampsOutsideTheTrack() {
        XCTAssertEqual(SliderGeometry.progress(forX: -40, width: width, inset: inset), 0, accuracy: 0.0001)
        XCTAssertEqual(SliderGeometry.progress(forX: 400, width: width, inset: inset), 1, accuracy: 0.0001)
    }

    func testXRoundTripsThroughProgress() {
        for progress in [0.0, 0.25, 0.5, 0.75, 1.0] {
            let x = SliderGeometry.x(forProgress: progress, width: width, inset: inset)
            XCTAssertEqual(
                SliderGeometry.progress(forX: x, width: width, inset: inset),
                progress,
                accuracy: 0.0001
            )
        }
    }

    func testXClampsProgress() {
        XCTAssertEqual(SliderGeometry.x(forProgress: -1, width: width, inset: inset), inset, accuracy: 0.0001)
        XCTAssertEqual(SliderGeometry.x(forProgress: 2, width: width, inset: inset), width - inset, accuracy: 0.0001)
    }

    func testDegenerateTrackDoesNotDivideByZero() {
        XCTAssertEqual(SliderGeometry.progress(forX: 0, width: 10, inset: 10), 0, accuracy: 0.0001)
        XCTAssertEqual(SliderGeometry.x(forProgress: 0.5, width: 10, inset: 10), 5, accuracy: 0.0001)
    }
}
