import Foundation
import SleepCore

/// A night's raw recording, kept when "Preserve raw audio" is on (Debug
/// builds): the full audio, written by the capture, and every sample with the
/// detection settings, written here in SleepCore's `RawLog` format (JSON
/// Lines), so one replay tool reads SleepGuard's logs and these. Both files
/// sit beside the clips and go with them: storage limits and delete all.
public protocol RawLogWriter: Sendable {
  /// Starts the log of night `id` with its settings.
  func begin(night id: UUID, metadata: RawLogMetadata) async
  /// Samples in batches, in the order they were heard.
  func append(_ samples: [SnoreSample]) async
  /// Flushes and closes the log.
  func finish() async
}

/// The raw files' names, so storage limits can find a night's files.
public enum RawRecording {
  public static func audioFileName(for night: UUID) -> String {
    "rawaudio_\(night.uuidString).caf"
  }

  public static func logFileName(for night: UUID) -> String {
    "rawlog_\(night.uuidString).jsonl"
  }

  public static func fileNames(for night: UUID) -> [String] {
    [audioFileName(for: night), logFileName(for: night)]
  }
}
