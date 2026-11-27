import Foundation
import SleepCore
import SleepDomain
import SleepFiles

/// `LifestyleLogStorePort` over the shared `LifestyleLogFile` (one JSON file;
/// a new answer for a night replaces the old one).
struct FileLifestyleLogStoreAdapter: LifestyleLogStorePort {
  private let file: LifestyleLogFile

  init(url: URL) {
    file = LifestyleLogFile(url: url)
  }

  func logs() async -> [LifestyleLog] {
    await file.logs()
  }

  func save(_ log: LifestyleLog) async throws {
    try await file.save(log)
  }
}
