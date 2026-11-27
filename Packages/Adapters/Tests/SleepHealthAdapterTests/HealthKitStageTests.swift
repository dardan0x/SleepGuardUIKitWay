import HealthKit
import SleepCore
import SleepHealthKit
import Testing
@testable import SleepHealthAdapter

/// HealthKit's sleep values map to stages as in SleepGuard; anything not
/// staged (our own "asleep" night sample, in bed) is no stage.
struct HealthKitStageTests {
  @Test func stagedValuesMapToStages() {
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepCore.rawValue) == .light)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepDeep.rawValue) == .deep)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepREM.rawValue) == .rem)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.awake.rawValue) == .awake)
  }

  @Test func unstagedValuesAreNoStage() {
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue) == nil)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.inBed.rawValue) == nil)
    #expect(HealthKitSleep.stage(for: 99) == nil)
  }
}
