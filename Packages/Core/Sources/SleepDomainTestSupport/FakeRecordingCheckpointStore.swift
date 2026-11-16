import Foundation
import SleepCore
import SleepDomain

/// Keeps the checkpoint in memory and every night it was given, in order.
public actor FakeRecordingCheckpointStore: RecordingCheckpointStore {
  public private(set) var night: Night?
  public private(set) var saved: [Night] = []
  public private(set) var clears = 0

  public init(_ night: Night? = nil) {
    self.night = night
  }

  public func save(_ night: Night) async {
    self.night = night
    saved.append(night)
  }

  public func load() async -> Night? {
    night
  }

  public func clear() async {
    night = nil
    clears += 1
  }
}
