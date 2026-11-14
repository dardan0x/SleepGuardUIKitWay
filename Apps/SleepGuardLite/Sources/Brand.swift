import AppShell
import SleepGuardDesignKit
import SwiftUI

/// SleepGuard Lite: teal, three tabs (no Learn), no HealthKit (it doesn't link
/// `SleepHealth`; see `Brand.usesHealthKit` in the Tuist brand list).
nonisolated struct SleepGuardLiteBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .lite,
    tabs: [.statistics, .history, .settings])
}

let appBrand = SleepGuardLiteBrand()

private extension Theme {
  /// SleepGuard's tokens with a teal identity. Background and accent match the
  /// `LaunchBackground` and `BrandAccent` assets.
  nonisolated static let lite: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#0B1A1A")
    theme.palette.bgSecondary = Color(hex: "#102424")
    theme.palette.bgCard = Color(hex: "#16302F")
    theme.palette.bgElevated = Color(hex: "#244240")
    theme.palette.border = Color(hex: "#2A4A47")
    theme.palette.accent = Color(hex: "#2EC4B6")
    return theme
  }()
}
