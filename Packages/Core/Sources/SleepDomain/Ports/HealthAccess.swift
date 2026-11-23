import Foundation
import SleepCore

/// Apple Health, for brands that link it (`SleepHealth`). A brand without it
/// has no `HealthAccess` at all, so its Health settings aren't shown and its
/// nights have no stages. It is also the brand's stage source.
public protocol HealthAccess: SleepStageSource {
  /// Asks to read and write sleep. `true` when writing is allowed.
  func requestAuthorization() async -> Bool
  /// Writes the night as time asleep, with its snoring as metadata. A failure
  /// is logged, never thrown: the night is already saved here.
  func save(_ night: Night, summary: NightSummary) async
}
