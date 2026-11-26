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

  /// Settings, in the `UserDefaults` suite (`nil`: the app's standard defaults).
  public static func makePreferencesStore(suiteName: String? = nil) -> any PreferencesStore {
    UserDefaultsPreferencesStore(suiteName: suiteName)
  }

  /// The profile, as the file at `url`.
  public static func makeProfileStore(url: URL) -> any ProfileStore {
    FileProfileStore(url: url)
  }

  /// The briefing survey's answers, one JSON file at `url`.
  public static func makeLifestyleLogStore(url: URL) -> any LifestyleLogStore {
    FileLifestyleLogStore(url: url)
  }

  /// Raw recordings' sample logs, beside the clips in `directory`.
  public static func makeRawLogWriter(directory: URL) -> any RawLogWriter {
    RawLogFileWriter(directory: directory)
  }

  /// The night in progress, as the file at `url`.
  public static func makeCheckpointStore(url: URL) -> any RecordingCheckpointStore {
    FileCheckpointStore(url: url)
  }
}
