import Foundation
import os
import SleepCore
import SleepDomain
import SleepFiles

/// `RawLogWriter` into the clips folder over the shared `RawLogFile`
/// (SleepGuardShared), the same file SleepGuard writes: `RawLog` format 3,
/// samples in time order, appended as they come so a night cut short keeps
/// what was written, an empty log removed. This adapter adds the port's shape
/// and the logging.
actor RawLogFileWriter: RawLogWriter {
  private let directory: URL
  private var file: RawLogFile?
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "storage")

  init(directory: URL) {
    self.directory = directory
  }

  func begin(night id: UUID, metadata: RawLogMetadata) async {
    do {
      file = try RawLogFile(night: id, metadata: metadata, directory: directory)
    } catch {
      Self.log.error("Raw log not started: \(error.localizedDescription, privacy: .public)")
      file = nil
    }
  }

  func append(_ samples: [SnoreSample]) async {
    do {
      try await file?.append(samples)
    } catch {
      Self.log.error("Raw log write failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  func finish() async {
    await file?.finish()
    file = nil
  }
}
