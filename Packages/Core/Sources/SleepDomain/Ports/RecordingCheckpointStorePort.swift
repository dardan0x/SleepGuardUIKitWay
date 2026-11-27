import Foundation
import SleepCore

/// The night in progress, kept on disk while recording so a crash, a kill in
/// the background or a dead battery doesn't lose it. Implemented by
/// `SleepPersistenceAdapter` as one file. Holds at most one night; cleared once that
/// night is saved or discarded.
public protocol RecordingCheckpointStorePort: Sendable {
  /// Replaces the checkpoint with `night` (its end is the checkpoint time).
  /// A failed write is logged; the previous checkpoint stays.
  func save(_ night: Night) async
  /// The checkpointed night, or `nil` when there is none or it can't be read.
  func load() async -> Night?
  func clear() async
}
