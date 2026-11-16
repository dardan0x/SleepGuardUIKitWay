import Foundation
import SleepCore

/// Throws a recorded night away: its clips, then its checkpoint.
///
/// A use case because it coordinates two ports. Clips go first: if the app
/// dies in between, the checkpoint is offered again and discarding again
/// finishes the job.
public struct DiscardRecording: Sendable {
  private let checkpoints: any RecordingCheckpointStore
  private let files: any SessionFileStore

  public init(checkpoints: any RecordingCheckpointStore, files: any SessionFileStore) {
    self.checkpoints = checkpoints
    self.files = files
  }

  /// `nil`: nothing was recorded (the microphone never started).
  public func callAsFunction(_ night: Night?) async {
    if let night {
      await files.removeFiles(named: night.events.compactMap(\.clipFileName))
    }
    await checkpoints.clear()
  }
}
