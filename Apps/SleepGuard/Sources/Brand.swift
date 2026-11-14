import AppShell
import SleepGuardDesignKit

/// SleepGuard: the full product in the original look. The shared scene
/// delegate reads `appBrand`, this target's one brand entry point.
nonisolated struct SleepGuardBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .sleepGuard,
    tabs: [.statistics, .history, .settings, .learn])
}

let appBrand = SleepGuardBrand()
