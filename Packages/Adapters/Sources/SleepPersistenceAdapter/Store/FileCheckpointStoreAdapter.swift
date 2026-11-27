import Foundation
import SleepCore
import SleepDomain
import SleepFiles

/// `RecordingCheckpointStorePort` over the shared `NightCheckpoint`: one atomic
/// JSON file of the night in progress, the same file SleepGuard writes.
struct FileCheckpointStoreAdapter: RecordingCheckpointStorePort {
  private let file: NightCheckpoint

  init(url: URL) {
    file = NightCheckpoint(url: url)
  }

  func save(_ night: Night) async {
    await file.save(night)
  }

  func load() async -> Night? {
    await file.load()
  }

  func clear() async {
    await file.clear()
  }
}
