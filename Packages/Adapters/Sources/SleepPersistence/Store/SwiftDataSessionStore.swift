import Foundation
import SleepCore
import SleepDomain
import SwiftData

/// `SessionRepository` over SwiftData.
///
/// A `@ModelActor`: the model context and every record live on this actor and
/// never leave it. Callers get `Sendable` domain values, so no code outside can
/// touch a record or fault a relationship.
///
/// Observation is explicit: after each write the store sends the new summary
/// list to its observers, rather than watching the context from outside.
@ModelActor
actor SwiftDataSessionStore: SessionRepository {
  private var observers: [UUID: AsyncStream<[NightSummary]>.Continuation] = [:]

  func save(_ session: Night, summary: NightSummary, scoreVersion: String) async throws {
    let record = try record(id: session.id) ?? {
      let record = SessionRecord(id: session.id)
      modelContext.insert(record)
      return record
    }()
    record.update(from: session, summary: summary)
    record.scoreVersion = scoreVersion
    replaceEvents(of: record, with: session.events)
    try modelContext.save()
    try publish()
  }

  func staleNightIDs(currentVersion: String) async throws -> [Night.ID] {
    var descriptor = FetchDescriptor<SessionRecord>(
      predicate: #Predicate { $0.scoreVersion != currentVersion }, sortBy: [SortDescriptor(\.start)])
    descriptor.propertiesToFetch = [\.id, \.start, \.scoreVersion]
    return try modelContext.fetch(descriptor).map(\.id)
  }

  func updateSummaries(_ summaries: [NightSummary], scoreVersion: String) async throws {
    for summary in summaries {
      guard let record = try record(id: summary.id) else { continue }
      record.update(from: summary)
      record.scoreVersion = scoreVersion
    }
    try modelContext.save()
    try publish()
  }

  func session(id: Night.ID) async throws -> Night {
    guard let record = try record(id: id) else { throw SessionError.notFound(id) }
    return record.night
  }

  func delete(id: Night.ID) async throws {
    guard let record = try record(id: id) else { throw SessionError.notFound(id) }
    modelContext.delete(record) // events cascade
    try modelContext.save()
    try publish()
  }

  func observeSummaries() async -> AsyncStream<[NightSummary]> {
    let (stream, continuation) = AsyncStream.makeStream(of: [NightSummary].self)
    let key = UUID()
    observers[key] = continuation
    continuation.onTermination = { [weak self] _ in
      Task { await self?.removeObserver(key) }
    }
    continuation.yield((try? summaries()) ?? [])
    return stream
  }

  func nightFiles() async throws -> [NightFiles] {
    try modelContext.fetch(FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.start)])).map { record in
      NightFiles(id: record.id, start: record.start, clipFileNames: record.events.compactMap(\.clipFileName))
    }
  }

  func removeClips(of id: Night.ID) async throws {
    guard let record = try record(id: id) else { throw SessionError.notFound(id) }
    for event in record.events {
      event.clipFileName = nil
    }
    try modelContext.save()
  }

  func deleteAll() async throws {
    for record in try modelContext.fetch(FetchDescriptor<SessionRecord>()) {
      modelContext.delete(record) // events cascade
    }
    try modelContext.save()
    try publish()
  }

  // MARK: - Private

  private func record(id: UUID) throws -> SessionRecord? {
    var descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.id == id })
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  /// Events are replaced wholesale: a saved night's events are a value.
  private func replaceEvents(of record: SessionRecord, with events: [NightEvent]) {
    for old in record.events {
      modelContext.delete(old)
    }
    record.events = events.map { event in
      let new = EventRecord(id: event.id)
      new.update(from: event)
      modelContext.insert(new)
      return new
    }
  }

  private func summaries() throws -> [NightSummary] {
    try modelContext.fetch(FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.start, order: .reverse)])).map(\.summary)
  }

  private func publish() throws {
    guard !observers.isEmpty else { return }
    let current = try summaries()
    for continuation in observers.values {
      continuation.yield(current)
    }
  }

  private func removeObserver(_ key: UUID) {
    observers[key] = nil
  }
}
