import Foundation
import SleepCore
import SleepDomain

/// The stage source of a brand without Apple Health (Lite): never any
/// stages. Brands with Health read them through their `HealthAccess`.
nonisolated struct NoSleepStages: SleepStagePort {
  func stages(from _: Date, to _: Date) async throws -> [SleepStageSegment] {
    []
  }
}
