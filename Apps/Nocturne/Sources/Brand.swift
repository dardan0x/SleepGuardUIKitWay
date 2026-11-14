import AppShell
import SleepGuardDesignKit
import SwiftUI

/// Nocturne: a sister brand on the same product. Violet with amber for
/// recording, rounded type, softer corners; Sessions is the first tab.
nonisolated struct NocturneBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .nocturne,
    tabs: [.history, .statistics, .settings, .learn])
}

let appBrand = NocturneBrand()

private extension Theme {
  /// Background and accent match the `LaunchBackground` and `BrandAccent` assets.
  nonisolated static let nocturne: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#120A24")
    theme.palette.bgSecondary = Color(hex: "#1A1033")
    theme.palette.bgCard = Color(hex: "#221640")
    theme.palette.bgElevated = Color(hex: "#3A2C66")
    theme.palette.border = Color(hex: "#3A2C66")
    theme.palette.accent = Color(hex: "#9B7BFF")
    theme.palette.destructive = Color(hex: "#FFB547")
    theme.palette.tabInactive = Color(hex: "#8A80A8")
    theme.palette.textTertiary = Color(hex: "#9A90B8")
    theme.typography = Typography(design: .rounded)
    theme.radii = Radii(card: 24, small: 16)
    return theme
  }()
}
