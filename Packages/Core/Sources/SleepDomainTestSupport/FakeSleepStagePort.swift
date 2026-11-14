import Foundation
import SleepCore
import SleepDomain

/// Returns preset stages, or throws when `fails`, and records each request.
public actor FakeSleepStagePort: SleepStagePort {
  public struct Failure: Error {}

  private let stages: [SleepStageSegment]
  private let fails: Bool
  public private(set) var requests: [(start: Date, end: Date)] = []

  public init(stages: [SleepStageSegment] = [], fails: Bool = false) {
    self.stages = stages
    self.fails = fails
  }

  public func stages(from start: Date, to end: Date) async throws -> [SleepStageSegment] {
    requests.append((start, end))
    if fails { throw Failure() }
    return stages
  }
}
