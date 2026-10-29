import XCTest
@testable import BreatherCore

final class ClockTests: XCTestCase {
    func testSystemClockReturnsCurrentTime() {
        let before = Date()
        let now = SystemClock().now
        let after = Date()

        XCTAssertGreaterThanOrEqual(now, before)
        XCTAssertLessThanOrEqual(now, after)
    }
}
