import Foundation
import OSLog

/// Where this brand keeps its nights database and clips.
///
/// The brand's app group container when the app is entitled to it (its id
/// comes from Info.plist, set by the Tuist brand list), so a future widget can
/// read it; otherwise Application Support. Unsigned simulator builds may not
/// get the app group.
nonisolated struct StorageLocation {
  let root: URL

  var storeURL: URL {
    root.appendingPathComponent("Nights.store")
  }

  var clipsDirectory: URL {
    root.appendingPathComponent("Clips", isDirectory: true)
  }

  /// The person's profile (F8-T1).
  var profileURL: URL {
    root.appendingPathComponent("Profile.json")
  }

  /// Sounds recorded for the Snore Interrupter (F8-T4).
  var melodiesDirectory: URL {
    root.appendingPathComponent("Melodies", isDirectory: true)
  }

  /// The night in progress, while recording (F7-T7).
  var checkpointURL: URL {
    root.appendingPathComponent("Recording.json")
  }

  /// Picks the root and creates the folders.
  static func resolve(
    appGroup: String? = Bundle.main.object(forInfoDictionaryKey: "SGAppGroup") as? String,
    fileManager: FileManager = .default) -> StorageLocation
  {
    let base: URL
    if let appGroup, let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
      base = container
    } else {
      Log.storage.notice("App group unavailable; storing in Application Support")
      base = URL.applicationSupportDirectory
    }
    let location = StorageLocation(root: base.appendingPathComponent("SleepGuardUIKitWay", isDirectory: true))
    do {
      try fileManager.createDirectory(at: location.clipsDirectory, withIntermediateDirectories: true)
    } catch {
      Log.storage.error("Couldn't create the storage folders: \(error.localizedDescription, privacy: .public)")
    }
    return location
  }
}

nonisolated enum Log {
  static let storage = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "storage")
  static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "app")
}
