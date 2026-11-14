import Foundation
import SleepCore
import SleepDomain

/// The stage source until HealthKit arrives (F8): never any stages. Brands
/// that use HealthKit will bind `SleepHealth` instead; Lite keeps this one.
nonisolated struct NoSleepStages: SleepStagePort {
  func stages(from _: Date, to _: Date) async throws -> [SleepStageSegment] {
    []
  }
}
