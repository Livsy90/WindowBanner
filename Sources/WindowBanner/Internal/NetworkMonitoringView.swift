import SwiftUI
import Network
import Combine

/// A `ViewModifier` that observes network connectivity and updates the hosting window.
struct NetworkMonitoringViewModifier: ViewModifier {
    
    /// Configuration controlling the appearance and content of the banner shown when there is no internet connection.
    /// Typically includes a title string, background color (e.g., red), and text color (e.g., white).
    let noConnectionConfig: WindowBannerConfig
    
    /// Configuration controlling the appearance and content of the banner shown briefly after network connectivity is restored.
    /// Typically includes a title string, background color (e.g., green or teal), and text color.
    let restoredConfig: WindowBannerConfig
    
    /// Delay before auto-hiding the banner after connection is restored.
    let hideDelay: TimeInterval
    /// Shared monitor that publishes connectivity changes on the main actor.
    @StateObject private var monitor = NetworkMonitor()
    /// The current hosting window for the modified view (if available).
    @State private var window: UIWindow?
    /// Task used to schedule auto-hide; cancelled when new status arrives.
    @State private var hideTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChangeWindow { window in
                self.window = window
                apply(for: monitor.hasNetworkConnection)
            }
            .onChange(of: monitor.hasNetworkConnection) { newValue in
                apply(for: newValue)
            }
    }

    /// Applies banner appearance and visibility based on connectivity.
    private func apply(for isConnected: Bool) {
        // Cancel any scheduled hide when status changes.
        hideTask?.cancel()

        guard let window else { return }

        if !window.isBannerPresented && !isConnected {
            // No internet: show red banner with offline text.
            window.presentTopBanner { config in
                config
                    .title(noConnectionConfig.title)
                    .backgroundColor(noConnectionConfig.backgroundColor)
                    .textColor(noConnectionConfig.textColor)
            }
        } else if window.isBannerPresented && isConnected {
            // Restored: show green banner briefly, then hide after delay.
            window.presentTopBanner { config in
                config
                    .title(restoredConfig.title)
                    .backgroundColor(restoredConfig.backgroundColor)
                    .textColor(restoredConfig.textColor)
            }
            // Schedule auto-hide
            hideTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(hideDelay * 1_000_000_000))
                if !Task.isCancelled {
                    window.dismissTopBanner()
                }
            }
        } else {
            window.dismissTopBanner()
        }
    }
}

/// Observes network path status using `NWPathMonitor` and publishes a simple boolean.
///
/// Updates occur on the main actor to integrate cleanly with SwiftUI state.
@MainActor
final class NetworkMonitor: ObservableObject {
    /// Indicates whether the device currently has an active network path.
    @Published var hasNetworkConnection = true

    /// Underlying Network framework monitor.
    private let networkMonitor = NWPathMonitor()

    /// Starts monitoring network path changes and updates `hasNetworkConnection` accordingly.
    init() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.hasNetworkConnection = path.status == .satisfied
            }
        }

        networkMonitor.start(queue: DispatchQueue(label: "NetworkMonitorQueue"))
    }
}
