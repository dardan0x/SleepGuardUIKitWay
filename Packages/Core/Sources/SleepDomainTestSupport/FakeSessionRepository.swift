import Foundation
import SleepCore
import SleepDomain

/// In-memory `SessionRepositoryPort` for tests and previews. Records what was
/// saved and deleted; `failNextCall` makes the next call throw.
public actor FakeSessionRepository: SessionRepositoryPort {
  public private(set) var sessions: [Night.ID: Night] = [:]
  public private(set) var summaries: [Night.ID: NightSummary] = [:]
  /// The score version each summary was stored with; "" for nights given to `init`.
  public private(set) var scoreVersions: [Night.ID: String] = [:]
  /// One entry per `updateSummaries` call.
  public private(set) var summaryUpdates: [[Night.ID]] = []
  public private(set) var savedIDs: [Night.ID] = []
  public private(set) var deletedIDs: [Night.ID] = []
  /// Nights given stages through `updateStages`, in order.
  public private(set) var stageUpdates: [Night.ID] = []
  private var failure: (any Error)?
  private var stageUpdateFailure: (any Error)?
  private var deleteFailure: (any Error)?
  private var observers: [UUID: AsyncStream<[NightSummary]>.Continuation] = [:]

  public init(_ sessions: [Night] = []) {
    for session in sessions {
      self.sessions[session.id] = session
      summaries[session.id] = session.summary()
      scoreVersions[session.id] = ""
    }
  }

  public func failNextCall(with error: any Error) {
    failure = error
  }

  /// Every `delete(ids:)` throws this, while other calls succeed.
  public func failDeletes(with error: any Error) {
    deleteFailure = error
  }

  /// Every `updateStages` throws this, while other calls succeed.
  public func failStageUpdates(with error: any Error) {
    stageUpdateFailure = error
  }

  public func save(_ session: Night, summary: NightSummary, scoreVersion: String) async throws {
    try throwIfFailing()
    sessions[session.id] = session
    summaries[session.id] = summary
    scoreVersions[session.id] = scoreVersion
    savedIDs.append(session.id)
    publish()
  }

  public func staleNightIDs(currentVersion: String) async throws -> [Night.ID] {
    try throwIfFailing()
    return sessions.values.sorted { $0.start < $1.start }.map(\.id).filter { scoreVersions[$0] != currentVersion }
  }

  public func updateStages(
    of id: Night.ID, stages: [SleepStageSegment], summary: NightSummary, scoreVersion: String) async throws
  {
    try throwIfFailing()
    if let stageUpdateFailure { throw stageUpdateFailure }
    guard sessions[id] != nil else { throw SessionError.notFound(id) }
    sessions[id]?.sleepStages = stages
    summaries[id] = summary
    scoreVersions[id] = scoreVersion
    stageUpdates.append(id)
    publish()
  }

  public func updateSummaries(_ updates: [NightSummary], scoreVersion: String) async throws {
    try throwIfFailing()
    let present = updates.filter { sessions[$0.id] != nil }
    for summary in present {
      summaries[summary.id] = summary
      scoreVersions[summary.id] = scoreVersion
    }
    summaryUpdates.append(present.map(\.id))
    publish()
  }

  public func session(id: Night.ID) async throws -> Night {
    try throwIfFailing()
    guard var session = sessions[id] else { throw SessionError.notFound(id) }
    // In time order, as the port promises and the SwiftData store does.
    session.events.sort { $0.start < $1.start }
    return session
  }

  public func delete(id: Night.ID) async throws {
    try throwIfFailing()
    guard sessions.removeValue(forKey: id) != nil else { throw SessionError.notFound(id) }
    summaries[id] = nil
    scoreVersions[id] = nil
    deletedIDs.append(id)
    publish()
  }

  public func delete(ids: [Night.ID]) async throws {
    try throwIfFailing()
    if let deleteFailure { throw deleteFailure }
    if let missing = ids.first(where: { sessions[$0] == nil }) { throw SessionError.notFound(missing) }
    for id in ids {
      sessions[id] = nil
      summaries[id] = nil
      scoreVersions[id] = nil
      deletedIDs.append(id)
    }
    publish()
  }

  public func observeSummaries() async -> AsyncStream<[NightSummary]> {
    let (stream, continuation) = AsyncStream.makeStream(of: [NightSummary].self)
    let key = UUID()
    observers[key] = continuation
    continuation.onTermination = { [weak self] _ in
      Task { await self?.removeObserver(key) }
    }
    continuation.yield(sortedSummaries)
    return stream
  }

  public func nightFiles() async throws -> [NightFiles] {
    try throwIfFailing()
    return sessions.values.sorted { $0.start < $1.start }.map {
      NightFiles(id: $0.id, start: $0.start, clipFileNames: $0.events.compactMap(\.clipFileName))
    }
  }

  public func removeClips(of id: Night.ID) async throws {
    try throwIfFailing()
    guard var session = sessions[id] else { throw SessionError.notFound(id) }
    for index in session.events.indices {
      session.events[index].clipFileName = nil
    }
    sessions[id] = session
  }

  public func deleteAll() async throws {
    try throwIfFailing()
    deletedIDs += sessions.keys
    sessions = [:]
    summaries = [:]
    scoreVersions = [:]
    publish()
  }

  private var sortedSummaries: [NightSummary] {
    summaries.values.sorted { $0.start > $1.start }
  }

  private func publish() {
    for continuation in observers.values {
      continuation.yield(sortedSummaries)
    }
  }

  private func removeObserver(_ key: UUID) {
    observers[key] = nil
  }

  private func throwIfFailing() throws {
    if let failure {
      self.failure = nil
      throw failure
    }
  }
}
