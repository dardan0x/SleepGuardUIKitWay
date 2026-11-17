import Foundation
import SleepCore

/// The night being recorded: a value the recording actor owns and updates,
/// never a database record. `night(end:endReason:)` turns it into the
/// `Night` that gets saved (F7-T6) or checkpointed (F7-T7).
public struct RecordingDraft: Sendable, Equatable {
  public let id: UUID
  public let start: Date
  /// Detected events in the order they finished.
  public internal(set) var events: [NightEvent] = []
  /// When the microphone was paused for the Snore Interrupter's melody.
  public internal(set) var recordingGaps: [RecordingGap] = []
  /// Loudest RMS level heard, dBFS. The floor until the first sample.
  public internal(set) var peakDB = Double(AudioLevels.floorDB)
  private(set) var levelSum: Double = 0
  public private(set) var sampleCount = 0

  public init(id: UUID = UUID(), start: Date) {
    self.id = id
    self.start = start
  }

  /// Mean RMS level of every sample, dBFS; 0 before the first.
  public var averageDB: Double {
    sampleCount > 0 ? levelSum / Double(sampleCount) : 0
  }

  mutating func add(level db: Float) {
    levelSum += Double(db)
    sampleCount += 1
    peakDB = max(peakDB, Double(db))
  }

  /// The finished night. `end` is clamped to `start`.
  public func night(end: Date, endReason: Night.EndReason = .stopped) -> Night {
    Night(
      id: id, start: start, end: max(end, start),
      averageDB: averageDB, peakDB: sampleCount > 0 ? peakDB : 0,
      events: events, recordingGaps: recordingGaps, endReason: endReason)
  }
}

/// What the recording screen shows, a few times a second.
public struct LiveSnapshot: Sendable, Equatable {
  /// When the latest sample was taken.
  public let time: Date
  /// RMS level of that sample, dBFS.
  public let db: Float
  public let snoreState: DetectionState
  public let isSpeech: Bool
  /// Events saved so far.
  public let eventCount: Int
  /// The Snore Interrupter's melody is playing (the microphone is paused).
  public let melodyPlaying: Bool

  public init(time: Date, db: Float, snoreState: DetectionState, isSpeech: Bool, eventCount: Int, melodyPlaying: Bool = false) {
    self.time = time
    self.db = db
    self.snoreState = snoreState
    self.isSpeech = isSpeech
    self.eventCount = eventCount
    self.melodyPlaying = melodyPlaying
  }
}
