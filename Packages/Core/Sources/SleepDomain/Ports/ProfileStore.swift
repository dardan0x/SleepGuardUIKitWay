import Foundation
import SleepCore

/// The person's profile, on this device only. Implemented by
/// `SleepPersistence` as one file. An app that never saved one gets the
/// empty profile.
public protocol ProfileStore: Sendable {
  func load() async -> SleepProfile
  func save(_ profile: SleepProfile) async throws
  /// Removes it (delete all data).
  func clear() async
}
