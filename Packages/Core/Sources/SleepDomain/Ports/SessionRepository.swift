import Foundation
import SleepCore

/// Where finished nights are stored. Implemented by `SleepPersistence` (SwiftData).
///
/// Every method takes and returns domain values; no storage type crosses it.
public protocol SessionRepository: Sendable {
  /// Inserts or replaces the night and its summary. The summary is stored with
  /// it so lists never load events; `scoreVersion` (SleepCore's
  /// `SleepScore.cacheVersion(for:)`) says which formula and config made it.
  func save(_ session: Night, summary: NightSummary, scoreVersion: String) async throws

  /// The nights whose stored summary was made by another score version, or
  /// before versions were stored. Reads no events.
  func staleNightIDs(currentVersion: String) async throws -> [Night.ID]

  /// Replaces stored summaries only (events and stages untouched), in one
  /// write. A night that no longer exists is skipped.
  func updateSummaries(_ summaries: [NightSummary], scoreVersion: String) async throws

  /// The whole night, events included and in time order. Throws
  /// `SessionError.notFound`.
  func session(id: Night.ID) async throws -> Night

  /// Removes the night and its events. Throws `SessionError.notFound`.
  func delete(id: Night.ID) async throws

  /// Every summary, newest first: the current list, then the new list after
  /// each change. Ends when the caller stops iterating.
  func observeSummaries() async -> AsyncStream<[NightSummary]>

  /// Every night's start and clip files, oldest first: what the storage
  /// limits measure. Reads no other event data.
  func nightFiles() async throws -> [NightFiles]

  /// Forgets the night's clips: its events keep everything else. Throws
  /// `SessionError.notFound`.
  func removeClips(of id: Night.ID) async throws

  /// Removes every night and its events.
  func deleteAll() async throws
}

/// A night's files, for the storage limits.
public struct NightFiles: Equatable, Sendable {
  public let id: Night.ID
  public let start: Date
  public let clipFileNames: [String]

  public init(id: Night.ID, start: Date, clipFileNames: [String]) {
    self.id = id
    self.start = start
    self.clipFileNames = clipFileNames
  }

  /// Its clips and raw recording (which may not exist).
  public var allFileNames: [String] {
    clipFileNames + RawRecording.fileNames(for: id)
  }
}

public enum SessionError: Error, Equatable {
  case notFound(Night.ID)
}
