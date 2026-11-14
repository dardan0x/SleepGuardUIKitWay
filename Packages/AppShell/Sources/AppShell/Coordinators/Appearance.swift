import SleepGuardDesignKit
import SwiftUI
import UIKit

/// UIKit chrome in the brand's theme, so bars match the SwiftUI content.
/// Set per bar instance, never through global `UIAppearance` proxies.
enum Appearance {
  static func apply(_ theme: Theme, to navigationBar: UINavigationBar) {
    let palette = theme.palette
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(palette.bgPrimary)
    appearance.shadowColor = .clear
    appearance.titleTextAttributes = [
      .foregroundColor: UIColor(palette.textPrimary),
      .font: font(theme, style: .headline, weight: .semibold),
    ]
    appearance.largeTitleTextAttributes = [
      .foregroundColor: UIColor(palette.textPrimary),
      .font: font(theme, style: .largeTitle, weight: .bold),
    ]
    navigationBar.standardAppearance = appearance
    navigationBar.compactAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
    navigationBar.tintColor = UIColor(palette.accent)
  }

  /// The theme's type design in UIKit, at the system size for `style`.
  static func font(_ theme: Theme, style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
    let base = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)
    let design: UIFontDescriptor.SystemDesign = switch theme.typography.design {
    case .rounded: .rounded
    case .serif: .serif
    case .monospaced: .monospaced
    default: .default
    }
    guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
    return UIFont(descriptor: descriptor, size: base.pointSize)
  }

  static func apply(_ theme: Theme, to tabBar: UITabBar) {
    let palette = theme.palette
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(palette.bgSecondary)
    for item in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
      item.normal.iconColor = UIColor(palette.tabInactive)
      item.normal.titleTextAttributes = [.foregroundColor: UIColor(palette.tabInactive)]
      item.selected.iconColor = UIColor(palette.accent)
      item.selected.titleTextAttributes = [.foregroundColor: UIColor(palette.accent)]
    }
    tabBar.standardAppearance = appearance
    tabBar.scrollEdgeAppearance = appearance
    tabBar.tintColor = UIColor(palette.accent)
  }
}
