import SleepCore
import SleepGuardContentKit
import SwiftUI

/// The sleep-stages sheet, from the night detail or the dashboard: the shared
/// `SleepStagesInfoContent` with its own close button.
public struct SleepStagesInfoScreen: View {
  let breakdown: SleepStageBreakdown
  let close: @MainActor () -> Void

  public init(breakdown: SleepStageBreakdown, close: @escaping @MainActor () -> Void) {
    self.breakdown = breakdown
    self.close = close
  }

  public var body: some View {
    SleepStagesInfoContent(breakdown: breakdown) { close() }
  }
}
