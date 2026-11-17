import Foundation
import SleepDomain

/// `SessionFileStore` over one directory (the clips folder in the app group).
struct FileSessionStore: SessionFileStore {
  let directory: URL

  func removeFiles(named names: [String]) async {
    for name in names where Self.isPlain(name) {
      // A missing file already meets the goal.
      try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
    }
  }

  func url(forFileNamed name: String) -> URL? {
    guard Self.isPlain(name) else { return nil }
    let url = directory.appendingPathComponent(name)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  func size(ofFileNamed name: String) async -> Int64 {
    guard Self.isPlain(name),
          let size = try? FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)[.size]
          as? Int64 else { return 0 }
    return size
  }

  func allFileNames() async -> [String] {
    (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
  }

  /// Only plain file names: a name can't reach outside the directory.
  private static func isPlain(_ name: String) -> Bool {
    !name.isEmpty && !name.contains("/") && name != ".." && name != "."
  }
}
