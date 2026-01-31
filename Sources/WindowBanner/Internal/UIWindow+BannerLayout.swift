import ObjectiveC
import UIKit

/// Keys for Objective‑C associated objects used to keep per-window state.
@MainActor
private enum AssociatedKeys {
    static var bannerView: UInt8 = 0
    static var bannerTopConstraint: UInt8 = 0
    static var bannerHeightConstraint: UInt8 = 0
    static var originalTopInset: UInt8 = 0
    static var isBannerPresented: UInt8 = 0
    static var currentAppearance: UInt8 = 0
    static var orientationObserver: UInt8 = 0
}

extension UIWindow {
    /// Holds appearance values for the banner.
    ///
    /// Instances of this class represent a complete set of styling values. A single
    /// instance per window can be used to customize appearance.
    struct TopBannerAppearance {
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
        
        /// Default appearance used when no per-window appearance is provided.
        @MainActor
        static let `default` = TopBannerAppearance(
            title: "",
            backgroundColor: .systemGreen,
            textColor: .white,
            height: 80,
            titleTopInset: 20,
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        
        /// Designated initializer for a complete appearance description.
        init(
            title: String,
            backgroundColor: UIColor,
            textColor: UIColor,
            height: CGFloat,
            titleTopInset: CGFloat,
            font: UIFont
        ) {
            self.title = title
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.height = height
            self.titleTopInset = titleTopInset
            self.font = font
        }
    }
}

extension UIWindow {
    /// Builder for overriding appearance of the banner.
    ///
    /// Use with `topBanner(isPresented:config:)` to selectively change
    /// text, colors, typography, and layout metrics.
    @MainActor
    public final class TopBannerConfigBuilder {
        /// Optional override for the text.
        private var title: String?
        /// Optional override for the background color.
        private var backgroundColor: UIColor?
        /// Optional override for the text color.
        private var textColor: UIColor?
        /// Optional override for the banner height.
        private var height: CGFloat?
        /// Optional override for the label's top padding.
        private var titleTopInset: CGFloat?
        /// Optional override for the label font.
        private var font: UIFont?
        
        /// Creates an empty builder.
        public init() {}
        
        /// Sets the primary text.
        @discardableResult public func title(_ value: String) -> Self {
            self.title = value
            return self
        }
        /// Sets the primary background color.
        @discardableResult public func backgroundColor(_ value: UIColor) -> Self {
            self.backgroundColor = value
            return self
        }
        /// Sets the primary text color.
        @discardableResult public func textColor(_ value: UIColor) -> Self {
            self.textColor = value
            return self
        }
        /// Sets the banner height.
        @discardableResult public func height(_ value: CGFloat) -> Self {
            self.height = value
            return self
        }
        /// Sets the label's top padding.
        @discardableResult public func titleTopInset(_ value: CGFloat) -> Self {
            self.titleTopInset = value
            return self
        }
        /// Sets the label font.
        @discardableResult public func font(_ value: UIFont) -> Self {
            self.font = value
            return self
        }
        
        /// Builds a concrete appearance by merging overrides with local defaults.
        ///
        /// Values not set on the builder fall back to local defaults.
        func build() -> TopBannerAppearance {
            TopBannerAppearance(
                title: title ?? TopBannerAppearance.default.title,
                backgroundColor: backgroundColor ?? TopBannerAppearance.default.backgroundColor,
                textColor: textColor ?? TopBannerAppearance.default.textColor,
                height: height ?? TopBannerAppearance.default.height,
                titleTopInset: titleTopInset ?? TopBannerAppearance.default.titleTopInset,
                font: font ?? TopBannerAppearance.default.font
            )
        }
    }
}

extension UIWindow {
    /// Controls visibility of the banner for this window.
    /// Set to `true` to show the banner, `false` to hide it. Changes are dispatched to the main queue and animated.
    var isBannerVisible: Bool {
        get {
            (objc_getAssociatedObject(self, &AssociatedKeys.isBannerPresented) as? Bool) ?? false
        }
        set {
            let current = (objc_getAssociatedObject(self, &AssociatedKeys.isBannerPresented) as? Bool) ?? false
            guard current != newValue else { return }
            objc_setAssociatedObject(self, &AssociatedKeys.isBannerPresented, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            DispatchQueue.main.async { [weak self] in
                if newValue {
                    self?.presentBanner()
                } else {
                    self?.removeBanner()
                }
            }
        }
    }
}

extension UIWindow {
    /// Per-window banner instance stored via associated objects.
    var bannerView: BannerView? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.bannerView) as? BannerView }
        set { objc_setAssociatedObject(self, &AssociatedKeys.bannerView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Stores the top constraint used for Auto Layout of the banner.
    var bannerTopConstraint: NSLayoutConstraint? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.bannerTopConstraint) as? NSLayoutConstraint }
        set { objc_setAssociatedObject(self, &AssociatedKeys.bannerTopConstraint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Stores the height constraint used for Auto Layout of the banner.
    var bannerHeightConstraint: NSLayoutConstraint? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.bannerHeightConstraint) as? NSLayoutConstraint }
        set { objc_setAssociatedObject(self, &AssociatedKeys.bannerHeightConstraint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Stores the original top safe area inset before the banner pushes content down.
    var originalTopSafeAreaInset: CGFloat? {
        get {
            if let number = objc_getAssociatedObject(self, &AssociatedKeys.originalTopInset) as? NSNumber {
                return CGFloat(number.floatValue)
            }
            return nil
        }
        set {
            if let v = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.originalTopInset, v as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                objc_setAssociatedObject(self, &AssociatedKeys.originalTopInset, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    /// Stores the current banner appearance per window.
    var currentBannerAppearance: TopBannerAppearance? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.currentAppearance) as? TopBannerAppearance }
        set { objc_setAssociatedObject(self, &AssociatedKeys.currentAppearance, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Stores the orientation change observer token for this window.
    var orientationObserver: NSObjectProtocol? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.orientationObserver) as? NSObjectProtocol }
        set { objc_setAssociatedObject(self, &AssociatedKeys.orientationObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Returns an adjusted appearance based on current orientation.
    func effectiveAppearance(from appearance: TopBannerAppearance) -> TopBannerAppearance {
        if isLandscape {
            return TopBannerAppearance(
                title: appearance.title,
                backgroundColor: appearance.backgroundColor,
                textColor: appearance.textColor,
                height: 18,
                titleTopInset: 0,
                font: .systemFont(ofSize: 14, weight: .semibold)
            )
        } else {
            return appearance
        }
    }
    
    /// Ensures the banner exists, configures it, and animates it into view.
    /// Uses Auto Layout constraints and animates the top constraint to show the banner.
    /// Adjusts window's root view controller additionalSafeAreaInsets.top to push content below the banner.
    func presentBanner() {
        makeBannerIfNeeded()
        configureBanner()
        guard let bannerView else { return }
        let appearance = currentBannerAppearance ?? .default
        let effective = effectiveAppearance(from: appearance)
        
        if bannerView.superview == nil {
            addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            
            let leading = bannerView.leadingAnchor.constraint(equalTo: leadingAnchor)
            let trailing = bannerView.trailingAnchor.constraint(equalTo: trailingAnchor)
            let heightConstraint = bannerView.heightAnchor.constraint(equalToConstant: effective.height)
            NSLayoutConstraint.activate([
                leading,
                trailing,
                heightConstraint
            ])
            self.bannerHeightConstraint = heightConstraint
            
            // Use safeAreaLayoutGuide.topAnchor instead of topAnchor
            let topConstraint = bannerView.topAnchor.constraint(equalTo: topAnchor, constant: -effective.height)
            topConstraint.isActive = true
            self.bannerTopConstraint = topConstraint
            layoutIfNeeded()
        }
        
        guard let topConstraint = self.bannerTopConstraint else { return }
        topConstraint.constant = 0
        
        // Capture original safe area inset if not set
        if originalTopSafeAreaInset == nil {
            originalTopSafeAreaInset = rootViewController?.additionalSafeAreaInsets.top ?? 0
        }
        let targetTopInset = (originalTopSafeAreaInset ?? 0) + effective.height - 20
        
        // Animate banner slide-in and content shift via safe area
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            // Move banner from -height to 0
            self.layoutIfNeeded()
            // Shift content down by increasing safe area
            self.rootViewController?.additionalSafeAreaInsets.top = targetTopInset
            self.rootViewController?.view.layoutIfNeeded()
        }, completion: { _ in
            self.hardSync()
        })
        
        // Register for orientation changes if not already registered
        if orientationObserver == nil {
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.configureBanner()
                    if self.isBannerVisible {
                        let effectiveAppearance = self.effectiveAppearance(from: self.currentBannerAppearance ?? .default)
                        self.bannerHeightConstraint?.constant = effectiveAppearance.height
                        self.bannerTopConstraint?.constant = 0
                        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
                            self.layoutIfNeeded()
                            let baseInset = self.originalTopSafeAreaInset ?? 0
                            self.rootViewController?.additionalSafeAreaInsets.top = baseInset + effectiveAppearance.height - 20
                            self.rootViewController?.view.layoutIfNeeded()
                        }, completion: { _ in
                            self.hardSync()
                        })
                    }
                }
            }
        }
    }
    
    /// Lazily creates the banner view sized to the window's width and the configured height.
    func makeBannerIfNeeded() {
        if self.bannerView == nil {
            let banner = BannerView(
                frame: CGRect(x: 0,y: 0, width: self.bounds.width, height: (currentBannerAppearance?.height ?? TopBannerAppearance.default.height))
            )
            banner.translatesAutoresizingMaskIntoConstraints = false
            self.bannerView = banner
        }
    }
    
    /// Applies primary appearance to the banner.
    func configureBanner() {
        let appearance = currentBannerAppearance ?? .default
        let effective = effectiveAppearance(from: appearance)
        guard let banner = self.bannerView else { return }

        // If banner already in hierarchy, cross-fade text/color changes smoothly.
        let isInHierarchy = banner.superview != nil
        if isInHierarchy {
            UIView.transition(with: banner, duration: 0.2, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
                banner.configure(
                    text: effective.title,
                    backgroundColor: effective.backgroundColor,
                    height: effective.height,
                    titleTopInset: effective.titleTopInset,
                    font: effective.font,
                    textColor: effective.textColor
                )
            }
        } else {
            banner.configure(
                text: effective.title,
                backgroundColor: effective.backgroundColor,
                height: effective.height,
                titleTopInset: effective.titleTopInset,
                font: effective.font,
                textColor: effective.textColor
            )
        }
    }
    
    /// Animates the banner out and removes it from the hierarchy upon completion.
    /// Uses Auto Layout to animate the top constraint to hide the banner.
    /// Restores window's root view controller additionalSafeAreaInsets.top to original inset.
    func removeBanner() {
        guard let banner = self.bannerView, let topConstraint = self.bannerTopConstraint else { return }

        let baseAppearance = currentBannerAppearance ?? .default
        let effective = effectiveAppearance(from: baseAppearance)
        topConstraint.constant = -effective.height
        
        let base = originalTopSafeAreaInset ?? 0
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) { [self] in
            // Animate banner slide-out by applying the updated top constraint
            layoutIfNeeded()
            // Restore safe area to original so content moves back up
            rootViewController?.additionalSafeAreaInsets.top = base
            rootViewController?.view.layoutIfNeeded()
            hardSync()
        } completion: { _ in
            banner.removeFromSuperview()
            self.bannerTopConstraint = nil
            self.originalTopSafeAreaInset = nil
            
            if let token = self.orientationObserver {
                NotificationCenter.default.removeObserver(token)
                self.orientationObserver = nil
            }
        }
    }
    
    /// Hard sync to force UIScrollView to commit safe area changes
    private func hardSync() {
        if let rootView = rootViewController?.view {
            var frame = rootView.frame
            frame.size.height += 0.01
            rootView.frame = frame
            frame.size.height -= 0.01
            rootView.frame = frame
            rootView.setNeedsLayout()
            rootView.layoutIfNeeded()
        }
    }
    
    /// Simple top-aligned banner view containing a centered status label.
    final class BannerView: UIView {
        
        /// Cached height used for layout and animations.
        private var bannerHeight: CGFloat = TopBannerAppearance.default.height
        /// Top padding for the label; mirrored to the top constraint's constant.
        private var titleTopInset: CGFloat = TopBannerAppearance.default.titleTopInset
        
        /// The label that displays the status text. Configured for dynamic truncation.
        private let titleLabel: UILabel = {
            let label = UILabel()
            label.baselineAdjustment = .alignBaselines
            label.adjustsFontSizeToFitWidth = true
            label.allowsDefaultTighteningForTruncation = true
            label.minimumScaleFactor = 0.5
            label.clipsToBounds = false
            label.backgroundColor = .clear
            label.textAlignment = .center
            
            return label
        }()
        
        /// Holds the top constraint of the titleLabel to adjust its top inset dynamically.
        private var topConstraint: NSLayoutConstraint?
        
        /// Initializes the banner and sets up constraints.
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            configureLayout()
        }
        
        /// Unavailable. Use programmatic initialization.
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        /// Applies appearance and content to the banner.
        /// - Parameters:
        ///   - text: The status message to display.
        ///   - backgroundColor: The banner background color.
        ///   - height: The banner height in points.
        ///   - titleTopInset: The top padding for the label.
        ///   - font: The font for the status label.
        ///   - textColor: The text color for the status label for the current state.
        ///
        /// Updates the stored layout metrics and adjusts the existing top constraint to match `titleTopInset`.
        func configure(
            text: String,
            backgroundColor: UIColor,
            height: CGFloat,
            titleTopInset: CGFloat,
            font: UIFont,
            textColor: UIColor
        ) {
            self.backgroundColor = backgroundColor
            titleLabel.text = text
            self.bannerHeight = height
            self.titleTopInset = titleTopInset
            titleLabel.font = font
            titleLabel.textColor = textColor

            topConstraint?.constant = titleTopInset
        }
        
        /// Adds and pins the status label to the banner with a configurable top inset.
        private func configureLayout() {
            addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let top = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: titleTopInset)
            topConstraint = top
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
                top
            ])
        }
    }
}

private extension UIWindow {
    /// Returns true if the window is currently in landscape orientation.
    var isLandscape: Bool {
        if let scene = windowScene {
            if #available(iOS 26.0, *) {
                return scene.effectiveGeometry.interfaceOrientation.isLandscape
            } else {
                return scene.interfaceOrientation.isLandscape
            }
        }
        // Fallbacks if windowScene is unavailable
        if traitCollection.verticalSizeClass == .compact && traitCollection.horizontalSizeClass == .regular {
            return true
        }
        return UIDevice.current.orientation.isLandscape
    }
}
