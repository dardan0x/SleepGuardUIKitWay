import Foundation
import SleepCore
import SleepDomain

/// In-memory `SessionRepository` for tests and previews. Records what was
/// saved and deleted; `failNextCall` makes the next call throw.
public actor FakeSessionRepository: SessionRepository {
  public private(set) var sessions: [Night.ID: Night] = [:]
  public private(set) var summaries: [Night.ID: NightSummary] = [:]
  public private(set) var savedIDs: [Night.ID] = []
  public private(set) var deletedIDs: [Night.ID] = []
  private var failure: (any Error)?
  private var observers: [UUID: AsyncStream<[NightSummary]>.Continuation] = [:]

  public init(_ sessions: [Night] = []) {
    for session in sessions {
      self.sessions[session.id] = session
      summaries[session.id] = session.summary()
    }
  }

  public func failNextCall(with error: any Error) {
    failure = error
  }

  public func save(_ session: Night, summary: NightSummary) async throws {
    try throwIfFailing()
    sessions[session.id] = session
    summaries[session.id] = summary
    savedIDs.append(session.id)
    publish()
  }

  public func session(id: Night.ID) async throws -> Night {
    try throwIfFailing()
    guard let session = sessions[id] else { throw SessionError.notFound(id) }
    return session
  }

  public func delete(id: Night.ID) async throws {
    try throwIfFailing()
    guard sessions.removeValue(forKey: id) != nil else { throw SessionError.notFound(id) }
    summaries[id] = nil
    deletedIDs.append(id)
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
