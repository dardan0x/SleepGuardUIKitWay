import Foundation
import SleepCore

/// At launch: a night the app didn't get to finish (crash, kill, dead
/// battery), to offer for Save or Discard.
///
/// A use case because it applies SleepGuard's rule: only a night with events
/// is worth offering. One without is cleared silently, along with any clips.
public struct RecoverInterruptedSessionUseCase: Sendable {
  private let checkpoints: any RecordingCheckpointStorePort
  private let files: any SessionFileStorePort

  public init(checkpoints: any RecordingCheckpointStorePort, files: any SessionFileStorePort) {
    self.checkpoints = checkpoints
    self.files = files
  }

  /// The night to offer, or `nil`. The checkpoint stays until that night is
  /// saved or discarded, so a second crash still finds it.
  public func callAsFunction() async -> Night? {
    guard let night = await checkpoints.load() else { return nil }
    guard night.events.isEmpty else { return night }
    await DiscardRecordingUseCase(checkpoints: checkpoints, files: files)(night)
    return nil
  }
}
