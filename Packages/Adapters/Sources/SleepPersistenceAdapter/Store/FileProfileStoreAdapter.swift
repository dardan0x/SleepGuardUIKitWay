import Foundation
import SleepCore
import SleepDomain
import SleepFiles

/// `ProfileStorePort` over the shared `ProfileFile` (one atomic JSON file).
struct FileProfileStoreAdapter: ProfileStorePort {
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
