import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import SleepFiles
import Testing
@testable import AppShell

struct StorageLocationTests {
  @Test func withoutAnAppGroupItUsesApplicationSupport() {
    let location = StorageLocation.resolve(appGroup: nil, folder: "SleepGuardUIKitWay")
    #expect(location.root == URL.applicationSupportDirectory.appendingPathComponent("SleepGuardUIKitWay", isDirectory: true))
    #expect(location.storeURL.lastPathComponent == "Nights.store")
    #expect(FileManager.default.fileExists(atPath: location.clipsDirectory.path))
  }
}

/// A nights file that can't be opened (F13-T5): an in-memory store for this
/// launch, marked unavailable, and the file left exactly as it was.
struct StoreOpeningTests {
  @Test func aCorruptFileIsKeptAndTheStoreIsMarkedUnavailable() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let location = StorageLocation(root: root)
    let garbage = Data("not a database".utf8)
    try garbage.write(to: location.storeURL)
    let container = Container()
    container.storageLocation.register { location }

    let opening = container.storeOpening()

    #expect(!opening.isAvailable)
    #expect(try Data(contentsOf: location.storeURL) == garbage)
  }

  @Test func aGoodFileOpens() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let container = Container()
    container.storageLocation.register { StorageLocation(root: root) }
    #expect(container.storeOpening().isAvailable)
  }
}
