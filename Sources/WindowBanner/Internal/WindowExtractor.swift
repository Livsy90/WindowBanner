import SwiftUI

/// A `UIViewRepresentable` that exposes the containing `UIWindow` to SwiftUI.
///
/// Embeds a lightweight `UIView` subclass that notifies when it moves to a window so that
/// SwiftUI views can react to window changes.
struct WindowExtractor: UIViewRepresentable {
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
