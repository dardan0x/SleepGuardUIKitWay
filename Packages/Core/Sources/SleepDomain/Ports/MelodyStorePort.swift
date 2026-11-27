import Foundation
import SleepCore

/// The recordings someone made as their own melody, and where any melody's
/// file is (a built-in's comes from the shared `SleepMelodies`). Implemented
/// by `SleepAudioAdapter`.
@MainActor
public protocol MelodyStorePort: AnyObject, Sendable {
  /// Recordings, oldest first.
  func recordings() -> [Melody]
  func url(for melody: Melody) -> URL?
  /// Keeps the take at `take` (moved) as a new recording named `name`.
  func save(take: URL, name: String) -> Melody?
  /// Removes a recording and its file.
  func delete(_ melody: Melody)
}
