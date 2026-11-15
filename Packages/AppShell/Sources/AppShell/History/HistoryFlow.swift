import FactoryKit
import HistoryFeature
import ScreenKit
import SleepCore
import UIKit

/// The Sessions tab: the list of nights, and a night's detail (through
/// `NightDetailNavigation`). Screens say what the user asked for; this flow
/// decides what happens.
final class HistoryFlow: TabFlow {
  let tab = AppTab.history
  let navigator: any Navigator
  let nightDetail: NightDetailNavigation
  private let history: HistoryScreenComposer

  init(navigator: any Navigator, container: Container) {
    self.navigator = navigator
    history = HistoryScreenComposer(container: container)
    nightDetail = NightDetailNavigation(navigator: navigator, container: container)
  }

  func start() {
    navigator.setRoot(history.make(routes: HistoryRoutes(
      openNight: { [weak self] night in self?.nightDetail.show(night) })))
  }

  /// See `NightDetailNavigation.delete(_:)`.
  func delete(_ id: Night.ID) async {
    await nightDetail.delete(id)
  }
}
