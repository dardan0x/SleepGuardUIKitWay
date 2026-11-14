import FactoryKit
import SleepDomain
import SleepGuardDesignKit
import SleepPersistence

/// The shell's registrations. Everything derives from `brand`, the one value
/// supplied from outside (`AppShell.bootstrap(brand:)`). Only `AppShell`
/// imports Factory; packages below it take plain initializer arguments.
extension Container {
  var brand: Factory<any BrandComposition> {
    self { preconditionFailure("AppShell.bootstrap(brand:) registers the brand before anything resolves") }
      .singleton
  }

  var theme: Factory<Theme> {
    self { self.brand().configuration.theme }
  }

  var storageLocation: Factory<StorageLocation> {
    self { StorageLocation.resolve() }.singleton
  }

  /// The nights database. If it can't be opened, this launch runs on an
  /// in-memory store and logs a fault: the file is left alone, never deleted,
  /// so nothing is lost and the next launch tries again.
  var sessionRepository: Factory<any SessionRepository> {
    self {
      let url = self.storageLocation().storeURL
      do {
        return try SleepPersistence.makeSessionRepository(storeURL: url)
      } catch {
        Log.storage.fault("Couldn't open the nights store: \(error.localizedDescription, privacy: .public)")
        // In memory can only fail if SwiftData itself can't start.
        return try! SleepPersistence.makeSessionRepository(storeURL: nil)
      }
    }
    .singleton
  }

  var sessionFileStore: Factory<any SessionFileStore> {
    self { SleepPersistence.makeSessionFileStore(directory: self.storageLocation().clipsDirectory) }.singleton
  }
}
