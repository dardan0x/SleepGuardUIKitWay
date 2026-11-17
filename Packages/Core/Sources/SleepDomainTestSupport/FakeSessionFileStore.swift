import Foundation
import SleepDomain

/// Files as names and sizes in memory. Records which were removed; serves the
/// URLs it was given.
public actor FakeSessionFileStore: SessionFileStore {
  public private(set) var removed: [String] = []
  public private(set) var files: [String: Int64]
  private let urls: [String: URL]

  public init(urls: [String: URL] = [:], files: [String: Int64] = [:]) {
    self.urls = urls
    self.files = files
  }

  public nonisolated func url(forFileNamed name: String) -> URL? {
    urls[name]
  }

  public func removeFiles(named names: [String]) async {
    removed += names
    for name in names {
      files[name] = nil
    }
  }

  public func size(ofFileNamed name: String) async -> Int64 {
    files[name] ?? 0
  }

  public func allFileNames() async -> [String] {
    files.keys.sorted()
  }

  /// A file appears (the capture wrote it).
  public func add(_ name: String, bytes: Int64) {
    files[name] = bytes
  }
}
