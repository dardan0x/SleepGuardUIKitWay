import Foundation
import SleepCore
@testable import SleepDomain

/// Same defaults as SleepGuard's test fixtures, so ported cases keep their numbers.
enum Night {
  static let start = Date(timeIntervalSinceReferenceDate: 23 * 3600)

  static func at(_ seconds: TimeInterval) -> Date {
    start.addingTimeInterval(seconds)
  }

  static func session(
    hours: Double = 8,
    events: [SnoreEvent] = [],
    gaps: [RecordingGap] = [],
    stages: [SleepStageSegment] = []) -> SleepSession
  {
    SleepSession(
      start: start, end: start.addingTimeInterval(hours * 3600),
      events: events, recordingGaps: gaps, sleepStages: stages)
  }

  static func event(
    at seconds: TimeInterval,
    duration: TimeInterval = 60,
    intensity: SnoreIntensity = .light,
    category: SoundCategory = .snoring,
    averageDB: Double = -35,
    peakDB: Double = -25,
    bursts: [SnoreBurst] = []) -> SnoreEvent
  {
    SnoreEvent(
      start: at(seconds), duration: duration, category: category, intensity: intensity,
      averageDB: averageDB, peakDB: peakDB, bursts: bursts)
  }
}
