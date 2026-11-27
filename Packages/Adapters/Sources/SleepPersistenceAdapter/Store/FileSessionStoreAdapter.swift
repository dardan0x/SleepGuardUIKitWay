import Foundation
import SleepDomain
import SleepFiles

/// `SessionFileStorePort` over the shared `ClipFolder` (the clips folder; plain
/// names only).
struct FileSessionStoreAdapter: SessionFileStorePort {
  private let folder: ClipFolder

  init(directory: URL) {
    folder = ClipFolder(directory: directory)
  }

  func removeFiles(named names: [String]) async {
    folder.removeFiles(named: names)
  }

  func url(forFileNamed name: String) -> URL? {
    folder.url(forFileNamed: name)
  }

  func size(ofFileNamed name: String) async -> Int64 {
    folder.size(ofFileNamed: name)
  }

  func allFileNames() async -> [String] {
    folder.allFileNames()
  }
}
