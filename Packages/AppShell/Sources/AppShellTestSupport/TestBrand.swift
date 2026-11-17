import AppShell
import Foundation
import SleepDomain
import SleepGuardDesignKit

/// A brand for shell tests: any theme and tab list.
public nonisolated struct TestBrand: BrandComposition {
  public let configuration: BrandConfiguration

  public init(
    theme: Theme = .sleepGuard, tabs: [AppTab] = AppTab.allCases, health: (any HealthAccess)? = nil,
    appStoreID: String? = nil, snoreInterrupter: Bool = false, learnURL: URL? = nil)
  {
    configuration = BrandConfiguration(
      theme: theme, tabs: tabs, health: health, appStoreID: appStoreID, snoreInterrupter: snoreInterrupter,
      learnURL: learnURL)
  }
}
