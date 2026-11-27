import Foundation
import SleepCore
import SleepDomain
import SleepHealthKit
import SleepLogging

/// Apple Health. Linked only by brands that use HealthKit (the Tuist brand
/// list's `usesHealthKit`); the brand hands the shell its `HealthAccess`,
/// which also reads the night's sleep stages.
public enum SleepHealth {
  public static func makeHealthAccess() -> any HealthAccess {
    HealthKitAccess()
  }
}

/// `HealthAccess` over the shared `HealthKitSleep` (SleepGuardShared), which
/// decides what a night looks like in Apple Health, the same as SleepGuard:
/// one "asleep" sample with the snoring as metadata; stages read from the
/// staged samples (Apple Watch) inside the night. This adapter adds the
/// port's shape and the logging.
struct HealthKitAccess: HealthAccess {
  private let health = HealthKitSleep()

  func requestAuthorization() async -> Bool {
    do {
      return try await health.requestAuthorization()
    } catch {
      Log.health.error("Health authorization failed: \(error.localizedDescription, privacy: .public)")
      return false
    }
  }

  func stages(from start: Date, to end: Date) async throws -> [SleepStageSegment] {
    try await health.stages(from: start, to: end)
  }

  func save(_ night: Night, summary: NightSummary) async {
    do {
      try await health.save(night, summary: summary)
    } catch {
      Log.health.error("Writing the night to Health failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
