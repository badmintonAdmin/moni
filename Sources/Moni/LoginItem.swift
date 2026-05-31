import ServiceManagement

/// Thin wrapper around SMAppService for "launch at login" support.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns the resulting enabled state (best-effort; ignores errors so the
    /// UI toggle never traps).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // No-op: surfaced to the user via the (unchanged) toggle state.
        }
        return isEnabled
    }
}
