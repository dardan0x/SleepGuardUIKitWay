import Observation
import UIKit

/// How a screen looks in the navigation bar, described as a value.
///
/// UIKit owns the bar: `ScreenController` applies this to its `navigationItem`.
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

public extension ScreenChrome {
  /// Title and bar items onto a screen's navigation item; returns each item
  /// with its button. `ScreenController` calls it, keeps the buttons of
  /// items with an activity up to date, and applies `hidesNavigationBar` on
  /// appearing.
  @discardableResult
  func apply(to navigationItem: UINavigationItem) -> [(item: BarItem, button: UIBarButtonItem)] {
    navigationItem.title = title
    navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
    let buttons = trailingItems.map { item in
      let button = UIBarButtonItem(
        image: UIImage(systemName: item.systemImage),
        primaryAction: UIAction { _ in item.action() })
      button.accessibilityLabel = item.accessibilityLabel
      return (item: item, button: button)
    }
    navigationItem.rightBarButtonItems = buttons.reversed().map(\.button)
    return buttons
  }
}

/// An icon button in the navigation bar. `accessibilityLabel` is required:
/// the button has no visible text. With an `activity`, the button is
/// disabled and shows a spinner (read as `activity.label`) while it runs.
public struct BarItem {
  public let systemImage: String
  public let accessibilityLabel: String
  public let activity: BarItemActivity?
  public let action: @MainActor () -> Void

  public init(
    systemImage: String,
    accessibilityLabel: String,
    activity: BarItemActivity? = nil,
    action: @escaping @MainActor () -> Void)
  {
    self.systemImage = systemImage
    self.accessibilityLabel = accessibilityLabel
    self.activity = activity
    self.action = action
  }
}

/// Whether a bar item's work is running (making a report). Whoever runs the
/// work sets `isRunning`; the screen's button follows it.
@MainActor
@Observable
public final class BarItemActivity {
  public var isRunning = false
  /// What VoiceOver reads while it runs ("Generating report").
  public let label: String

  public init(label: String) {
    self.label = label
  }
}
