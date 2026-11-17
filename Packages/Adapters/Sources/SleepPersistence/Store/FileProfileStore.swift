import Foundation
import os
import SleepCore
import SleepDomain

/// `ProfileStore` as one JSON file, written atomically like the checkpoint.
actor FileProfileStore: ProfileStore {
  private let url: URL
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "storage")

  init(url: URL) {
    self.url = url
  }

  func load() async -> SleepProfile {
    guard FileManager.default.fileExists(atPath: url.path) else { return SleepProfile() }
    do {
      return try JSONDecoder().decode(SleepProfile.self, from: Data(contentsOf: url))
    } catch {
      Self.log.error("Profile unreadable, starting empty: \(error.localizedDescription, privacy: .public)")
      return SleepProfile()
    }
  }

  func save(_ profile: SleepProfile) async throws {
    try JSONEncoder().encode(profile).write(to: url, options: .atomic)
  }

  func clear() async {
    try? FileManager.default.removeItem(at: url)
  }
}
