import AppShell
import SleepGuardDesignKit
import SleepHealth
import SwiftUI

/// Dawn: the worked example in `docs/ADDING_A_BRAND.md`. A warm sunrise
/// palette; Apple Health and its sleep stages, but no Snore Interrupter and
/// no Learn tab: a mix of capabilities none of the other brands has.
nonisolated struct DawnBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .dawn,
    tabs: [.statistics, .history, .settings],
    health: SleepHealth.makeHealthAccess(),
    appStoreID: nil,
    snoreInterrupter: false,
    learnURL: nil)
}

let appBrand = DawnBrand()

private extension Theme {
  /// Background and accent match the `LaunchBackground` and `BrandAccent` assets.
  nonisolated static let dawn: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#1A1210")
    theme.palette.bgSecondary = Color(hex: "#24170F")
    theme.palette.bgCard = Color(hex: "#2E1E14")
    theme.palette.bgElevated = Color(hex: "#44301F")
    theme.palette.border = Color(hex: "#44301F")
    theme.palette.accent = Color(hex: "#FF9A5C")
    theme.palette.tabInactive = Color(hex: "#A08A78")
    theme.palette.textTertiary = Color(hex: "#B09A88")
    return theme
  }()
}
