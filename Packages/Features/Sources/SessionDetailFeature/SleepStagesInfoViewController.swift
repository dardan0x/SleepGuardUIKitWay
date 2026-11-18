import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The sleep-stages sheet, from the night detail or the dashboard: the shared
/// `SleepStagesInfoContent` with its own close button.
public final class SleepStagesInfoViewController: ScreenController {
  let breakdown: SleepStageBreakdown
  let close: @MainActor () -> Void

  public init(breakdown: SleepStageBreakdown, close: @escaping @MainActor () -> Void, theme: Theme) {
    self.breakdown = breakdown
    self.close = close
    super.init(theme: theme)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let close = close
    show(host(SleepStagesInfoContent(breakdown: breakdown) { close() }))
  }
}
