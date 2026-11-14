import Foundation
import SleepDomain

/// In-memory `SessionRepository` for tests and previews. Records what was
/// saved and deleted; `failNextCall` makes the next call throw.
public actor FakeSessionRepository: SessionRepository {
  public private(set) var sessions: [SleepSession.ID: SleepSession] = [:]
  public private(set) var summaries: [SleepSession.ID: SessionSummary] = [:]
  public private(set) var savedIDs: [SleepSession.ID] = []
  public private(set) var deletedIDs: [SleepSession.ID] = []
  private var failure: (any Error)?
  private var observers: [UUID: AsyncStream<[SessionSummary]>.Continuation] = [:]

  public init(_ sessions: [SleepSession] = []) {
    for session in sessions {
      self.sessions[session.id] = session
      summaries[session.id] = session.summary()
    }
  }

  public func failNextCall(with error: any Error) {
    failure = error
  }

  public func save(_ session: SleepSession, summary: SessionSummary) async throws {
    try throwIfFailing()
    sessions[session.id] = session
    summaries[session.id] = summary
    savedIDs.append(session.id)
    publish()
  }

  public func session(id: SleepSession.ID) async throws -> SleepSession {
    try throwIfFailing()
    guard let session = sessions[id] else { throw SessionError.notFound(id) }
    return session
  }

  public func delete(id: SleepSession.ID) async throws {
    try throwIfFailing()
    guard sessions.removeValue(forKey: id) != nil else { throw SessionError.notFound(id) }
    summaries[id] = nil
    deletedIDs.append(id)
    publish()
  }

  public func observeSummaries() async -> AsyncStream<[SessionSummary]> {
    let (stream, continuation) = AsyncStream.makeStream(of: [SessionSummary].self)
    let key = UUID()
    observers[key] = continuation
    continuation.onTermination = { [weak self] _ in
      Task { await self?.removeObserver(key) }
    }
    continuation.yield(sortedSummaries)
    return stream
  }

  private var sortedSummaries: [SessionSummary] {
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
