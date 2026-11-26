import Foundation
import SleepCore
import SleepDomain
import SleepLogging
import SwiftData

/// `SessionRepository` over SwiftData.
///
/// A `@ModelActor`: the model context and every record live on this actor and
/// never leave it. Callers get `Sendable` domain values, so no code outside can
/// touch a record or fault a relationship.
///
/// Observation is explicit: after each write the store sends the new summary
/// list to its observers, rather than watching the context from outside.
/// That holds because this actor is the only writer: the app makes one store
/// (a container singleton) and nothing else opens the database. A second
/// writer (a widget, an extension, sync) would need persistent-history
/// observation first.
///
/// Publishing comes after the save has committed, so it never throws: a
/// failed re-read is logged and observers keep their last list until the next
/// write.
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
    publish()
  }

  func staleNightIDs(currentVersion: String) async throws -> [Night.ID] {
    var descriptor = FetchDescriptor<SessionRecord>(
      predicate: #Predicate { $0.scoreVersion != currentVersion }, sortBy: [SortDescriptor(\.start)])
    descriptor.propertiesToFetch = [\.id, \.start, \.scoreVersion]
    return try modelContext.fetch(descriptor).map(\.id)
  }

  func updateStages(
    of id: Night.ID, stages: [SleepStageSegment], summary: NightSummary, scoreVersion: String) async throws
  {
    guard let record = try record(id: id) else { throw SessionError.notFound(id) }
    record.sleepStages = stages
    record.update(from: summary)
    record.scoreVersion = scoreVersion
    try modelContext.save()
    publish()
  }

  func updateSummaries(_ summaries: [NightSummary], scoreVersion: String) async throws {
    for summary in summaries {
      guard let record = try record(id: summary.id) else { continue }
      record.update(from: summary)
      record.scoreVersion = scoreVersion
    }
    try modelContext.save()
    publish()
  }

  func session(id: Night.ID) async throws -> Night {
    guard let record = try record(id: id) else { throw SessionError.notFound(id) }
    return record.night
  }

  func delete(id: Night.ID) async throws {
    guard let record = try record(id: id) else { throw SessionError.notFound(id) }
    modelContext.delete(record) // events cascade
    try modelContext.save()
    publish()
  }

  func delete(ids: [Night.ID]) async throws {
    var records: [SessionRecord] = []
    for id in ids {
      guard let record = try record(id: id) else { throw SessionError.notFound(id) }
      records.append(record)
    }
    records.forEach(modelContext.delete) // events cascade
    do {
      try modelContext.save()
    } catch {
      modelContext.rollback() // nothing half-deleted stays pending for the next save
      throw error
    }
    publish()
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
    publish()
  }

  func deleteAll() async throws {
    for record in try modelContext.fetch(FetchDescriptor<SessionRecord>()) {
      modelContext.delete(record) // events cascade
    }
    try modelContext.save()
    publish()
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

  private func publish() {
    guard !observers.isEmpty else { return }
    let current: [NightSummary]
    do {
      current = try summaries()
    } catch {
      Log.storage.error("Couldn't re-read the nights after a save: \(error.localizedDescription, privacy: .public)")
      return
    }
    for continuation in observers.values {
      continuation.yield(current)
    }
  }

  private func removeObserver(_ key: UUID) {
    observers[key] = nil
  }
}
