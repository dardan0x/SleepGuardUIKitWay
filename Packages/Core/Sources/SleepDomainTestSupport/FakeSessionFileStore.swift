import SleepDomain

/// Records which files were removed.
public actor FakeSessionFileStore: SessionFileStore {
  public private(set) var removed: [String] = []

  public init() {}

  public func removeFiles(named names: [String]) async {
    removed += names
  }
}
