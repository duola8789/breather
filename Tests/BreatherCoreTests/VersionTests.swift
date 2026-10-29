import XCTest
@testable import BreatherCore

final class VersionTests: XCTestCase {
    func testNumericNotLexical() {
        XCTAssertTrue(Version.isNewer("1.10.0", than: "1.9.0"))
        XCTAssertFalse(Version.isNewer("1.9.0", than: "1.10.0"))
    }

    func testSameVersionIsNotNewer() {
        XCTAssertFalse(Version.isNewer("1.0.0", than: "1.0.0"))
    }

    func testMissingComponentsCountAsZero() {
        XCTAssertTrue(Version.isNewer("1.1", than: "1.0.9"))
        XCTAssertFalse(Version.isNewer("1.0", than: "1.0.0"))
        XCTAssertTrue(Version.isNewer("2", than: "1.9.9"))
    }

    func testMajorBeatsMinor() {
        XCTAssertTrue(Version.isNewer("2.0.0", than: "1.99.99"))
        XCTAssertFalse(Version.isNewer("1.99.99", than: "2.0.0"))
    }
}
