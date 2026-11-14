import UIKit

/// How a screen looks in the navigation bar, described as a value.
///
/// UIKit owns the bar: `HostingScreen` applies this to its `navigationItem`.
/// Screens never call `.navigationTitle` or `.toolbar`, so one system writes
/// the bar, not two.
public struct ScreenChrome {
  public var title: String?
  public var largeTitle: Bool
  /// For full-bleed screens (the bedside clock).
  public var hidesNavigationBar: Bool
  public var trailingItems: [BarItem]

  public init(
    title: String? = nil,
    largeTitle: Bool = false,
    hidesNavigationBar: Bool = false,
    trailingItems: [BarItem] = [])
  {
    self.title = title
    self.largeTitle = largeTitle
    self.hidesNavigationBar = hidesNavigationBar
    self.trailingItems = trailingItems
  }
}

/// An icon button in the navigation bar. `accessibilityLabel` is required:
/// the button has no visible text.
public struct BarItem {
  public let systemImage: String
  public let accessibilityLabel: String
  public let action: @MainActor () -> Void

  public init(systemImage: String, accessibilityLabel: String, action: @escaping @MainActor () -> Void) {
    self.systemImage = systemImage
    self.accessibilityLabel = accessibilityLabel
    self.action = action
  }
}
