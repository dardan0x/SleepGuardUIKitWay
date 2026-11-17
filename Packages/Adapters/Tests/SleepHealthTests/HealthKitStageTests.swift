import HealthKit
import SleepCore
import Testing
@testable import SleepHealth

/// HealthKit's sleep values map to stages as in SleepGuard; anything not
/// staged (our own "asleep" night sample, in bed) is no stage.
struct HealthKitStageTests {
  @Test func stagedValuesMapToStages() {
    #expect(HealthKitAccess.stage(for: HKCategoryValueSleepAnalysis.asleepCore.rawValue) == .light)
    #expect(HealthKitAccess.stage(for: HKCategoryValueSleepAnalysis.asleepDeep.rawValue) == .deep)
    #expect(HealthKitAccess.stage(for: HKCategoryValueSleepAnalysis.asleepREM.rawValue) == .rem)
    #expect(HealthKitAccess.stage(for: HKCategoryValueSleepAnalysis.awake.rawValue) == .awake)
  }

  @Test func unstagedValuesAreNoStage() {
    #expect(HealthKitAccess.stage(for: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue) == nil)
    #expect(HealthKitAccess.stage(for: HKCategoryValueSleepAnalysis.inBed.rawValue) == nil)
    #expect(HealthKitAccess.stage(for: 99) == nil)
  }
}
