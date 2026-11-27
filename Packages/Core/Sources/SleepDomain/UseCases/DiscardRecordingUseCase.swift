import Foundation
import SleepCore

/// Throws a recorded night away: its clips, then its checkpoint.
///
/// A use case because it coordinates two ports. Clips go first: if the app
/// dies in between, the checkpoint is offered again and discarding again
/// finishes the job.
public struct DiscardRecordingUseCase: Sendable {
  private let checkpoints: any RecordingCheckpointStorePort
  private let files: any SessionFileStorePort

  public init(checkpoints: any RecordingCheckpointStorePort, files: any SessionFileStorePort) {
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
