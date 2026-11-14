import Foundation
import SleepCore
import SleepDomain

/// Records ↔ domain values. Runs inside the store actor only.
extension SessionRecord {
  func update(from session: SleepSession, summary: SessionSummary) {
    start = session.start
    end = session.end
    averageDB = session.averageDB
    peakDB = session.peakDB
    endReason = session.endReason.rawValue
    recordingGaps = session.recordingGaps
    sleepStages = session.sleepStages
    score = summary.score
    snoringDuration = summary.snoringDuration
    eventCount = summary.eventCount
  }

  /// Events come back in time order: SwiftData doesn't keep relationship order.
  var session: SleepSession {
    SleepSession(
      id: id, start: start, end: end, averageDB: averageDB, peakDB: peakDB,
      events: events.map(\.event).sorted { $0.start < $1.start },
      recordingGaps: recordingGaps, sleepStages: sleepStages,
      endReason: SleepSession.EndReason(rawValue: endReason) ?? .stopped)
  }

  var summary: SessionSummary {
    SessionSummary(id: id, start: start, end: end, score: score, snoringDuration: snoringDuration, eventCount: eventCount)
  }
}

extension EventRecord {
  func update(from event: SnoreEvent) {
    start = event.start
    duration = event.duration
    category = event.category.rawValue
    intensity = event.intensity.rawValue
    averageDB = event.averageDB
    peakDB = event.peakDB
    averageConfidence = event.averageConfidence
    bursts = event.bursts
    clipFileName = event.clipFileName
  }

  /// Unknown raw values (written by a newer version) read as the safest default.
  var event: SnoreEvent {
    SnoreEvent(
      id: id, start: start, duration: duration,
      category: SoundCategory(rawValue: category) ?? .other,
      intensity: SnoreIntensity(rawValue: intensity) ?? .quiet,
      averageDB: averageDB, peakDB: peakDB, averageConfidence: averageConfidence,
      bursts: bursts, clipFileName: clipFileName)
  }
}
