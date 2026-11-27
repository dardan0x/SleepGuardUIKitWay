import Foundation

/// "Delete all recordings": every night, every file in the clips folder (clips
/// and raw recordings), and a night left in the checkpoint. The profile and
/// the settings stay, as in SleepGuard.
///
/// A use case because it coordinates three ports. The records go first, as in
/// `DeleteSessionUseCase`: if removing files then fails, no night points at a
/// missing clip.
public struct DeleteAllDataUseCase: Sendable {
  private let sessions: any SessionRepositoryPort
  private let files: any SessionFileStorePort
  private let checkpoints: any RecordingCheckpointStorePort

  public init(sessions: any SessionRepositoryPort, files: any SessionFileStorePort, checkpoints: any RecordingCheckpointStorePort) {
    self.sessions = sessions
    self.files = files
    self.checkpoints = checkpoints
  }

  public func callAsFunction() async throws {
    try await sessions.deleteAll()
    await checkpoints.clear()
    await files.removeFiles(named: files.allFileNames())
  }
}
