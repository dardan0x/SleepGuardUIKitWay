import Foundation
import HealthKit
import os
import SleepCore
import SleepDomain

/// Apple Health. Linked only by brands that use HealthKit (the Tuist brand
/// list's `usesHealthKit`); the brand hands the shell its `HealthAccess`.
/// Sleep stages come in F8-T3.
public enum SleepHealth {
  public static func makeHealthAccess() -> any HealthAccess {
    HealthKitAccess()
  }
}

/// `HealthAccess` over HealthKit, as SleepGuard's `HealthKitSync`: read and
/// write sleep; a saved night is one "asleep" sample with its snoring as
/// metadata (SleepGuard's keys).
struct HealthKitAccess: HealthAccess {
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "health")
  private let store = HKHealthStore()

  private var sleepType: HKCategoryType? {
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
  }

  func requestAuthorization() async -> Bool {
    guard HKHealthStore.isHealthDataAvailable(), let sleepType else { return false }
    do {
      try await store.requestAuthorization(toShare: [sleepType], read: [sleepType])
      return store.authorizationStatus(for: sleepType) == .sharingAuthorized
    } catch {
      Self.log.error("Health authorization failed: \(error.localizedDescription, privacy: .public)")
      return false
    }
  }

  func save(_ night: Night, summary: NightSummary) async {
    guard HKHealthStore.isHealthDataAvailable(), let sleepType,
          store.authorizationStatus(for: sleepType) == .sharingAuthorized else { return }
    let sample = HKCategorySample(
      type: sleepType,
      value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
      start: night.start,
      end: night.end,
      metadata: [
        HKMetadataKeyWasUserEntered: true,
        "snoreEventsCount": summary.eventCount,
        "snoringPercentage": summary.snoringShare * 100,
        "averageDB": night.averageDB,
        "peakDB": night.peakDB,
      ])
    do {
      try await store.save(sample)
    } catch {
      Self.log.error("Writing the night to Health failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
