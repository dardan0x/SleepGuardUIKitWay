import FactoryKit
import LearnFeature
import ScreenKit
import SleepGuardDesignKit
import UIKit

/// Builds the Learn screen: its view model with the brand's page, then the
/// screen (ADR 0008).
struct LearnFactory {
  let container: Container

  func make() -> UIViewController {
    LearnViewController(
      viewModel: LearnViewModel(url: container.brand().configuration.learnURL), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.tabLearn, hidesNavigationBar: true))
  }
}
