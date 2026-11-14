import AppShell
import SleepGuardDesignKit

/// A brand for shell tests: any theme and tab list.
public nonisolated struct TestBrand: BrandComposition {
  public let configuration: BrandConfiguration

  public init(theme: Theme = .sleepGuard, tabs: [AppTab] = AppTab.allCases) {
    configuration = BrandConfiguration(theme: theme, tabs: tabs)
  }
}
