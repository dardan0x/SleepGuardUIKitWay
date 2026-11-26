import FactoryKit
import HistoryFeature
import ScreenKit
import SessionDetailFeature
import SleepCore
import SleepGuardDesignKit
import SleepStrings
import UIKit

/// Builds the History list: dependencies, then its view model, then the
/// screen (ADR 0008). Wiring only.
struct HistoryScreenFactory {
  let container: Container

  func make(routes: HistoryRoutes) -> UIViewController {
    let dependencies = HistoryDependencies(nights: container.sessionRepository(), deleteNights: container.deleteSessions())
    return HistoryViewController(
      viewModel: HistoryViewModel(dependencies: dependencies, routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(title: Strings.tabSessions))
  }
}

/// Builds a night's detail, with its date as the title and delete in the bar.
struct SessionDetailFactory {
  let container: Container

  func make(
    night: NightSummary, report: BarItemActivity, onReport: @escaping @MainActor () -> Void,
    onDelete: @escaping @MainActor () -> Void,
    routes: SessionDetailRoutes) -> UIViewController
  {
    let dependencies = SessionDetailDependencies(
      nightID: night.id, loadDetail: container.loadSessionDetail(), enrichDetail: container.enrichNightWithStages())
    return SessionDetailViewController(
      viewModel: SessionDetailViewModel(dependencies: dependencies, routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(
        title: night.start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
        trailingItems: [
          BarItem(systemImage: "doc.text", accessibilityLabel: Strings.a11yExportReport, activity: report, action: onReport),
          BarItem(systemImage: "trash", accessibilityLabel: Strings.actionDelete, action: onDelete),
        ]))
  }

  /// The events sheet in its own navigation controller, for its title bar.
  func makeEventsSheet(
    rows: [EventListRow], events: [NightEvent], playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void,
    onClose: @escaping @MainActor () -> Void) -> UIViewController
  {
    let theme = container.theme()
    let screen = EventsSheetViewController(
      viewModel: EventsSheetViewModel(rows: rows, events: events, routes: EventsSheetRoutes(playEvents: playEvents)),
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
    let viewModel = PlayerViewModel(
      events: events, startEvent: start, player: container.makeClipPlayer()(), files: container.sessionFileStore(),
      waveforms: container.clipWaveformSource())
    let screen = PlayerViewController(
      viewModel: viewModel,
      theme: theme,
      chrome: ScreenChrome(
        title: Self.playerTitle(for: events.first { $0.id == start }?.category ?? .snoring),
        trailingItems: [BarItem(systemImage: "xmark.circle.fill", accessibilityLabel: Strings.actionClose, action: onClose)]))
    let navigation = UINavigationController(rootViewController: screen)
    Appearance.apply(theme, to: navigation.navigationBar)
    return navigation
  }

  /// "Couldn't create the report", with OK.
  func makeReportFailedAlert() -> UIViewController {
    let alert = UIAlertController(
      title: Strings.reportExportFailedTitle, message: Strings.reportExportFailedMessage, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel))
    return alert
  }

  func makeStagesInfo(_ stages: SleepStageBreakdown, onClose: @escaping @MainActor () -> Void) -> UIViewController {
    SleepStagesInfoViewController(
      viewModel: SleepStagesInfoViewModel(breakdown: stages, routes: SleepStagesInfoRoutes(close: onClose)),
      theme: container.theme())
  }

  static func playerTitle(for category: SoundCategory) -> String {
    switch category {
    case .snoring: Strings.eventPlayerNavigationTitle
    case .sleepTalking: Strings.eventPlayerSleepTalkingTitle
    case .noise, .coughing, .other: Strings.eventPlayerNoiseTitle
    }
  }
}
