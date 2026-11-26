import BriefingFeature
import OnboardingFeature
import ScreenKit
import SleepCore
import SleepDomain
import UIKit

/// Owns the window's content: the onboarding on first launch, then the main
/// tabs, and the recording flow over them; and the links the app is opened
/// with (`AppRoute`).
public final class AppCoordinator {
  let composition: AppComposition
  private weak var window: UIWindow?
  /// Reads the preferences, then shows the onboarding or the tabs; awaited by tests.
  private(set) var launch: Task<Void, Never>?
  private(set) var onboarding: OnboardingFlow?
  private(set) var mainTabs: MainTabCoordinator?
  /// The night being recorded, from prestart to saved or discarded.
  private(set) var recording: RecordingFlow?
  /// Debug only: fills an empty store with sample nights.
  private var seeding: Task<Void, Never>?
  /// Looks for a night the app didn't get to finish; internal for tests.
  private(set) var recovery: Task<Void, Never>?
  /// The morning briefing, after the tabs (and any recovered night); awaited by tests.
  private(set) var briefing: Task<Void, Never>?
  /// A link that came while the app was busy (launching, the onboarding, a
  /// night recording, a sheet up); opened once it's free. Kept in memory only:
  /// a link doesn't outlive the launch it came in.
  private(set) var pendingRoute: AppRoute?
  /// Looking up a linked night; awaited by tests.
  private(set) var routing: Task<Void, Never>?
  /// The nights database didn't open; only the store-unavailable screen shows.
  private(set) var storeUnavailable = false
  /// Resolved at launch, used once the tabs are up.
  private let recoverInterruptedSession: RecoverInterruptedSession
  private let enforceStorageLimits: EnforceStorageLimits
  private let refreshStaleSummaries: RefreshStaleSummaries
  private let loadMorningBriefing: LoadMorningBriefing
  private let preferences: any PreferencesStore
  private let lifestyleLogs: any LifestyleLogStore

  init(composition: AppComposition) {
    self.composition = composition
    recoverInterruptedSession = composition.recoverInterruptedSession
    enforceStorageLimits = composition.enforceStorageLimits
    refreshStaleSummaries = composition.refreshStaleSummaries
    loadMorningBriefing = composition.loadMorningBriefing
    preferences = composition.preferences
    lifestyleLogs = composition.lifestyleLogs
  }

  deinit {
    seeding?.cancel()
    recovery?.cancel()
    briefing?.cancel()
  }

  /// The theme's background until the preferences say what comes first, so
  /// the tabs never flash before the onboarding.
  public func start(in window: UIWindow) {
    self.window = window
    let placeholder = UIViewController()
    placeholder.view.backgroundColor = UIColor(composition.theme.palette.bgPrimary)
    window.rootViewController = placeholder
    window.tintColor = UIColor(composition.theme.palette.accent)
    window.makeKeyAndVisible()
    guard composition.storeOpening.isAvailable else {
      showStoreUnavailable()
      return
    }
    let preferences = composition.preferences
    launch = Task { [weak self] in
      let completed = await preferences.load().hasCompletedOnboarding
      if completed {
        self?.showTabs()
      } else {
        self?.showOnboarding()
      }
    }
  }

  /// The nights database didn't open: this screen only, so no recovery, no
  /// recording and no sample nights reach the in-memory fallback.
  private func showStoreUnavailable() {
    let device = composition.device
    let update = composition.brand.configuration.appStoreID
      .flatMap { URL(string: "https://apps.apple.com/app/id\($0)") }
      .map { url in { @MainActor in device.openURL(url) } }
    window?.rootViewController = StoreUnavailableViewController(
      viewModel: StoreUnavailableViewModel(update: update), theme: composition.theme)
    storeUnavailable = true
  }

  private func showOnboarding() {
    let navigator = NavigationControllerNavigator()
    let flow = composition.onboardingFlow(navigator: navigator) { [weak self] startRecording in
      self?.onboarding = nil
      self?.showTabs()
      if startRecording { self?.startRecording() }
    }
    flow.start()
    onboarding = flow
    window?.rootViewController = navigator.navigationController
  }

  /// The app proper. A night left unfinished and the Debug sample nights wait
  /// for it: nothing runs over the onboarding.
  private func showTabs() {
    let mainTabs = composition.mainTabs(onStartRecording: { [weak self] in self?.startRecording() })
    window?.rootViewController = mainTabs.tabBarController
    self.mainTabs = mainTabs
    offerInterruptedNight()
    offerBriefing()
    seedSampleNightsInDebug()
  }

  /// The morning briefing as a sheet over the tabs, once per new night, when
  /// nothing else is showing (a recovered night comes first). Shown counts
  /// from when it opens, however it's closed.
  private func offerBriefing() {
    let (load, preferences, logs) = (loadMorningBriefing, preferences, lifestyleLogs)
    briefing = Task { [weak self] in
      await self?.recovery?.value
      guard let self else { return }
      guard let due = await load(), recording == nil,
            let tabs = mainTabs?.tabBarController, tabs.presentedViewController == nil else { return openPendingRoute() }
      var shown = await preferences.load()
      shown.lastBriefingShown = Date()
      await preferences.save(shown)
      let sheet = composition.briefingFactory().make(
        briefing: due.briefing,
        routes: BriefingRoutes(
          answer: { [weak tabs] chip in
            Task { try? await logs.save(LifestyleLog(night: due.night.start, chips: [chip])) }
            tabs?.dismiss(animated: true) { [weak self] in self?.openPendingRoute() }
          },
          close: { [weak tabs, weak self] in tabs?.dismiss(animated: true) { self?.openPendingRoute() } }))
      sheet.sheetPresentationController?.detents = [.large()]
      tabs.present(sheet, animated: true)
    }
  }

  // MARK: - Links

  /// A link the app was opened with. Unknown ones are ignored.
  public func open(_ url: URL) {
    guard let route = AppRoute(url: url) else {
      Log.app.notice("Ignoring a link the app doesn't know")
      return
    }
    handle(route)
  }

  /// Now when the app is free; otherwise kept until it is. "Start" while a
  /// night is recording has nothing to start, so it's dropped.
  func handle(_ route: AppRoute) {
    if route == .startRecording, recording != nil { return }
    guard let mainTabs, !isBusy(mainTabs) else {
      pendingRoute = route
      return
    }
    pendingRoute = nil
    switch route {
    case .startRecording:
      startRecording()
    case .lastSevenNights:
      guard let flow = mainTabs.select(.statistics) as? StatisticsFlow else { return }
      flow.navigator.popToRoot()
      flow.showLastSevenNights()
    case let .night(id):
      let nights = composition.nights
      routing = Task { [weak self] in
        // A night deleted since the link was made: the app stays where it is.
        guard let night = try? await nights.session(id: id), let tabs = self?.mainTabs else { return }
        guard let flow = (tabs.select(.history) ?? tabs.select(.statistics)) as? NightDetailHosting else { return }
        flow.navigator.popToRoot()
        flow.nightDetail.show(night.summary())
      }
    }
  }

  private func isBusy(_ tabs: MainTabCoordinator) -> Bool {
    recording != nil || tabs.tabBarController.presentedViewController.map { !$0.isBeingDismissed } ?? false
  }

  private func openPendingRoute() {
    if let route = pendingRoute { handle(route) }
  }

  /// "Start recording" from any screen: the recording flow, full screen over
  /// the tabs. One at a time.
  func startRecording() {
    presentRecording { $0.start() }
  }

  /// A night interrupted by a crash, a kill or a dead battery comes back as
  /// its summary, for Save or Discard (SleepGuard does the same at launch).
  /// Then stored scores made by an older formula are recomputed (before the
  /// briefing, which waits for this task, reads them), and the storage limits
  /// run, as SleepGuard does at launch. An offered night keeps its checkpoint
  /// until saved or discarded, so its files stay.
  private func offerInterruptedNight() {
    let recover = recoverInterruptedSession
    let refreshScores = refreshStaleSummaries
    let enforceLimits = enforceStorageLimits
    recovery = Task { [weak self] in
      if let night = await recover() {
        Log.app.notice("Offering a night interrupted before it was saved")
        self?.presentRecording { $0.start(recovering: night) }
      }
      do {
        let refreshed = try await refreshScores()
        if refreshed > 0 { Log.storage.notice("Recomputed \(refreshed, privacy: .public) stale scores") }
      } catch {
        Log.storage.error("Score refresh failed at launch: \(error.localizedDescription, privacy: .public)")
      }
      do {
        try await enforceLimits()
      } catch {
        Log.storage.error("Storage limits failed at launch: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  private func presentRecording(_ begin: (RecordingFlow) -> Void) {
    guard recording == nil, let tabs = mainTabs?.tabBarController else { return }
    let navigator = NavigationControllerNavigator()
    let height = tabs.view.window?.windowScene?.screen.bounds.height ?? 0
    let flow = composition.recordingFlow(navigator: navigator, compactHeight: height <= 874) { [weak self] in
      self?.recording = nil
      tabs.dismiss(animated: true) { self?.openPendingRoute() }
    }
    begin(flow)
    recording = flow
    navigator.navigationController.modalPresentationStyle = .fullScreen
    tabs.present(navigator.navigationController, animated: true)
  }

  private func seedSampleNightsInDebug() {
    #if DEBUG
    seeding = composition.seedSampleNights(onlyIfEmpty: true)
    #endif
  }
}
