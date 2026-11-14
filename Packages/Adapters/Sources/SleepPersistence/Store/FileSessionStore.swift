import Foundation
import SleepDomain

/// `SessionFileStore` over one directory (the clips folder in the app group).
struct FileSessionStore: SessionFileStore {
  let directory: URL

  func removeFiles(named names: [String]) async {
    for name in names {
      // Only plain file names: a name can't reach outside the directory.
      guard !name.isEmpty, !name.contains("/"), name != "..", name != "." else { continue }
      // A missing file already meets the goal.
      try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
    }
  }
}
