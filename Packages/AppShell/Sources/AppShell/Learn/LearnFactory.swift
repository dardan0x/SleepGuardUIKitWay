import FactoryKit
import LearnFeature
import ScreenKit
import SleepGuardDesignKit
import UIKit

/// Builds the Learn screen with the brand's page. Display only, so no view
/// model (ADR 0008).
struct LearnFactory {
  let container: Container

  func make() -> UIViewController {
    LearnViewController(
      url: container.brand().configuration.learnURL, theme: container.theme(),
      chrome: ScreenChrome(title: Strings.tabLearn, hidesNavigationBar: true))
  }
}
