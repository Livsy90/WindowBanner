# WindowBanner — Window‑Scoped iOS Banner with optional Network Monitoring

<video src="https://github.com/Livsy90/WindowBanner/blob/main/WindowBanner.mp4" controls="controls" muted="muted" width="500"></video>


A lightweight, **window-scoped** top banner for iOS that shows short status messages, **pushes content down** via safe‑area insets, and includes a ready‑to‑use SwiftUI network monitoring integration built on top of the same UIWindow infrastructure.

It enables both manual banner presentation and automatic system‑level feedback such as offline/online state handling.

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
```

## How it works

WindowBanner attaches a BannerView to a UIWindow and animates it using Auto Layout constraints:
- The banner is added as a subview of the window and pinned
- Visibility is animated by changing the banner’s top constraint from `-height` → `0`
- Content is pushed down by adjusting:
  - `window.rootViewController?.additionalSafeAreaInsets.top`

The banner’s state is stored per window using Objective-C associated objects (banner view, constraints, current appearance, orientation observer, etc.).

## Usage

### Present with configuration:

```swift
window.presentTopBanner { config in
    config
        .title("Connected")
        .backgroundColor(.systemGreen)
        .textColor(.white)
        .height(80)
        .titleTopInset(20)
        .font(.systemFont(ofSize: 17, weight: .semibold))
}
```

Dismiss:

```swift
window.dismissTopBanner()
```

3) Update appearance while visible

Calling `presentTopBanner` again updates the banner in-place.
If the banner is already on screen, changes are applied with a cross-dissolve transition.

```swift
window.presentTopBanner { config in
    config
        .title("No Internet")
        .backgroundColor(.systemRed)
}
```

## Default appearance

If you don’t provide any configuration, the banner uses defaults:
- `title`: `""`
- `backgroundColor`: `systemGreen`
- `textColor`: `white`
- `height`: `80`
- `titleTopInset`: `20`
- `font`: system semibold 17

## Orientation behavior

The implementation optionally switches to a compact style in landscape via effectiveAppearance(from:):
- Landscape height becomes smaller (e.g. `18`)
- Inset becomes `0`
- Font becomes smaller

This is applied automatically on UIDevice.orientationDidChangeNotification.

## Network Monitoring (SwiftUI)

WindowBanner can be combined with a small SwiftUI modifier to provide global network status feedback using the same `UIWindow` banner infrastructure.

This example shows how connectivity changes are reflected automatically at the window level.

```swift
ContentView()
    .networkMonitoring(
        hideDelay: 2.0,
        noConnectionConfig: .init(
            title: "No Internet Connection",
            backgroundColor: .systemRed,
            textColor: .white,
            height: 80,
            titleTopInset: 20,
            font: .systemFont(ofSize: 17, weight: .semibold)
        ),
        restoredConfig: .init(
            title: "Back Online",
            backgroundColor: .systemTeal,
            textColor: .white,
            height: 80,
            titleTopInset: 20,
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
    )
```

### How it works

- A lightweight `NWPathMonitor` observes network reachability
- The current `UIWindow` is extracted from SwiftUI using `UIViewRepresentable`
- Connectivity changes trigger:
  - Persistent banner when offline
  - Temporary confirmation banner when connection is restored
- All layout shifting is handled automatically via safe-area insets

This keeps network feedback centralized at the window level and avoids per-screen banner logic.
Attach the modifier to your root view to ensure global network state handling across the entire app.

## UIWindow API Summary

- `isBannerPresented: Bool`
  Shows banner visibility for that window

- `presentTopBanner(config: ((inout TopBannerConfigBuilder) -> Void)? = nil)`
  Shows the banner and optionally overrides appearance values
  
- `dismissTopBanner()`
  Hides the banner and optionally overrides appearance values

- `TopBannerConfigBuilder`
  Chainable configuration for title, colors, font, height, and top inset
