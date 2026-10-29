import XCTest
@testable import BreatherCore

final class AppInfoTests: XCTestCase {
    func testVersionIsNotEmpty() {
        XCTAssertFalse(AppInfo.version.isEmpty)
    }
}
