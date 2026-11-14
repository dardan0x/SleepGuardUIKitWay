import SleepGuardDesignKit
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
    appearance.titleTextAttributes = [.foregroundColor: UIColor(palette.textPrimary)]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(palette.textPrimary)]
    navigationBar.standardAppearance = appearance
    navigationBar.compactAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
    navigationBar.tintColor = UIColor(palette.accent)
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
