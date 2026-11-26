import FactoryKit
import SleepAudio
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SleepPersistence
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
    self { StorageLocation.resolve() }.cached
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
        return try StoreOpening(repository: SleepPersistence.makeSessionRepository(storeURL: url), isAvailable: true)
      } catch {
        Log.storage.fault("Couldn't open the nights store: \(error.localizedDescription, privacy: .public)")
        do {
          return try StoreOpening(repository: SleepPersistence.makeSessionRepository(storeURL: nil), isAvailable: false)
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

  var sessionRepository: Factory<any SessionRepository> {
    self { self.storeOpening().repository }.cached
  }

  var sessionFileStore: Factory<any SessionFileStore> {
    self { SleepPersistence.makeSessionFileStore(directory: self.storageLocation().clipsDirectory) }.cached
  }

  /// The brand's Apple Health reads the stages; a brand without it has none.
  var sleepStageSource: Factory<any SleepStageSource> {
    self {
      guard let health = self.healthAccess() else { return NoSleepStages() as any SleepStageSource }
      return health
    }.cached
  }

  var deleteSession: Factory<DeleteSession> {
    self { DeleteSession(sessions: self.sessionRepository(), files: self.sessionFileStore()) }
  }

  var deleteSessions: Factory<DeleteSessions> {
    self { DeleteSessions(sessions: self.sessionRepository(), files: self.sessionFileStore()) }
  }

  var refreshStaleSummaries: Factory<RefreshStaleSummaries> {
    self { RefreshStaleSummaries(sessions: self.sessionRepository()) }
  }

  var loadSessionDetail: Factory<LoadSessionDetail> {
    self { LoadSessionDetail(sessions: self.sessionRepository()) }
  }

  var enrichNightWithStages: Factory<EnrichNightWithStages> {
    self { EnrichNightWithStages(sessions: self.sessionRepository(), sleepStages: self.sleepStageSource()) }
  }

  var checkpointStore: Factory<any RecordingCheckpointStore> {
    self { SleepPersistence.makeCheckpointStore(url: self.storageLocation().checkpointURL) }.cached
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

  var commitSession: Factory<CommitSession> {
    self {
      CommitSession(
        sessions: self.sessionRepository(), checkpoints: self.checkpointStore(), health: self.healthAccess(),
        preferences: self.preferencesStore(), saveRules: self.saveRules())
    }
  }

  var preferencesStore: Factory<any PreferencesStore> {
    self { SleepPersistence.makePreferencesStore() }.cached
  }

  var profileStore: Factory<any ProfileStore> {
    self { SleepPersistence.makeProfileStore(url: self.storageLocation().profileURL) }.cached
  }

  var lifestyleLogStore: Factory<any LifestyleLogStore> {
    self { SleepPersistence.makeLifestyleLogStore(url: self.storageLocation().lifestyleLogURL) }.cached
  }

  var loadMorningBriefing: Factory<LoadMorningBriefing> {
    self {
      LoadMorningBriefing(
        nights: self.sessionRepository(), profiles: self.profileStore(), logs: self.lifestyleLogStore(),
        preferences: self.preferencesStore())
    }
  }

  var shouldAskForProfile: Factory<ShouldAskForProfile> {
    self {
      ShouldAskForProfile(
        nights: self.sessionRepository(), profiles: self.profileStore(), preferences: self.preferencesStore(),
        saveRules: self.saveRules())
    }
  }

  /// The brand's Apple Health, or `nil` (Lite doesn't link HealthKit).
  var healthAccess: Factory<(any HealthAccess)?> {
    self { self.brand().configuration.health }
  }

  /// Makes the Snore Interrupter's sounds, or `nil` in a brand without it.
  /// A maker, because the store is main-actor (it reads its list when made).
  var makeMelodyStore: Factory<(@MainActor @Sendable () -> any MelodyStore)?> {
    self {
      guard self.brand().configuration.snoreInterrupter else { return nil }
      let directory = self.storageLocation().melodiesDirectory
      return { SleepAudio.makeMelodyStore(directory: directory) }
    }
  }

  /// The interrupter's player (`preview: false`, a new one per night) or the
  /// picker's preview player. A maker, as for `makeClipPlayer`.
  var makeMelodyPlayer: Factory<@MainActor @Sendable (_ preview: Bool) -> any MelodyPlayer> {
    self {
      { preview in
        preview ? SleepAudio.makePreviewPlayer() : SleepAudio.makeMelodyPlayer {
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
      }
    }
  }

  var makeMelodyRecorder: Factory<@MainActor @Sendable () -> any MelodyRecorder> {
    self { { SleepAudio.makeMelodyRecorder() } }
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
  var makeAudioCapture: Factory<@MainActor @Sendable () -> any AudioCapture> {
    self {
      let clips = self.storageLocation().clipsDirectory
      return { SleepAudio.makeAudioCapture(clipsDirectory: clips) }
    }
  }

  var deviceServices: Factory<DeviceServices> {
    self { .live }
  }

  var clipWaveformSource: Factory<any ClipWaveformSource> {
    self { SleepAudio.makeClipWaveformSource() }.cached
  }

  /// Makes a player per player sheet (the sheet's state owner releases it).
  /// A maker, because the player is main-actor and Factory's closures aren't.
  var makeClipPlayer: Factory<@MainActor @Sendable () -> any ClipPlayer> {
    self { { SleepAudio.makeClipPlayer() } }
  }
}

/// The nights database and whether it opened from its file.
struct StoreOpening: Sendable {
  let repository: any SessionRepository
  /// False when the file couldn't be opened and `repository` is in memory.
  let isAvailable: Bool
}
