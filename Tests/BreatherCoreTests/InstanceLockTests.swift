import XCTest
@testable import BreatherCore

final class InstanceLockTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("BreatherLockTests.\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func testFirstAcquireSucceeds() {
        guard case .acquired = InstanceLock.acquire(in: directory) else {
            return XCTFail("first acquire should succeed")
        }
    }

    func testSecondAcquireIsRejected() {
        guard case .acquired(let first) = InstanceLock.acquire(in: directory) else {
            return XCTFail("first acquire should succeed")
        }

        withExtendedLifetime(first) {
            guard case .alreadyRunning = InstanceLock.acquire(in: directory) else {
                return XCTFail("second acquire while the first is held should report alreadyRunning")
            }
        }
    }

    func testLockIsReusableAfterRelease() {
        do {
            guard case .acquired = InstanceLock.acquire(in: directory) else {
                return XCTFail("first acquire should succeed")
            }
        }

        guard case .acquired = InstanceLock.acquire(in: directory) else {
            return XCTFail("lock should be acquirable after the previous holder is released")
        }
    }

    func testUnusableDirectoryDegradesInsteadOfBlocking() throws {
        let fileAsDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("BreatherLockFile.\(UUID().uuidString)")
        FileManager.default.createFile(atPath: fileAsDirectory.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: fileAsDirectory) }

        guard case .unavailable = InstanceLock.acquire(in: fileAsDirectory.appendingPathComponent("sub")) else {
            return XCTFail("an unusable lock directory must degrade, not report alreadyRunning")
        }
    }
}
