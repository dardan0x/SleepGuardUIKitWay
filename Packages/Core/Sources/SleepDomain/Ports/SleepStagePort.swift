import Foundation
import SleepCore

/// Sleep stages recorded by another source (Apple Watch through HealthKit).
/// Implemented by `SleepHealth` in brands that use it; brands without it bind a
/// port that always returns none (F8).
public protocol SleepStagePort: Sendable {
  /// Stages between `start` and `end`, with offsets relative to `start`.
  /// Empty when nothing was recorded or access isn't granted.
  func stages(from start: Date, to end: Date) async throws -> [SleepStageSegment]
}
