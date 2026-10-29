import XCTest
@testable import BreatherCore

final class TimerEngineTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var preferences: Preferences!
    private var clock: TestClock!

    override func setUp() {
        super.setUp()
        suiteName = "BreatherTimerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        preferences = Preferences(defaults: defaults)
        self.clock = TestClock(TestCalendar.date(2026, 10, 28, 9, 0, 0))
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        preferences = nil
        clock = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeEngine() -> TimerEngine {
        TimerEngine(clock: clock, preferences: preferences, calendar: TestCalendar.calendar)
    }

    // MARK: - 3.2 Work -> rest

    func testWorkPhaseEndEntersRest() {
        let engine = makeEngine()
        clock.advance(45 * 60)

        engine.tick(now: clock.now)

        XCTAssertEqual(engine.state.phase, .rest)
        XCTAssertEqual(engine.remaining(), 5 * 60, accuracy: 0.001)
        XCTAssertTrue(engine.state.isSnoozeAvailable)
    }

    func testSingleJumpAdvancesOnlyOnePhase() {
        let engine = makeEngine()
        clock.advance(3 * 60 * 60)

        engine.tick(now: clock.now)

        XCTAssertEqual(engine.state.phase, .rest)
        XCTAssertEqual(engine.remaining(), 5 * 60, accuracy: 0.001, "break must start fresh, not expire from the jump")
    }

    // MARK: - 3.3 Pause / resume

    func testPauseFreezesRemaining() {
        let engine = makeEngine()
        clock.advance(15 * 60)

        engine.pause(now: clock.now)
        clock.advance(20 * 60)

        XCTAssertTrue(engine.state.isPaused)
        XCTAssertEqual(engine.remaining(), 30 * 60, accuracy: 0.001)
    }

    func testResumeContinuesFromFrozenRemaining() {
        let engine = makeEngine()
        clock.advance(15 * 60)
        engine.pause(now: clock.now)
        clock.advance(20 * 60)

        engine.resume(now: clock.now)
        clock.advance(5 * 60)

        XCTAssertFalse(engine.state.isPaused)
        XCTAssertEqual(engine.state.phase, .work)
        XCTAssertEqual(engine.remaining(), 25 * 60, accuracy: 0.001)
    }

    // MARK: - 3.4 Snooze

    func testSnoozeRejectedBeforeWindow() {
        let engine = makeEngine()
        clock.advance(10 * 60)

        engine.snooze(multiplier: 1, now: clock.now)

        XCTAssertEqual(engine.remaining(), 35 * 60, accuracy: 0.001)
        XCTAssertTrue(engine.state.isSnoozeAvailable)
    }

    func testSnoozeExtendsRemainingByStep() {
        let engine = makeEngine()
        clock.advance(45 * 60 - 10)

        engine.snooze(multiplier: 1, now: clock.now)

        XCTAssertEqual(engine.state.phase, .work)
        XCTAssertEqual(engine.remaining(), 5 * 60 + 10, accuracy: 0.001)
        XCTAssertFalse(engine.state.isSnoozeAvailable)
    }

    func testSnoozeMultipliers() {
        let engine = makeEngine()
        clock.advance(45 * 60 - 10)

        engine.snooze(multiplier: 2, now: clock.now)
        XCTAssertEqual(engine.remaining(), 10 * 60 + 10, accuracy: 0.001)

        let second = makeEngine()
        clock.advance(45 * 60 - 10)
        second.snooze(multiplier: 3, now: clock.now)
        XCTAssertEqual(second.remaining(), 15 * 60 + 10, accuracy: 0.001)
    }

    func testSnoozeCappedAtWorkPeriod() {
        preferences.workPeriod = 5
        let engine = makeEngine()
        clock.advance(5 * 60 - 10)

        engine.snooze(multiplier: 3, now: clock.now)

        XCTAssertEqual(engine.remaining(), 5 * 60, accuracy: 0.001)
    }

    func testSnoozeAllowedOnlyOncePerCycle() {
        let engine = makeEngine()
        clock.advance(45 * 60 - 10)
        engine.snooze(multiplier: 1, now: clock.now)
        let afterFirst = engine.remaining()

        clock.advance(afterFirst - 10)
        engine.snooze(multiplier: 1, now: clock.now)

        XCTAssertEqual(engine.remaining(), 10, accuracy: 0.001, "a second snooze in the same work cycle must be ignored")
    }

    // MARK: - 3.6 Rest completion requires confirmation

    func testRestCompletionAwaitsConfirmation() {
        let engine = makeEngine()
        clock.advance(45 * 60)
        engine.tick(now: clock.now)

        clock.advance(5 * 60)
        engine.tick(now: clock.now)

        XCTAssertEqual(engine.state.phase, .restEnded)

        clock.advance(10 * 60)
        engine.tick(now: clock.now)
        XCTAssertEqual(engine.state.phase, .restEnded, "restEnded must wait for the user")

        engine.confirmBreakEnded(now: clock.now)
        XCTAssertEqual(engine.state.phase, .work)
        XCTAssertEqual(engine.remaining(), 45 * 60, accuracy: 0.001)
    }

    // MARK: - 3.7 End break early

    func testEndBreakEarlyReturnsToWork() {
        let engine = makeEngine()
        clock.advance(45 * 60)
        engine.tick(now: clock.now)
        clock.advance(60)

        engine.endBreakEarly(now: clock.now)

        XCTAssertEqual(engine.state.phase, .work)
        XCTAssertEqual(engine.remaining(), 45 * 60, accuracy: 0.001)
    }

    func testEndBreakEarlyRejectedWithForceBreak() {
        preferences.forceBreak = true
        let engine = makeEngine()
        clock.advance(45 * 60)
        engine.tick(now: clock.now)
        clock.advance(60)

        engine.endBreakEarly(now: clock.now)

        XCTAssertEqual(engine.state.phase, .rest)
    }

    // MARK: - 3.8 Force break blocks pausing in the last seconds

    func testPauseRejectedInLastTenSecondsWithForceBreak() {
        preferences.forceBreak = true
        let engine = makeEngine()
        clock.advance(45 * 60 - 5)

        engine.pause(now: clock.now)

        XCTAssertFalse(engine.state.isPaused)
    }

    func testPauseAllowedEarlierInWorkWithForceBreak() {
        preferences.forceBreak = true
        let engine = makeEngine()
        clock.advance(10 * 60)

        engine.pause(now: clock.now)

        XCTAssertTrue(engine.state.isPaused)
    }

    func testForceBreakDoesNotBlockSnooze() {
        preferences.forceBreak = true
        let engine = makeEngine()
        clock.advance(45 * 60 - 10)

        engine.snooze(multiplier: 1, now: clock.now)

        XCTAssertEqual(engine.remaining(), 5 * 60 + 10, accuracy: 0.001)
    }

    // MARK: - 3.9 Cross-day auto resume

    func testPauseAutoResumesNextDayAtSeven() {
        let engine = makeEngine()
        engine.pause(now: clock.now)

        clock.now = TestCalendar.date(2026, 10, 29, 7, 0, 0)
        engine.tick(now: clock.now)

        XCTAssertFalse(engine.state.isPaused)
    }

    func testPauseNotResumedSameDay() {
        self.clock = TestClock(TestCalendar.date(2026, 10, 28, 6, 30, 0))
        let engine = makeEngine()
        engine.pause(now: clock.now)

        clock.now = TestCalendar.date(2026, 10, 28, 7, 0, 0)
        engine.tick(now: clock.now)

        XCTAssertTrue(engine.state.isPaused)
    }

    func testPauseNotResumedNextDayBeforeSeven() {
        let engine = makeEngine()
        engine.pause(now: clock.now)

        clock.now = TestCalendar.date(2026, 10, 29, 6, 59, 0)
        engine.tick(now: clock.now)

        XCTAssertTrue(engine.state.isPaused)
    }

    func testPauseHeldAcrossMidnightStaysPausedUntilMorning() {
        self.clock = TestClock(TestCalendar.date(2026, 10, 28, 23, 59, 0))
        let engine = makeEngine()
        engine.pause(now: clock.now)

        clock.now = TestCalendar.date(2026, 10, 28, 23, 59, 30)
        engine.tick(now: clock.now)
        XCTAssertTrue(engine.state.isPaused, "同一日内不得自动恢复")

        clock.now = TestCalendar.date(2026, 10, 29, 6, 59, 0)
        engine.tick(now: clock.now)
        XCTAssertTrue(engine.state.isPaused, "次日 07:00 之前不得自动恢复")

        clock.now = TestCalendar.date(2026, 10, 29, 7, 0, 0)
        engine.tick(now: clock.now)
        XCTAssertFalse(engine.state.isPaused, "次日 07:00 应自动恢复")
    }

    // MARK: - 3.10 Sleep / wall clock

    func testWakeAfterLongSleepDuringWorkMovesToRest() {
        let engine = makeEngine()
        clock.advance(20 * 60)
        XCTAssertEqual(engine.remaining(), 25 * 60, accuracy: 0.001)

        clock.advance(3 * 60 * 60)
        engine.tick(now: clock.now)

        XCTAssertEqual(engine.state.phase, .rest)
        XCTAssertEqual(engine.remaining(), 5 * 60, accuracy: 0.001)
    }

    // MARK: - 3.11 Persistence across relaunch

    private func makePersistedEngine() -> TimerEngine {
        TimerEngine(
            clock: clock,
            preferences: preferences,
            store: UserDefaultsTimerStateStore(defaults: defaults),
            calendar: TestCalendar.calendar
        )
    }

    func testWorkPhaseResumesAfterRelaunch() {
        _ = makePersistedEngine()
        clock.advance(12 * 60)

        let relaunched = makePersistedEngine()

        XCTAssertEqual(relaunched.state.phase, .work)
        XCTAssertEqual(relaunched.remaining(), 33 * 60, accuracy: 0.001)
    }

    func testBreakExpiringWhileClosedLandsInRestEnded() {
        let first = makePersistedEngine()
        clock.advance(45 * 60)
        first.tick(now: clock.now)
        XCTAssertEqual(first.state.phase, .rest)

        clock.advance(10 * 60)

        let relaunched = makePersistedEngine()
        XCTAssertEqual(relaunched.state.phase, .restEnded)
    }

    func testPausedStateSurvivesRelaunch() {
        let first = makePersistedEngine()
        clock.advance(15 * 60)
        first.pause(now: clock.now)
        clock.advance(30 * 60)

        let relaunched = makePersistedEngine()

        XCTAssertTrue(relaunched.state.isPaused)
        XCTAssertEqual(relaunched.remaining(), 30 * 60, accuracy: 0.001)
    }

    // MARK: - 3.1 Skeleton

    func testInitialStateIsWorkWithFullDuration() {
        let engine = makeEngine()

        XCTAssertEqual(engine.state.phase, .work)
        XCTAssertEqual(engine.remaining(), 45 * 60, accuracy: 0.001)
        XCTAssertFalse(engine.state.isPaused)
        XCTAssertTrue(engine.state.isSnoozeAvailable)
    }
}
