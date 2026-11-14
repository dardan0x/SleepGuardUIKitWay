import Foundation
import SleepCore

/// Deletes a night: its record, then its audio clips.
///
/// A use case because it coordinates two ports. The record goes first: if
/// removing files then fails, what's left is unreferenced files, never a night
/// that points at missing clips.
public struct DeleteSession: Sendable {
  private let sessions: any SessionRepository
  private let files: any SessionFileStore

  public init(sessions: any SessionRepository, files: any SessionFileStore) {
    self.sessions = sessions
    self.files = files
  }

  public func callAsFunction(_ id: Night.ID) async throws {
    let clips = try await sessions.session(id: id).events.compactMap(\.clipFileName)
    try await sessions.delete(id: id)
    await files.removeFiles(named: clips)
  }
}
