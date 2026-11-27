import HistoryFeature
import ScreenKit
import SleepCore
import UIKit

/// The Sessions tab: the list of nights, and a night's detail (through
/// `NightDetailNavigation`). Screens say what the user asked for; this flow
/// decides what happens.
final class HistoryFlow: NightDetailHosting {
  let tab = AppTab.history
  let navigator: any Navigator
  let nightDetail: NightDetailNavigation
  private let history: HistoryScreenFactory

  init(navigator: any Navigator, history: HistoryScreenFactory, nightDetail: NightDetailNavigation) {
    self.navigator = navigator
    self.history = history
    self.nightDetail = nightDetail
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
