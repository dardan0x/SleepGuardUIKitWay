import SleepDomain

import Foundation

/// Records which files were removed; serves the URLs it was given.
public actor FakeSessionFileStore: SessionFileStore {
  public private(set) var removed: [String] = []
  private let urls: [String: URL]

  public init(urls: [String: URL] = [:]) {
    self.urls = urls
  }

  public nonisolated func url(forFileNamed name: String) -> URL? {
    urls[name]
  }

  public func removeFiles(named names: [String]) async {
    removed += names
  }
}
