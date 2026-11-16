import Foundation
import os
import SleepCore
import SleepDomain

/// `RecordingCheckpointStore` as one JSON file, as SleepGuard's
/// `SessionCheckpointStore`. Writes are atomic (a temporary file, then a
/// rename), so a crash mid-write leaves the previous checkpoint intact.
/// An actor: checkpoints arrive from the recording actor and the flow.
actor FileCheckpointStore: RecordingCheckpointStore {
  private let url: URL
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "storage")

  init(url: URL) {
    self.url = url
  }

  func save(_ night: Night) async {
    do {
      try JSONEncoder().encode(CheckpointFile(night)).write(to: url, options: .atomic)
    } catch {
      Self.log.error("Checkpoint write failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  func load() async -> Night? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    do {
      return try JSONDecoder().decode(CheckpointFile.self, from: Data(contentsOf: url)).night
    } catch {
      Self.log.error("Checkpoint unreadable, night not recoverable: \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }

  func clear() async {
    try? FileManager.default.removeItem(at: url)
  }
}

/// The file's shape: `Night` and `NightEvent` as plain Codable mirrors, so
/// the domain types stay free of storage concerns.
struct CheckpointFile: Codable, Equatable {
  struct Event: Codable, Equatable {
    let id: UUID
    let start: Date
    let duration: TimeInterval
    let category: SoundCategory
    let intensity: SnoreIntensity
    let averageDB: Double
    let peakDB: Double
    let averageConfidence: Double
    let bursts: [SnoreBurst]
    let clipFileName: String?
  }

  let id: UUID
  let start: Date
  let end: Date
  let averageDB: Double
  let peakDB: Double
  let events: [Event]
  let recordingGaps: [RecordingGap]
  let endReason: String

  init(_ night: Night) {
    id = night.id
    start = night.start
    end = night.end
    averageDB = night.averageDB
    peakDB = night.peakDB
    events = night.events.map {
      Event(
        id: $0.id, start: $0.start, duration: $0.duration, category: $0.category, intensity: $0.intensity,
        averageDB: $0.averageDB, peakDB: $0.peakDB, averageConfidence: $0.averageConfidence, bursts: $0.bursts,
        clipFileName: $0.clipFileName)
    }
    recordingGaps = night.recordingGaps
    endReason = night.endReason.rawValue
  }

  var night: Night {
    Night(
      id: id, start: start, end: max(end, start), averageDB: averageDB, peakDB: peakDB,
      events: events.map {
        NightEvent(
          id: $0.id, start: $0.start, duration: max(0, $0.duration), category: $0.category, intensity: $0.intensity,
          averageDB: $0.averageDB, peakDB: $0.peakDB, averageConfidence: $0.averageConfidence, bursts: $0.bursts,
          clipFileName: $0.clipFileName)
      },
      recordingGaps: recordingGaps,
      endReason: Night.EndReason(rawValue: endReason) ?? .stopped)
  }
}
