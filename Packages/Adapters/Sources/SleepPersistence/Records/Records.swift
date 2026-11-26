import Foundation
import SleepCore
import SleepDomain
import SwiftData

/// A stored night. Internal: only `SwiftDataSessionStore` touches records;
/// everything else sees `Night` / `NightSummary` values.
///
/// Schema rules (same as SleepGuard): add properties with defaults, never rename
/// or remove one. Enums are stored as raw strings so a value written by a newer
/// version can't fail to decode in an older one.
@Model
final class SessionRecord {
  // Not `@Attribute(.unique)`: unique constraints rule out CloudKit sync. Saves
  // look the record up by id (one actor serializes them).
  var id = UUID()
  var start = Date.distantPast
  var end = Date.distantPast
  var averageDB = 0.0
  var peakDB = 0.0
  var endReason = Night.EndReason.stopped.rawValue
  var recordingGaps: [RecordingGap] = []
  var sleepStages: [SleepStageSegment] = []

  // The summary, stored so lists never load events.
  var score = 0
  var snoringDuration: TimeInterval = 0
  var eventCount = 0
  /// `SnoreIntensity` raw value; `nil` for a night without events.
  var loudestIntensity: String?
  /// `SleepScore.cacheVersion(for:)` of the formula and config that made the
  /// summary. "" (every night stored before versions were) reads as stale.
  var scoreVersion = ""

  @Relationship(deleteRule: .cascade, inverse: \EventRecord.session)
  var events: [EventRecord] = []

  init(id: UUID) {
    self.id = id
  }
}

@Model
final class EventRecord {
  var id = UUID()
  var start = Date.distantPast
  var duration: TimeInterval = 0
  var category = SoundCategory.snoring.rawValue
  var intensity = SnoreIntensity.quiet.rawValue
  var averageDB = 0.0
  var peakDB = 0.0
  var averageConfidence = 0.0
  var bursts: [SnoreBurst] = []
  var clipFileName: String?
  var session: SessionRecord?

  init(id: UUID) {
    self.id = id
  }
}
