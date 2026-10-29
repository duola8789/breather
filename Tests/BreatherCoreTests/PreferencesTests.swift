import XCTest
@testable import BreatherCore

final class PreferencesTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "BreatherTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultValuesMatchOriginalApp() {
        let prefs = Preferences(defaults: defaults)

        XCTAssertEqual(prefs.workPeriod, 45)
        XCTAssertEqual(prefs.breakPeriod, 5)
        XCTAssertEqual(prefs.postponePeriod, 5)
        XCTAssertEqual(prefs.popupSecond, 10)
        XCTAssertFalse(prefs.forceBreak)
        XCTAssertTrue(prefs.showIndicatorBeforeBreak)
        XCTAssertTrue(prefs.showPopupBeforeBreak)
        XCTAssertTrue(prefs.ringBellOnBreakStart)
        XCTAssertTrue(prefs.ringBellOnBreakEnd)
        XCTAssertFalse(prefs.autoCloseBreakOverlay)
    }

    func testReadingDoesNotWrite() {
        let prefs = Preferences(defaults: defaults)
        _ = prefs.workPeriod
        _ = prefs.breakPeriod
        _ = prefs.postponePeriod
        _ = prefs.popupSecond
        _ = prefs.forceBreak
        _ = prefs.showIndicatorBeforeBreak
        _ = prefs.showPopupBeforeBreak
        _ = prefs.ringBellOnBreakStart
        _ = prefs.ringBellOnBreakEnd
        _ = prefs.autoCloseBreakOverlay

        let stored = defaults.persistentDomain(forName: suiteName) ?? [:]
        XCTAssertTrue(stored.isEmpty, "reading preferences must not persist anything, got: \(stored)")
    }

    func testWritesPersistAcrossInstances() {
        let writer = Preferences(defaults: defaults)
        writer.workPeriod = 30
        writer.breakPeriod = 8
        writer.forceBreak = true
        writer.autoCloseBreakOverlay = true

        let reader = Preferences(defaults: UserDefaults(suiteName: suiteName)!)
        XCTAssertEqual(reader.workPeriod, 30)
        XCTAssertEqual(reader.breakPeriod, 8)
        XCTAssertTrue(reader.forceBreak)
        XCTAssertTrue(reader.autoCloseBreakOverlay)
        XCTAssertEqual(reader.postponePeriod, 5, "untouched keys keep their defaults")
    }
}
