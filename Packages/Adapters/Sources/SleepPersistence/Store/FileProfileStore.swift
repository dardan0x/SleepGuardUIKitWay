import Foundation
import SleepCore
import SleepDomain
import SleepFiles

/// `ProfileStore` over the shared `ProfileFile` (one atomic JSON file).
struct FileProfileStore: ProfileStore {
  private let file: ProfileFile

  init(url: URL) {
    file = ProfileFile(url: url)
  }

  func load() async -> SleepProfile {
    await file.load()
  }

  func save(_ profile: SleepProfile) async throws {
    try await file.save(profile)
  }

  func clear() async {
    await file.clear()
  }
}
