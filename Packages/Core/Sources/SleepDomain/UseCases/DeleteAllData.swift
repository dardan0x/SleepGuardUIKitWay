import Foundation

/// "Delete all recordings": every night, every file in the clips folder (clips
/// and raw recordings), and a night left in the checkpoint. The profile and
/// the settings stay, as in SleepGuard.
///
/// A use case because it coordinates three ports. The records go first, as in
/// `DeleteSession`: if removing files then fails, no night points at a
/// missing clip.
public struct DeleteAllData: Sendable {
  private let sessions: any SessionRepository
  private let files: any SessionFileStore
  private let checkpoints: any RecordingCheckpointStore

  public init(sessions: any SessionRepository, files: any SessionFileStore, checkpoints: any RecordingCheckpointStore) {
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
