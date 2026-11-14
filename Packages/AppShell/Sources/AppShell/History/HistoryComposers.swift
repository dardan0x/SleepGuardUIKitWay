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

  func make(night: NightSummary, onDelete: @escaping @MainActor () -> Void, routes: SessionDetailRoutes) -> UIViewController {
    HostingScreen(
      rootView: SessionDetailScreen(
        dependencies: SessionDetailDependencies(nightID: night.id, loadDetail: container.loadSessionDetail()),
        routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(
        title: night.start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
        trailingItems: [BarItem(systemImage: "trash", accessibilityLabel: Strings.actionDelete, action: onDelete)]))
  }

  /// The events sheet in its own navigation controller, for its title bar.
  func makeEventsSheet(rows: [DetailEventRow], onClose: @escaping @MainActor () -> Void) -> UIViewController {
    let theme = container.theme()
    let screen = HostingScreen(
      rootView: EventsSheetScreen(rows: rows),
      theme: theme,
      chrome: ScreenChrome(
        title: Strings.recordingsDetailEventsLabel,
        trailingItems: [BarItem(systemImage: "xmark.circle.fill", accessibilityLabel: Strings.actionClose, action: onClose)]))
    let navigation = UINavigationController(rootViewController: screen)
    Appearance.apply(theme, to: navigation.navigationBar)
    return navigation
  }
}
