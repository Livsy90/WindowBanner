# WindowBanner

A lightweight, **window-scoped** top banner for iOS that shows a short status message and **pushes the content down** (via safe-area insets) while it’s visible.

This implementation is designed to work well with UIKit and SwiftUI content hosted inside a `UIWindow` / `UIHostingController`.

## Features

- Window-scoped banner (each `UIWindow` manages its own banner instance)
- Slide-in / slide-out animation from the top edge
- Pushes content down by updating `rootViewController?.additionalSafeAreaInsets.top`
- Per-call appearance overrides via a small builder API
- Orientation-aware appearance (optional compact style in landscape)
- Smooth cross-fade when updating banner text/colors while visible
- No global singleton, no dependency on view controller hierarchy beyond the window root

## Requirements

- iOS 15.0+

## Installation (Swift Package Manager)

Add the package to your project using Swift Package Manager.

### Xcode
1. Open **File → Add Packages…**
2. Paste the repository URL:

https://github.com/Livsy90/WindowBanner

3. Select the package and add it to your target(s)

### Package.swift
```swift
dependencies: [
 .package(url: "https://github.com/Livsy90/WindowBanner", branch: "main")
]

How it works

WindowBanner attaches a BannerView to a UIWindow and animates it using Auto Layout constraints:
    •    The banner is added as a subview of the window and pinned to leading/trailing.
    •    Visibility is animated by changing the banner’s top constraint from -height → 0.
    •    Content is pushed down by adjusting:
    •    window.rootViewController?.additionalSafeAreaInsets.top

The banner’s state is stored per window using Objective-C associated objects (banner view, constraints, current appearance, orientation observer, etc.).

Usage

1) Toggle visibility with a simple flag

// Show
window.isBannerVisible = true

// Hide
window.isBannerVisible = false

This uses the currently stored appearance for that window (or defaults if you never set one).

2) Present/hide with configuration (recommended)

Use topBanner(isPresented:config:) to both control visibility and override appearance values for that call:

window.topBanner(isPresented: true) { builder in
    builder
        .title("Connected")
        .backgroundColor(.systemGreen)
        .textColor(.white)
        .height(80)
        .titleTopInset(20)
        .font(.systemFont(ofSize: 17, weight: .semibold))
}

Hide it later:

window.topBanner(isPresented: false)

3) Update appearance while visible

Calling topBanner(isPresented:true, config:...) again updates the banner in-place.
If the banner is already on screen, changes are applied with a cross-dissolve transition.

window.topBanner(isPresented: true) { builder in
    builder
        .title("No Internet")
        .backgroundColor(.systemRed)
}

Default appearance

If you don’t provide any configuration, the banner uses defaults:
    •    title: ""
    •    backgroundColor: systemGreen
    •    textColor: white
    •    height: 80
    •    titleTopInset: 20
    •    font: system semibold 17

Orientation behavior

The implementation optionally switches to a compact style in landscape via effectiveAppearance(from:):
    •    landscape height becomes smaller (e.g. 18)
    •    inset becomes 0
    •    font becomes smaller

This is applied automatically on UIDevice.orientationDidChangeNotification.

If you prefer different rules (or no changes), adjust effectiveAppearance(from:).

Notes for SwiftUI and Scroll Views

This banner pushes content by modifying safe-area insets. Some scroll views (and SwiftUI layouts) can be sensitive to rapid safe-area changes.

The code includes a small “hard sync” layout nudge after animations to help the system commit the updated insets more reliably.

If you still see a one-frame “jump” in a specific layout:
    •    ensure you are not triggering competing animations at the same time (e.g. animated navigation bar changes)
    •    consider coordinating banner presentation with other top inset changes
    •    consider increasing animation duration slightly if content is heavy

Threading
    •    The public API dispatches to the main queue.
    •    The implementation is annotated with @MainActor where appropriate.

API Summary
    •    UIWindow.isBannerVisible: Bool
    •    toggles banner visibility for that window
    •    UIWindow.topBanner(isPresented: Bool, config: ((inout TopBannerConfigBuilder) -> Void)? = nil)
    •    shows/hides banner and optionally overrides appearance values
    •    TopBannerConfigBuilder
    •    chainable configuration for title, colors, font, height, and top inset
