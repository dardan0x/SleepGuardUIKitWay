import Foundation
import SleepDomain

/// Apple Health. Linked only by brands that use HealthKit (the Tuist brand
/// list's `usesHealthKit`); the brand hands the shell its `HealthAccessPort`,
/// which also reads the night's sleep stages.
public enum SleepHealthAdapter {
  public static func makeHealthAccess() -> any HealthAccessPort {
    HealthKitAccessAdapter()
  }
}
