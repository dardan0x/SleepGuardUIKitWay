import Foundation
import SleepCore

/// The answers to the briefing's survey, one per night. Implemented by
/// `SleepPersistence`.
public protocol LifestyleLogStore: Sendable {
  func logs() async -> [LifestyleLog]
  func save(_ log: LifestyleLog) async throws
}
