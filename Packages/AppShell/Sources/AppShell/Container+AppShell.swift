import FactoryKit
import SleepAudio
import SleepDomain
import SleepGuardDesignKit
import SleepPersistence

/// The shell's registrations. Everything derives from `brand`, the one value
/// supplied from outside (`AppShell.bootstrap(brand:)`). Only `AppShell`
/// imports Factory; packages below it take plain initializer arguments.
extension Container {
  var brand: Factory<any BrandComposition> {
    self { preconditionFailure("AppShell.bootstrap(brand:) registers the brand before anything resolves") }
      .singleton
  }

  var theme: Factory<Theme> {
    self { self.brand().configuration.theme }
  }

  var storageLocation: Factory<StorageLocation> {
    self { StorageLocation.resolve() }.singleton
  }

  /// The nights database. If it can't be opened, this launch runs on an
  /// in-memory store and logs a fault: the file is left alone, never deleted,
  /// so nothing is lost and the next launch tries again.
  var sessionRepository: Factory<any SessionRepository> {
    self {
      let url = self.storageLocation().storeURL
      do {
        return try SleepPersistence.makeSessionRepository(storeURL: url)
      } catch {
        Log.storage.fault("Couldn't open the nights store: \(error.localizedDescription, privacy: .public)")
        // In memory can only fail if SwiftData itself can't start.
        return try! SleepPersistence.makeSessionRepository(storeURL: nil)
      }
    }
    .singleton
  }

  var sessionFileStore: Factory<any SessionFileStore> {
    self { SleepPersistence.makeSessionFileStore(directory: self.storageLocation().clipsDirectory) }.singleton
  }

  var sleepStagePort: Factory<any SleepStagePort> {
    self { NoSleepStages() }.singleton
  }

  var deleteSession: Factory<DeleteSession> {
    self { DeleteSession(sessions: self.sessionRepository(), files: self.sessionFileStore()) }
  }

  var loadSessionDetail: Factory<LoadSessionDetail> {
    self { LoadSessionDetail(sessions: self.sessionRepository(), sleepStages: self.sleepStagePort()) }
  }

  var checkpointStore: Factory<any RecordingCheckpointStore> {
    self { SleepPersistence.makeCheckpointStore(url: self.storageLocation().checkpointURL) }.singleton
  }

  var commitSession: Factory<CommitSession> {
    self {
      CommitSession(
        sessions: self.sessionRepository(), checkpoints: self.checkpointStore(), health: self.healthAccess(),
        preferences: self.preferencesStore())
    }
  }

  var preferencesStore: Factory<any PreferencesStore> {
    self { SleepPersistence.makePreferencesStore() }.singleton
  }

  var profileStore: Factory<any ProfileStore> {
    self { SleepPersistence.makeProfileStore(url: self.storageLocation().profileURL) }.singleton
  }

  /// The brand's Apple Health, or `nil` (Lite doesn't link HealthKit).
  var healthAccess: Factory<(any HealthAccess)?> {
    self { self.brand().configuration.health }
  }

  /// A new writer per night: it holds that night's open file.
  var makeRawLogWriter: Factory<@Sendable () -> any RawLogWriter> {
    self {
      let clips = self.storageLocation().clipsDirectory
      return { SleepPersistence.makeRawLogWriter(directory: clips) }
    }
  }

  var enforceStorageLimits: Factory<EnforceStorageLimits> {
    self {
      EnforceStorageLimits(
        sessions: self.sessionRepository(), files: self.sessionFileStore(), checkpoints: self.checkpointStore(),
        preferences: self.preferencesStore())
    }
  }

  var deleteAllData: Factory<DeleteAllData> {
    self { DeleteAllData(sessions: self.sessionRepository(), files: self.sessionFileStore(), checkpoints: self.checkpointStore()) }
  }

  var discardRecording: Factory<DiscardRecording> {
    self { DiscardRecording(checkpoints: self.checkpointStore(), files: self.sessionFileStore()) }
  }

  var recoverInterruptedSession: Factory<RecoverInterruptedSession> {
    self { RecoverInterruptedSession(checkpoints: self.checkpointStore(), files: self.sessionFileStore()) }
  }

  /// Makes the microphone capture for one night, writing clips beside the
  /// others. A maker for the same reason as `makeClipPlayer`.
  var makeAudioCapture: Factory<@MainActor @Sendable () -> any AudioCapturePort> {
    self {
      let clips = self.storageLocation().clipsDirectory
      return { SleepAudio.makeAudioCapture(clipsDirectory: clips) }
    }
  }

  var deviceServices: Factory<DeviceServices> {
    self { .live }
  }

  var clipWaveformSource: Factory<any ClipWaveformSource> {
    self { SleepAudio.makeClipWaveformSource() }.singleton
  }

  /// Makes a player per player sheet (the sheet's state owner releases it).
  /// A maker, because the player is main-actor and Factory's closures aren't.
  var makeClipPlayer: Factory<@MainActor @Sendable () -> any ClipPlayer> {
    self { { SleepAudio.makeClipPlayer() } }
  }
}
