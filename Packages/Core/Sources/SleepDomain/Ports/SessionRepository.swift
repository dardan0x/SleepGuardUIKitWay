import Foundation

/// Where finished nights are stored. Implemented by `SleepPersistence` (SwiftData).
///
/// Every method takes and returns domain values; no storage type crosses it.
public protocol SessionRepository: Sendable {
  /// Inserts or replaces the night and its summary. The summary is stored with
  /// it so lists never load events.
  func save(_ session: SleepSession, summary: SessionSummary) async throws

  /// The whole night, events included. Throws `SessionError.notFound`.
  func session(id: SleepSession.ID) async throws -> SleepSession

  /// Removes the night and its events. Throws `SessionError.notFound`.
  func delete(id: SleepSession.ID) async throws

  /// Every summary, newest first: the current list, then the new list after
  /// each change. Ends when the caller stops iterating.
  func observeSummaries() async -> AsyncStream<[SessionSummary]>
}

public enum SessionError: Error, Equatable {
  case notFound(SleepSession.ID)
}
