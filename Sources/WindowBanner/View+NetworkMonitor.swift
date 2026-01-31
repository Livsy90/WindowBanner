//
//  WindowBannerConfig.swift
//  WindowBanner
//
//  Created by Artem Mir on 31.01.26.
//


/// Network monitoring utilities for SwiftUI.
///
/// This file provides a SwiftUI `ViewModifier` and helpers to monitor network connectivity
/// using `NWPathMonitor` and expose the result to the current `UIWindow` via a custom property
/// (`isNetworkAvailable`). It also includes a `WindowExtractor` to access the hosting window
/// from SwiftUI view hierarchy, and a simple preview demonstrating usage.
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
            NetworkMonitoringView(
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

public struct WindowBannerConfig {
    /// Text shown when the primary state is active.
    let title: String
    
    /// Background color for the primary state.
    let backgroundColor: UIColor
    
    /// Text color used for the status label in the primary state.
    let textColor: UIColor
    
    /// Banner height in points.
    let height: CGFloat
    
    /// Top padding for the status label inside the banner.
    let titleTopInset: CGFloat
    
    /// Font used for the status label.
    let font: UIFont
    
    public init(
        title: String,
        backgroundColor: UIColor = .systemGreen,
        textColor: UIColor = .white,
        height: CGFloat = 80,
        titleTopInset: CGFloat = 20,
        font: UIFont = .systemFont(ofSize: 17, weight: .semibold)
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.height = height
        self.titleTopInset = titleTopInset
        self.font = font
    }
}

/// Internal helper to observe the `UIWindow` a SwiftUI view is hosted in.
private extension View {
    /// Calls `perform` whenever the underlying `UIWindow` changes for this view.
    ///
    /// This uses a transparent `UIViewRepresentable` to detect `didMoveToWindow` events.
    /// - Parameter perform: Closure invoked with the current window (or `nil`).
    /// - Returns: A view that triggers the closure whenever the window changes.
    func onChangeWindow(_ perform: @escaping (UIWindow?) -> Void) -> some View {
        background {
            WindowExtractor(onExtract: perform)
        }
    }
}

/// A `UIViewRepresentable` that exposes the containing `UIWindow` to SwiftUI.
///
/// Embeds a lightweight `UIView` subclass that notifies when it moves to a window so that
/// SwiftUI views can react to window changes.
private struct WindowExtractor: UIViewRepresentable {
    let onExtract: (UIWindow?) -> Void

    /// Minimal `UIView` that reports window changes via `didMoveToWindow`.
    @MainActor
    final class ViewWithWindow: UIView {
        /// Callback invoked whenever the view is attached to a new window.
        var onMoveToWindow: ((UIWindow?) -> Void)
        /// Tracks the last observed window to avoid duplicate notifications.
        private weak var lastWindow: UIWindow?

        /// Creates the reporting view.
        /// - Parameter onMoveToWindow: Closure called with the current window when it changes.
        init(onMoveToWindow: (@escaping (UIWindow?) -> Void)) {
            self.onMoveToWindow = onMoveToWindow
            super.init(frame: .null)

            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// Notifies when the view is moved to a different window.
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window !== lastWindow else { return }
            lastWindow = window
            onMoveToWindow(window)
        }
    }

    /// Creates the reporting view and wires the extraction callback.
    func makeUIView(context: Context) -> ViewWithWindow {
        ViewWithWindow(onMoveToWindow: onExtract)
    }

    /// Keeps the callback up to date if the closure changes across SwiftUI updates.
    func updateUIView(_ uiView: ViewWithWindow, context: Context) {
        uiView.onMoveToWindow = onExtract
    }
}

/// A `ViewModifier` that observes network connectivity and updates the hosting window.
private struct NetworkMonitoringView: ViewModifier {
    
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

        if !isConnected {
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

