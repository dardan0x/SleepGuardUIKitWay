import Foundation
import SleepCore

/// The answers to the briefing's survey, one per night. Implemented by
/// `SleepPersistenceAdapter`.
public protocol LifestyleLogStorePort: Sendable {
  func logs() async -> [LifestyleLog]
  func save(_ log: LifestyleLog) async throws
}
