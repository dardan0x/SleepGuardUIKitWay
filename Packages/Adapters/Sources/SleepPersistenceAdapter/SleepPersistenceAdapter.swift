import Foundation
import SleepDomain
import SleepStore

/// The module's public surface: factories returning ports. The store types
/// stay internal; the records are the shared SleepStore's.
public enum SleepPersistenceAdapter {
  /// The nights database. `url == nil` keeps it in memory (tests, previews).
  public static func makeSessionRepository(storeURL url: URL?) throws -> any SessionRepositoryPort {
    try SwiftDataSessionStoreAdapter(modelContainer: SleepStoreSchema.container(at: url))
  }

  /// Clip files in `directory`.
  public static func makeSessionFileStore(directory: URL) -> any SessionFileStorePort {
    FileSessionStoreAdapter(directory: directory)
  }

  /// Settings, in the `UserDefaults` suite (`nil`: the app's standard defaults).
  public static func makePreferencesStore(suiteName: String? = nil) -> any PreferencesStorePort {
    UserDefaultsPreferencesStoreAdapter(suiteName: suiteName)
  }

  /// The profile, as the file at `url`.
  public static func makeProfileStore(url: URL) -> any ProfileStorePort {
    FileProfileStoreAdapter(url: url)
  }

  /// The briefing survey's answers, one JSON file at `url`.
  public static func makeLifestyleLogStore(url: URL) -> any LifestyleLogStorePort {
    FileLifestyleLogStoreAdapter(url: url)
  }

  /// Raw recordings' sample logs, beside the clips in `directory`.
  public static func makeRawLogWriter(directory: URL) -> any RawLogWriterPort {
    RawLogFileWriterAdapter(directory: directory)
  }

  /// The night in progress, as the file at `url`.
  public static func makeCheckpointStore(url: URL) -> any RecordingCheckpointStorePort {
    FileCheckpointStoreAdapter(url: url)
  }
}
