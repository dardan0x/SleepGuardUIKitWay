import Foundation
import os
import SleepCore
import SleepDomain

/// `LifestyleLogStore` as one JSON file, written atomically like the profile.
actor FileLifestyleLogStore: LifestyleLogStore {
  private let url: URL
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "storage")

  init(url: URL) {
    self.url = url
  }

  func logs() async -> [LifestyleLog] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    do {
      return try JSONDecoder().decode([LifestyleLog].self, from: Data(contentsOf: url))
    } catch {
      Self.log.error("Survey answers unreadable, starting empty: \(error.localizedDescription, privacy: .public)")
      return []
    }
  }

  func save(_ log: LifestyleLog) async throws {
    let all = await logs() + [log]
    try JSONEncoder().encode(all).write(to: url, options: .atomic)
  }
}
