import AppShell
import SleepGuardDesignKit
import SleepHealthAdapter

/// SleepGuard: the full product in the original look. The shared scene
/// delegate reads `appBrand`, this target's one brand entry point.
nonisolated struct SleepGuardBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .sleepGuard,
    tabs: [.statistics, .history, .settings, .learn],
    health: SleepHealthAdapter.makeHealthAccess(),
    appStoreID: nil,
    snoreInterrupter: true,
    // No Learn page yet: the tab shows "No content available".
    learnURL: nil)
}

let appBrand = SleepGuardBrand()
