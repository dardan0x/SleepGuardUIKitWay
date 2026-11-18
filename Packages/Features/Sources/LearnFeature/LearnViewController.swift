import ScreenKit
import SleepGuardContentKit
import UIKit

/// The Learn tab, hosting the shared `LearnContent`: the brand's Learn page,
/// or "No content available" when it has none.
public final class LearnViewController: ScreenController {
  let url: URL?

  public init(url: URL?, theme: Theme, chrome: ScreenChrome) {
    self.url = url
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    render(LearnContent(url: url))
  }
}
