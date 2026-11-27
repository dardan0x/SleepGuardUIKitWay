import LearnFeature
import ScreenKit
import SleepGuardDesignKit
import UIKit

/// The Learn tab: one screen with the brand's Learn page. The content draws
/// its own title row (as in SleepGuard), so the navigation bar is hidden; the
/// title stays on the item for VoiceOver and the app switcher.
final class LearnFlow: TabFlow {
  let tab = AppTab.learn
  let navigator: any Navigator
  private let factory: LearnFactory

  init(navigator: any Navigator, factory: LearnFactory) {
    self.navigator = navigator
    self.factory = factory
  }

  func start() {
    navigator.setRoot(factory.make())
  }
}
