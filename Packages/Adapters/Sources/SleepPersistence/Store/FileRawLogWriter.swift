import Foundation
import os
import SleepCore
import SleepDomain

/// `RawLogWriter` into the clips folder, in SleepCore's `RawLog` format 3
/// (JSON Lines: the metadata, then one sample per line). Appends as it goes,
/// so a night cut short by a crash keeps what was written.
actor FileRawLogWriter: RawLogWriter {
  private let directory: URL
  private var handle: FileHandle?
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "storage")

  init(directory: URL) {
    self.directory = directory
  }

  func begin(night id: UUID, metadata: RawLogMetadata) async {
    let url = directory.appendingPathComponent(RawRecording.logFileName(for: id))
    do {
      try RawLog.line(metadata).write(to: url)
      handle = try FileHandle(forWritingTo: url)
      try handle?.seekToEnd()
    } catch {
      Self.log.error("Raw log not started: \(error.localizedDescription, privacy: .public)")
      handle = nil
    }
  }

  func append(_ samples: [SnoreSample]) async {
    guard let handle, !samples.isEmpty else { return }
    do {
      var data = Data()
      for sample in samples {
        try data.append(RawLog.line(sample))
      }
      try handle.write(contentsOf: data)
    } catch {
      Self.log.error("Raw log write failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  func finish() async {
    try? handle?.close()
    handle = nil
  }
}
