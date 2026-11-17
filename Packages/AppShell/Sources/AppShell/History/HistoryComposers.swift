import FactoryKit
import HistoryFeature
import ScreenKit
import SessionDetailFeature
import SleepCore
import SleepGuardDesignKit
import UIKit

/// Builds the History list. Wiring only: resolve, build the screen, host it.
struct HistoryScreenComposer {
  let container: Container

  func make(routes: HistoryRoutes) -> UIViewController {
    HostingScreen(
      rootView: HistoryScreen(
        dependencies: HistoryDependencies(nights: container.sessionRepository(), deleteNight: container.deleteSession()),
        routes: routes),
      theme: container.theme(),
      // Inline: UIKit doesn't create the large title over a hosted SwiftUI
      // List (no large-title view in the bar, checked on iOS 26.2).
      chrome: ScreenChrome(title: Strings.tabSessions))
  }
}

/// Builds a night's detail, with its date as the title and delete in the bar.
struct SessionDetailComposer {
  let container: Container

  func make(
    night: NightSummary, onReport: @escaping @MainActor () -> Void, onDelete: @escaping @MainActor () -> Void,
    routes: SessionDetailRoutes) -> UIViewController
  {
    HostingScreen(
      rootView: SessionDetailScreen(
        dependencies: SessionDetailDependencies(nightID: night.id, loadDetail: container.loadSessionDetail()),
        routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(
        title: night.start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
        trailingItems: [
          BarItem(systemImage: "doc.text", accessibilityLabel: Strings.a11yExportReport, action: onReport),
          BarItem(systemImage: "trash", accessibilityLabel: Strings.actionDelete, action: onDelete),
        ]))
  }

  /// The events sheet in its own navigation controller, for its title bar.
  func makeEventsSheet(
    rows: [EventListRow], events: [NightEvent], playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void,
    onClose: @escaping @MainActor () -> Void) -> UIViewController
  {
    let theme = container.theme()
    let screen = HostingScreen(
      rootView: EventsSheetScreen(rows: rows, events: events, playEvents: playEvents),
      theme: theme,
      chrome: ScreenChrome(
        title: Strings.recordingsDetailEventsLabel,
        trailingItems: [BarItem(systemImage: "xmark.circle.fill", accessibilityLabel: Strings.actionClose, action: onClose)]))
    let navigation = UINavigationController(rootViewController: screen)
    Appearance.apply(theme, to: navigation.navigationBar)
    return navigation
  }

  /// The player: a state owner over a new clip player, titled by the kind of
  /// event, with a close button.
  func makePlayer(events: [NightEvent], start: NightEvent.ID, onClose: @escaping @MainActor () -> Void) -> UIViewController {
    let theme = container.theme()
    let model = ClipPlaybackModel(
      events: events, startEvent: start, player: container.makeClipPlayer()(), files: container.sessionFileStore(),
      waveforms: container.clipWaveformSource())
    let screen = HostingScreen(
      rootView: PlayerScreen(model: model),
      theme: theme,
      chrome: ScreenChrome(
        title: Self.playerTitle(for: events.first { $0.id == start }?.category ?? .snoring),
        trailingItems: [BarItem(systemImage: "xmark.circle.fill", accessibilityLabel: Strings.actionClose, action: onClose)]))
    let navigation = UINavigationController(rootViewController: screen)
    Appearance.apply(theme, to: navigation.navigationBar)
    return navigation
  }

  func makeStagesInfo(_ stages: SleepStageBreakdown, onClose: @escaping @MainActor () -> Void) -> UIViewController {
    HostingScreen(rootView: SleepStagesInfoScreen(breakdown: stages, close: onClose), theme: container.theme())
  }

  static func playerTitle(for category: SoundCategory) -> String {
    switch category {
    case .snoring: Strings.eventPlayerNavigationTitle
    case .sleepTalking: Strings.eventPlayerSleepTalkingTitle
    case .noise, .coughing, .other: Strings.eventPlayerNoiseTitle
    }
  }
}
