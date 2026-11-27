import FactoryKit
import SleepAudioAdapter
import SleepCore
import SleepDomain
import SleepFiles
import SleepGuardDesignKit
import SleepLogging
import SleepPersistenceAdapter
import UIKit

/// The shell's registrations. Everything derives from `brand`, the one value
/// supplied from outside. Only `AppShell` imports Factory; packages below it
/// take plain initializer arguments, and so do the flows (`AppComposition`
/// builds them).
///
/// The app never uses `Container.shared`: `AppComposition` makes its own
/// container and registers the brand before returning it, so nothing can
/// resolve without a brand. The default below is unreachable from the app;
/// it only catches a test container made without one.
extension Container {
  var brand: Factory<any BrandComposition> {
    self { fatalError("A container needs its brand: make it through AppComposition(brand:)") }
      .cached
  }

  var theme: Factory<Theme> {
    self { self.brand().configuration.theme }
  }

  var storageLocation: Factory<StorageLocation> {
    self {
      // The shared layout (SleepGuard's too), under this app's folder.
      StorageLocation.resolve(
        appGroup: Bundle.main.object(forInfoDictionaryKey: "SGAppGroup") as? String, folder: "SleepGuardUIKitWay")
    }.cached
  }

  /// The nights database, opened once. If the file can't be opened, this
  /// launch gets an in-memory store and `isAvailable` is false: the app then
  /// shows only "We couldn't open your sleep data" (`AppCoordinator`), so
  /// nothing is recorded into a store that would be lost. The file is left
  /// alone, never deleted, and the next launch (or an update) tries again.
  var storeOpening: Factory<StoreOpening> {
    self {
      let url = self.storageLocation().storeURL
      do {
        return try StoreOpening(repository: SleepPersistenceAdapter.makeSessionRepository(storeURL: url), isAvailable: true)
      } catch {
        Log.storage.fault("Couldn't open the nights store: \(error.localizedDescription, privacy: .public)")
        do {
          return try StoreOpening(repository: SleepPersistenceAdapter.makeSessionRepository(storeURL: nil), isAvailable: false)
        } catch {
          // Not even an in-memory store: SwiftData itself can't start, and
          // there is no app to show.
          fatalError("SwiftData can't create an in-memory store: \(error)")
        }
      }
    }
    // Once per container (`.singleton` would be one for every container in
    // the process, so a test's container could get another test's store).
    .cached
  }

  var sessionRepository: Factory<any SessionRepositoryPort> {
    self { self.storeOpening().repository }.cached
  }

  var sessionFileStore: Factory<any SessionFileStorePort> {
    self { SleepPersistenceAdapter.makeSessionFileStore(directory: self.storageLocation().clipsDirectory) }.cached
  }

  /// The brand's Apple Health reads the stages; a brand without it has none.
  var sleepStageSource: Factory<any SleepStageSourcePort> {
    self {
      guard let health = self.healthAccess() else { return NoSleepStages() as any SleepStageSourcePort }
      return health
    }.cached
  }

  var deleteSession: Factory<DeleteSessionUseCase> {
    self { DeleteSessionUseCase(sessions: self.sessionRepository(), files: self.sessionFileStore()) }
  }

  var deleteSessions: Factory<DeleteSessionsUseCase> {
    self { DeleteSessionsUseCase(sessions: self.sessionRepository(), files: self.sessionFileStore()) }
  }

  var refreshStaleSummaries: Factory<RefreshStaleSummariesUseCase> {
    self { RefreshStaleSummariesUseCase(sessions: self.sessionRepository()) }
  }

  var loadSessionDetail: Factory<LoadSessionDetailUseCase> {
    self { LoadSessionDetailUseCase(sessions: self.sessionRepository()) }
  }

  var enrichNightWithStages: Factory<EnrichNightWithStagesUseCase> {
    self { EnrichNightWithStagesUseCase(sessions: self.sessionRepository(), sleepStages: self.sleepStageSource()) }
  }

  var checkpointStore: Factory<any RecordingCheckpointStorePort> {
    self { SleepPersistenceAdapter.makeCheckpointStore(url: self.storageLocation().checkpointURL) }.cached
  }

  /// When a stopped night is long enough to save. The shipped rule is 30
  /// minutes; Debug builds take 2 so a night can be tried at a desk. The
  /// choice is this app's (SleepCore's `SaveRules`), not the shared
  /// package's build configuration.
  var saveRules: Factory<SaveRules> {
    self {
      #if DEBUG
      SaveRules(minimumDuration: 120)
      #else
      .standard
      #endif
    }
  }

  var commitSession: Factory<CommitSessionUseCase> {
    self {
      CommitSessionUseCase(
        sessions: self.sessionRepository(), checkpoints: self.checkpointStore(), health: self.healthAccess(),
        preferences: self.preferencesStore(), saveRules: self.saveRules())
    }
  }

  var preferencesStore: Factory<any PreferencesStorePort> {
    self { SleepPersistenceAdapter.makePreferencesStore() }.cached
  }

  var profileStore: Factory<any ProfileStorePort> {
    self { SleepPersistenceAdapter.makeProfileStore(url: self.storageLocation().profileURL) }.cached
  }

  var lifestyleLogStore: Factory<any LifestyleLogStorePort> {
    self { SleepPersistenceAdapter.makeLifestyleLogStore(url: self.storageLocation().lifestyleLogURL) }.cached
  }

  var loadMorningBriefing: Factory<LoadMorningBriefingUseCase> {
    self {
      LoadMorningBriefingUseCase(
        nights: self.sessionRepository(), profiles: self.profileStore(), logs: self.lifestyleLogStore(),
        preferences: self.preferencesStore())
    }
  }

  var shouldAskForProfile: Factory<ShouldAskForProfileUseCase> {
    self {
      ShouldAskForProfileUseCase(
        nights: self.sessionRepository(), profiles: self.profileStore(), preferences: self.preferencesStore(),
        saveRules: self.saveRules())
    }
  }

  /// The brand's Apple Health, or `nil` (Lite doesn't link HealthKit).
  var healthAccess: Factory<(any HealthAccessPort)?> {
    self { self.brand().configuration.health }
  }

  /// Makes the Snore Interrupter's sounds, or `nil` in a brand without it.
  /// A maker, because the store is main-actor (it reads its list when made).
  var makeMelodyStore: Factory<(@MainActor @Sendable () -> any MelodyStorePort)?> {
    self {
      guard self.brand().configuration.snoreInterrupter else { return nil }
      let directory = self.storageLocation().melodiesDirectory
      return { SleepAudioAdapter.makeMelodyStore(directory: directory) }
    }
  }

  /// The interrupter's player (`preview: false`, a new one per night) or the
  /// picker's preview player. A maker, as for `makeClipPlayer`.
  var makeMelodyPlayer: Factory<@MainActor @Sendable (_ preview: Bool) -> any MelodyPlayerPort> {
    self {
      { preview in
        preview ? SleepAudioAdapter.makePreviewPlayer() : SleepAudioAdapter.makeMelodyPlayer {
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
      }
    }
  }

  var makeMelodyRecorder: Factory<@MainActor @Sendable () -> any MelodyRecorderPort> {
    self { { SleepAudioAdapter.makeMelodyRecorder() } }
  }

  /// A new writer per night: it holds that night's open file.
  var makeRawLogWriter: Factory<@Sendable () -> any RawLogWriterPort> {
    self {
      let clips = self.storageLocation().clipsDirectory
      return { SleepPersistenceAdapter.makeRawLogWriter(directory: clips) }
    }
  }

  var enforceStorageLimits: Factory<EnforceStorageLimitsUseCase> {
    self {
      EnforceStorageLimitsUseCase(
        sessions: self.sessionRepository(), files: self.sessionFileStore(), checkpoints: self.checkpointStore(),
        preferences: self.preferencesStore())
    }
  }

  var deleteAllData: Factory<DeleteAllDataUseCase> {
    self { DeleteAllDataUseCase(sessions: self.sessionRepository(), files: self.sessionFileStore(), checkpoints: self.checkpointStore()) }
  }

  var discardRecording: Factory<DiscardRecordingUseCase> {
    self { DiscardRecordingUseCase(checkpoints: self.checkpointStore(), files: self.sessionFileStore()) }
  }

  var recoverInterruptedSession: Factory<RecoverInterruptedSessionUseCase> {
    self { RecoverInterruptedSessionUseCase(checkpoints: self.checkpointStore(), files: self.sessionFileStore()) }
  }

  /// Makes the microphone capture for one night, writing clips beside the
  /// others. A maker for the same reason as `makeClipPlayer`.
  var makeAudioCapture: Factory<@MainActor @Sendable () -> any AudioCapturePort> {
    self {
      let clips = self.storageLocation().clipsDirectory
      return { SleepAudioAdapter.makeAudioCapture(clipsDirectory: clips) }
    }
  }

  var deviceServices: Factory<DeviceServices> {
    self { .live }
  }

  var clipWaveformSource: Factory<any ClipWaveformSourcePort> {
    self { SleepAudioAdapter.makeClipWaveformSource() }.cached
  }

  /// Makes a player per player sheet (the sheet's state owner releases it).
  /// A maker, because the player is main-actor and Factory's closures aren't.
  var makeClipPlayer: Factory<@MainActor @Sendable () -> any ClipPlayerPort> {
    self { { SleepAudioAdapter.makeClipPlayer() } }
  }
}

/// The nights database and whether it opened from its file.
struct StoreOpening: Sendable {
  let repository: any SessionRepositoryPort
  /// False when the file couldn't be opened and `repository` is in memory.
  let isAvailable: Bool
}
