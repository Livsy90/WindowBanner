import SwiftUI
import Network

/// Adds live network connectivity monitoring to any SwiftUI view.
///
/// The modifier observes network status via `NWPathMonitor` and updates the hosting UIWindow with
/// the current connectivity state. You can use this to adjust UI or behavior based on connectivity.
///
/// Usage:
/// ```swift
/// SomeView()
///     .networkMonitoring()
/// ```
///
/// - Parameters:
///   - hideDelay: Time interval in seconds before the restored connectivity banner automatically hides. Default is 2.0 seconds.
///   - noConnectionConfig: Configuration for the banner shown when there is no internet connection (offline state).
///   - restoredConfing: Configuration for the banner shown briefly after connectivity is restored (online state).
///
/// - Returns: A view modified to show a top banner on network connectivity changes, reflecting offline and restored states.
public extension View {
    func networkMonitoring(
        hideDelay: TimeInterval = 2.0,
        noConnectionConfig: WindowBannerConfig,
        restoredConfing: WindowBannerConfig,
    ) -> some View {
        modifier(
            NetworkMonitoringViewModifier(
                noConnectionConfig: noConnectionConfig,
                restoredConfig: restoredConfing,
                hideDelay: hideDelay
            )
        )
    }
}

/// Example preview demonstrating how to attach the network monitoring modifier to a view hierarchy.
@available(iOS 16.0)
#Preview {
    NavigationStack {
        Text("Content")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "person.fill")
                }
            }
            .navigationTitle("Home")
    }
    .networkMonitoring(
        noConnectionConfig: .init(
            title: "No Internet Connection",
            backgroundColor: .red
        ),
        restoredConfing: .init(
            title: "Internet Connection Restored",
            backgroundColor: .systemTeal
        )
    )
}

