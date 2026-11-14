import ScreenKit
import SleepGuardDesignKit
import UIKit

/// Builds placeholder screens. Wiring only, like every composer.
struct PlaceholderScreenComposer {
  let theme: Theme

  func makeRoot(for tab: AppTab, routes: PlaceholderRoutes) -> UIViewController {
    HostingScreen(
      rootView: PlaceholderScreen(iconName: tab.iconName, routes: routes),
      theme: theme,
      chrome: ScreenChrome(title: tab.title, largeTitle: true))
  }

  func makeDetails(for tab: AppTab, routes: PlaceholderRoutes) -> UIViewController {
    HostingScreen(rootView: PlaceholderScreen(iconName: tab.iconName, routes: routes), theme: theme)
  }
}

/// One tab's flow until its feature exists. "Continue" presents a sheet; inside
/// a sheet it presents another above it; "Close" dismisses the top one.
final class PlaceholderFlow {
  let tab: AppTab
  let navigator: any Navigator
  private let composer: PlaceholderScreenComposer

  init(tab: AppTab, navigator: any Navigator, composer: PlaceholderScreenComposer) {
    self.tab = tab
    self.navigator = navigator
    self.composer = composer
  }

  func start() {
    navigator.setRoot(composer.makeRoot(for: tab, routes: PlaceholderRoutes(
      showDetails: { [weak self] in self?.showDetails() })))
  }

  private func showDetails() {
    navigator.present(
      composer.makeDetails(for: tab, routes: PlaceholderRoutes(
        showDetails: { [weak self] in self?.showDetails() },
        close: { [weak self] in self?.navigator.dismiss() })),
      style: .sheet(detents: [.medium, .large]))
  }
}
