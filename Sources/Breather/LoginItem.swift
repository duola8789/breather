import Foundation
import ServiceManagement

enum LoginItem {
    enum Result {
        case enabled
        case disabled
        case failed(String)
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) -> Result {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
                return .enabled
            } else {
                try SMAppService.mainApp.unregister()
                return .disabled
            }
        } catch {
            NSLog("Breather: login item update failed: \(error)")
            return .failed(error.localizedDescription)
        }
    }
}
