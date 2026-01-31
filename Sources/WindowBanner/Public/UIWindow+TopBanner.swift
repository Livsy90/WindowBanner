import UIKit

public extension UIWindow {
    /// Shows banner visibility.
    var isBannerPresented: Bool {
        isBannerVisible
    }
    
    /// Presents a top banner for this window with optional per-call configuration.
    /// - Parameters:
    ///   - config: Optional builder that lets you override appearance for this call without changing global defaults.
    func presentTopBanner(
        config: ((inout TopBannerConfigBuilder) -> Void)? = nil
    ) {
        if let config {
            var builder = TopBannerConfigBuilder()
            config(&builder)
            self.currentBannerAppearance = builder.build()
            
        }
        presentBanner()
        isBannerVisible = true
    }
    
    /// Dismiss a top banner.
    func dismissTopBanner() {
        isBannerVisible = false
    }
}
