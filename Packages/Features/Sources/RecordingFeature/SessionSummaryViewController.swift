import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The night just recorded, in the shared `SessionSummaryContent`: how long,
/// its score, snoring share and events, the banners that explain gaps, its
/// timeline, then Save or Discard. A night under `Night.minimumSaveDuration`
/// can't be saved, as in SleepGuard.
public final class SessionSummaryViewController: ScreenController {
  let night: Night
  let scoreConfig: SleepScoreConfig
  let routes: SessionSummaryRoutes

  public init(
    night: Night, scoreConfig: SleepScoreConfig = .default, routes: SessionSummaryRoutes, theme: Theme,
    chrome: ScreenChrome)
  {
    self.night = night
    self.scoreConfig = scoreConfig
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let (night, routes) = (night, routes)
    render(SessionSummaryContent(
      night: night, summary: night.summary(using: scoreConfig),
      onSave: { [weak self] in self?.saveTapped() }, onDiscard: { routes.discard(night) }))
  }

  /// Internal for tests.
  func saveTapped() {
    guard night.duration >= Night.minimumSaveDuration else { return present(tooShortAlert(), animated: true) }
    routes.save(night)
  }

  func tooShortAlert() -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionSummaryTooShortTitle,
      message: String(format: Strings.sessionSummaryTooShortInfoFormat, Int(Night.minimumSaveDuration / 60)),
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel))
    return alert
  }
}
