import Foundation

/// The audio files that belong to nights (event clips). Implemented by
/// `SleepPersistence` over the app group container.
public protocol SessionFileStore: Sendable {
  /// Removes the named files. Missing files are not an error: the goal is
  /// that they are gone.
  func removeFiles(named names: [String]) async
}
