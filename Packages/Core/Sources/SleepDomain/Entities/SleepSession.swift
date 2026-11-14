import Foundation
import SleepCore

/// A finished night: what was recorded between `start` and `end`.
///
/// A plain value, not a database record: persistence maps to and from it
/// (`SleepPersistence`), and nothing outside that adapter sees a record. The
/// in-progress night is a different type (`RecordingDraft`, F7).
public struct SleepSession: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var start: Date
  public var end: Date
  /// dBFS (relative to digital full scale), not calibrated dB-SPL.
  public var averageDB: Double
  public var peakDB: Double
  /// Every detected event, any category, in no particular order.
  public var events: [SnoreEvent]
  /// When the microphone was paused (Snore Interrupter playing).
  public var recordingGaps: [RecordingGap]
  /// From Apple Health, when available. Empty otherwise.
  public var sleepStages: [SleepStageSegment]
  public var endReason: EndReason

  public init(
    id: UUID = UUID(),
    start: Date,
    end: Date,
    averageDB: Double = 0,
    peakDB: Double = 0,
    events: [SnoreEvent] = [],
    recordingGaps: [RecordingGap] = [],
    sleepStages: [SleepStageSegment] = [],
    endReason: EndReason = .stopped)
  {
    precondition(end >= start, "A session can't end before it starts")
    self.id = id
    self.start = start
    self.end = end
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.events = events
    self.recordingGaps = recordingGaps
    self.sleepStages = sleepStages
    self.endReason = endReason
  }

  /// End − start, recording gaps included.
  public var duration: TimeInterval {
    end.timeIntervalSince(start)
  }

  /// Why recording stopped.
  public enum EndReason: String, Sendable, Equatable, CaseIterable {
    /// The user stopped it.
    case stopped
    /// Saved automatically before the battery ran out.
    case lowBattery
  }
}
