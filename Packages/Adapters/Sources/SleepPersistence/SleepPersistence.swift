import Foundation
import SleepDomain

/// The module's public surface: factories returning ports. Records, mappers
/// and the store types stay internal.
public enum SleepPersistence {
  /// The nights database. `url == nil` keeps it in memory (tests, previews).
  public static func makeSessionRepository(storeURL url: URL?) throws -> any SessionRepository {
    try SwiftDataSessionStore(modelContainer: PersistenceSchema.container(at: url))
  }

  /// Clip files in `directory`.
  public static func makeSessionFileStore(directory: URL) -> any SessionFileStore {
    FileSessionStore(directory: directory)
  }
}
