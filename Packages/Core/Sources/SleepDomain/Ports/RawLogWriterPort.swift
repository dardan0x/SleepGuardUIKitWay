import Foundation
import SleepCore

/// A night's raw recording, kept when "Preserve raw audio" is on (Debug
/// builds): the full audio, written by the capture, and every sample with the
/// detection settings, written here in SleepCore's `RawLog` format (JSON
/// Lines), so one replay tool reads SleepGuard's logs and these. Both files
/// sit beside the clips and go with them: storage limits and delete all.
public protocol RawLogWriterPort: Sendable {
  /// Starts the log of night `id` with its settings.
  func begin(night id: UUID, metadata: RawLogMetadata) async
  /// Samples in batches, in the order they were heard.
  func append(_ samples: [SnoreSample]) async
  /// Flushes and closes the log.
  func finish() async
}
