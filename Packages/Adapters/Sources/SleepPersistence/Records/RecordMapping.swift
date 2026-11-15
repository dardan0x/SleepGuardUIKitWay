import Foundation
import SleepCore
import SleepDomain

/// Records ↔ domain values. Runs inside the store actor only.
extension SessionRecord {
  func update(from session: Night, summary: NightSummary) {
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
    loudestIntensity = summary.loudestIntensity?.rawValue
  }

  /// Events come back in time order: SwiftData doesn't keep relationship order.
  var night: Night {
    Night(
      id: id, start: start, end: end, averageDB: averageDB, peakDB: peakDB,
      events: events.map(\.event).sorted { $0.start < $1.start },
      recordingGaps: recordingGaps, sleepStages: sleepStages,
      endReason: Night.EndReason(rawValue: endReason) ?? .stopped)
  }

  var summary: NightSummary {
    NightSummary(
      id: id, start: start, end: end, score: score, snoringDuration: snoringDuration, eventCount: eventCount,
      // An intensity this version doesn't know (written by a newer one) reads as quiet, like events do.
      loudestIntensity: loudestIntensity.map { SnoreIntensity(rawValue: $0) ?? .quiet })
  }
}

extension EventRecord {
  func update(from event: NightEvent) {
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
  var event: NightEvent {
    NightEvent(
      id: id, start: start, duration: duration,
      category: SoundCategory(rawValue: category) ?? .other,
      intensity: SnoreIntensity(rawValue: intensity) ?? .quiet,
      averageDB: averageDB, peakDB: peakDB, averageConfidence: averageConfidence,
      bursts: bursts, clipFileName: clipFileName)
  }
}
