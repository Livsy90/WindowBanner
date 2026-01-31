import SwiftUI

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
