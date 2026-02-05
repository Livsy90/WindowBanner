import SwiftUI

/// Helper to observe the `UIWindow` a SwiftUI view is hosted in.
public extension View {
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
