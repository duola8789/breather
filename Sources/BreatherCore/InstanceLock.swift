import Foundation

public enum InstanceLockAcquisition {
    case acquired(InstanceLock)
    case alreadyRunning
    /// Lock infrastructure is unusable (disk full, permissions, sandbox).
    /// The caller should log and continue running without a lock.
    case unavailable(Error)
}

/// Advisory exclusive lock backed by `flock`, held for the process lifetime.
public final class InstanceLock {
    private let fileDescriptor: Int32

    private init(fileDescriptor: Int32) {
        self.fileDescriptor = fileDescriptor
    }

    deinit {
        close(fileDescriptor)
    }

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent(AppInfo.bundleIdentifier, isDirectory: true)
    }

    public static func acquire(in directory: URL) -> InstanceLockAcquisition {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return .unavailable(error)
        }

        let path = directory.appendingPathComponent("instance.lock").path
        let fd = open(path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else {
            return .unavailable(POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO))
        }

        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            let code = errno
            close(fd)
            if code == EWOULDBLOCK {
                return .alreadyRunning
            }
            return .unavailable(POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO))
        }

        return .acquired(InstanceLock(fileDescriptor: fd))
    }
}
