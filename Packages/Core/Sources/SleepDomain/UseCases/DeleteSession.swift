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

/// Deletes several nights at once (a day in History): every record in one
/// write, then their clips. All or none: if the write fails, every night is
/// still there with its clips.
public struct DeleteSessions: Sendable {
  private let sessions: any SessionRepository
  private let files: any SessionFileStore

  public init(sessions: any SessionRepository, files: any SessionFileStore) {
    self.sessions = sessions
    self.files = files
  }

  public func callAsFunction(_ ids: [Night.ID]) async throws {
    var clips: [String] = []
    for id in ids {
      try await clips += sessions.session(id: id).events.compactMap(\.clipFileName)
    }
    try await sessions.delete(ids: ids)
    await files.removeFiles(named: clips)
  }
}
