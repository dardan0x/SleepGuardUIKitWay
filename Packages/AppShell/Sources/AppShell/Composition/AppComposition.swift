import FactoryKit
import Foundation
import ScreenKit
import SleepAudio
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SleepLogging

/// One brand's object graph: the composition root (ADR 0009).
///
/// It owns a container of its own (never `Container.shared`) with the brand
/// registered before anything can resolve, and it builds every flow with
/// exactly what that flow uses: a flow never sees the container, so what it
/// depends on is in its initializer. The screen factories stay composition
/// code and read the container.
@MainActor
public final class AppComposition {
  public let brand: any BrandComposition
  let container: Container

  public init(brand: some BrandComposition) {
    let container = Container()
    container.brand.register { brand }
    self.brand = brand
    self.container = container
  }

  /// Over a container a test filled (its brand registered).
  init(container: Container) {
    self.container = container
    brand = container.brand()
  }

  var theme: Theme {
    brand.configuration.theme
  }

  // MARK: - Flows

  func mainTabs(onStartRecording: @escaping @MainActor () -> Void = {}) -> MainTabCoordinator {
    MainTabCoordinator(theme: theme, tabs: brand.configuration.tabs) { [unowned self] tab, navigator in
      switch tab {
      case .history: historyFlow(navigator: navigator)
      case .statistics: statisticsFlow(navigator: navigator, onStartRecording: onStartRecording)
      case .settings: settingsFlow(navigator: navigator)
      case .learn: learnFlow(navigator: navigator)
      }
    }
  }

  func historyFlow(navigator: any Navigator) -> HistoryFlow {
    HistoryFlow(
      navigator: navigator, history: HistoryScreenFactory(container: container),
      nightDetail: nightDetail(navigator: navigator))
  }

  func statisticsFlow(navigator: any Navigator, onStartRecording: @escaping @MainActor () -> Void) -> StatisticsFlow {
    StatisticsFlow(
      navigator: navigator, screens: StatisticsFactory(container: container),
      settings: SettingsFactory(container: container), preferences: container.preferencesStore(),
      nightDetail: nightDetail(navigator: navigator), onStartRecording: onStartRecording)
  }

  func settingsFlow(navigator: any Navigator) -> SettingsFlow {
    #if DEBUG
    let seed: (@MainActor () -> Task<Void, Never>)? = { [unowned self] in seedSampleNights(onlyIfEmpty: false) }
    #else
    let seed: (@MainActor () -> Task<Void, Never>)? = nil
    #endif
    return SettingsFlow(
      navigator: navigator, factory: SettingsFactory(container: container), device: container.deviceServices(),
      appStoreID: brand.configuration.appStoreID, seedSampleNights: seed)
  }

  func learnFlow(navigator: any Navigator) -> LearnFlow {
    LearnFlow(navigator: navigator, factory: LearnFactory(container: container))
  }

  func nightDetail(navigator: any Navigator) -> NightDetailNavigation {
    NightDetailNavigation(
      navigator: navigator, detail: SessionDetailFactory(container: container),
      deleteSession: container.deleteSession(), nights: container.sessionRepository(),
      clipsDirectory: container.storageLocation().clipsDirectory)
  }

  func onboardingFlow(
    navigator: any Navigator,
    onFinish: @escaping @MainActor (_ startRecording: Bool) -> Void) -> OnboardingFlow
  {
    OnboardingFlow(
      navigator: navigator, factory: OnboardingFactory(container: container),
      preferences: container.preferencesStore(), onFinish: onFinish)
  }

  func recordingFlow(
    navigator: any Navigator,
    compactHeight: Bool,
    onClose: @escaping @MainActor () -> Void) -> RecordingFlow
  {
    RecordingFlow(
      navigator: navigator, factory: RecordingFactory(container: container, compactHeight: compactHeight),
      commit: container.commitSession(), discardRecording: container.discardRecording(),
      enforceStorageLimits: container.enforceStorageLimits(), device: container.deviceServices(),
      preferences: container.preferencesStore(), onClose: onClose)
  }

  func briefingFactory() -> BriefingFactory {
    BriefingFactory(container: container)
  }

  // MARK: - What the app coordinator runs

  var storeOpening: StoreOpening {
    container.storeOpening()
  }

  var device: DeviceServices {
    container.deviceServices()
  }

  var nights: any SessionRepository {
    container.sessionRepository()
  }

  var preferences: any PreferencesStore {
    container.preferencesStore()
  }

  var lifestyleLogs: any LifestyleLogStore {
    container.lifestyleLogStore()
  }

  var recoverInterruptedSession: RecoverInterruptedSession {
    container.recoverInterruptedSession()
  }

  var enforceStorageLimits: EnforceStorageLimits {
    container.enforceStorageLimits()
  }

  var refreshStaleSummaries: RefreshStaleSummaries {
    container.refreshStaleSummaries()
  }

  var loadMorningBriefing: LoadMorningBriefing {
    container.loadMorningBriefing()
  }

  /// Debug: the sample nights and their clips, into the store (only an empty
  /// one, at launch; any, from Settings).
  /// The nights are SleepCore's `SampleNights` (the same as SleepGuard's),
  /// with their clips and survey answers. Real data is left alone.
  func seedSampleNights(onlyIfEmpty: Bool) -> Task<Void, Never> {
    let repository = container.sessionRepository()
    let logs = container.lifestyleLogStore()
    let clips = container.storageLocation().clipsDirectory
    return Task {
      do {
        if onlyIfEmpty {
          var current = await repository.observeSummaries().makeAsyncIterator()
          guard let existing = await current.next(), existing.isEmpty else { return }
        }
        let nights = SampleNights.make()
        let samples = SampleNights.clips(of: nights)
        try await Task.detached(priority: .utility) {
          for clip in samples {
            try SleepAudio.writeSampleClip(
              to: clips.appendingPathComponent(clip.name), seconds: clip.seconds, intensity: clip.intensity)
          }
        }.value
        let version = SleepScore.cacheVersion(for: .default)
        for night in nights {
          try await repository.save(night, summary: night.summary(), scoreVersion: version)
        }
        for log in SampleNights.lifestyleLogs(for: nights) {
          try await logs.save(log)
        }
      } catch {
        Log.storage.error("Seeding sample nights failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
