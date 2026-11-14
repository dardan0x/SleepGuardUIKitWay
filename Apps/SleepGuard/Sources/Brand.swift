import AppShell
import SleepGuardDesignKit

/// This target's brand: what the shell needs that differs from other brands.
/// The shared scene delegate reads `appBrand`, the target's one brand entry point.
nonisolated struct SleepGuardBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .sleepGuard,
    tabs: [.statistics, .history, .settings, .learn])
}

let appBrand = SleepGuardBrand()
