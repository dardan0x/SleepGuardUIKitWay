import Foundation

/// The audio files that belong to nights (event clips). Implemented by
/// `SleepPersistenceAdapter` over the app group container.
public protocol SessionFileStorePort: Sendable {
  /// Removes the named files. Missing files are not an error: the goal is
  /// that they are gone.
  func removeFiles(named names: [String]) async
  /// The file to play, or `nil` when it doesn't exist (or the name isn't a
  /// plain file name).
  func url(forFileNamed name: String) -> URL?
  /// The file's size in bytes, 0 when it doesn't exist.
  func size(ofFileNamed name: String) async -> Int64
  /// Every file in the folder: what storage limits and delete all look through.
  func allFileNames() async -> [String]
}
